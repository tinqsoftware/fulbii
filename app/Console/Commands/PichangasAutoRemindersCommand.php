<?php

namespace App\Console\Commands;

use App\Models\GroupPichanga;
use App\Models\GroupPichangaNotificationBatch;
use App\Models\GroupPichangaParticipant;
use App\Services\ClubPushMuteService;
use App\Services\GroupPichangaAudienceService;
use App\Services\ProductEventService;
use App\Services\PushNotificationService;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class PichangasAutoRemindersCommand extends Command
{
    protected $signature = 'pichangas:auto-reminders {--dry-run : Solo simular, sin enviar notificaciones}';

    protected $description = 'Envía olas automáticas 48h/24h para pichangas con cupos faltantes.';

    private ?bool $supportsAuto48BatchType = null;
    private ?bool $supportsAuto24BatchType = null;

    public function handle(
        GroupPichangaAudienceService $audienceService,
        ClubPushMuteService $muteService,
        PushNotificationService $pushNotificationService,
        ProductEventService $eventService
    ): int {
        if (!$this->supportsAutoReminderColumns()) {
            $this->warn('Columnas de auto reminder no detectadas. Ejecuta el SQL incremental de Growth.');
            return self::SUCCESS;
        }

        $dryRun = (bool) $this->option('dry-run');
        $now = now();
        $h24 = $now->copy()->addHours(24);
        $h48 = $now->copy()->addHours(48);

        $query = GroupPichanga::query()
            ->with('club:id,audience_max_degree,auto_reminder_enabled,auto_reminder_48h_enabled,auto_reminder_24h_enabled')
            ->whereIn('status', ['published', 'confirmed'])
            ->where('starts_at', '>', $now)
            ->where('starts_at', '<=', $h48);

        if (Schema::hasColumn('group_pichangas', 'auto_reminder_enabled')) {
            $query->where('auto_reminder_enabled', 1);
        }

        $candidates = $query->orderBy('starts_at')->get();

        $processed = 0;
        $sentBatches = 0;
        foreach ($candidates as $pichanga) {
            $processed++;
            $wave = $this->resolveWaveType($pichanga, $h24, $h48);
            if (!$wave) {
                continue;
            }

            $degree = $wave === 'auto_48h'
                ? 1
                : $this->resolveMaxConfiguredDegree($pichanga);

            $result = $this->dispatchWave(
                $pichanga,
                $wave,
                $degree,
                $dryRun,
                $audienceService,
                $muteService,
                $pushNotificationService,
                $eventService
            );

            if ($result['executed']) {
                $sentBatches++;
                $this->line("{$wave} pichanga={$pichanga->id} targets={$result['target_count']} sent={$result['sent_count']}");
            }
        }

        $this->info("Procesadas {$processed} pichangas. Olas ejecutadas: {$sentBatches}.");

        return self::SUCCESS;
    }

    private function supportsAutoReminderColumns(): bool
    {
        return Schema::hasColumn('clubs', 'auto_reminder_enabled')
            && Schema::hasColumn('clubs', 'auto_reminder_48h_enabled')
            && Schema::hasColumn('clubs', 'auto_reminder_24h_enabled')
            && Schema::hasColumn('group_pichangas', 'auto_reminder_enabled')
            && Schema::hasColumn('group_pichangas', 'auto_reminder_48h_sent_at')
            && Schema::hasColumn('group_pichangas', 'auto_reminder_24h_sent_at');
    }

    private function resolveWaveType(GroupPichanga $pichanga, \Carbon\CarbonInterface $h24, \Carbon\CarbonInterface $h48): ?string
    {
        $club = $pichanga->club;
        if (!$club || !(bool) ($club->auto_reminder_enabled ?? true)) {
            return null;
        }

        if (!(bool) ($pichanga->auto_reminder_enabled ?? true)) {
            return null;
        }

        $spotsLeft = $this->spotsLeft((int) $pichanga->id, (int) $pichanga->capacity);
        if ($spotsLeft <= 0) {
            return null;
        }

        if ($pichanga->starts_at->lessThanOrEqualTo($h24)) {
            if ((bool) ($club->auto_reminder_24h_enabled ?? true) && !$pichanga->auto_reminder_24h_sent_at) {
                return 'auto_24h';
            }
            return null;
        }

        if ($pichanga->starts_at->lessThanOrEqualTo($h48)) {
            if ((bool) ($club->auto_reminder_48h_enabled ?? true) && !$pichanga->auto_reminder_48h_sent_at) {
                return 'auto_48h';
            }
        }

        return null;
    }

    /**
     * @return array{executed:bool,target_count:int,sent_count:int}
     */
    private function dispatchWave(
        GroupPichanga $pichanga,
        string $waveType,
        int $targetDegree,
        bool $dryRun,
        GroupPichangaAudienceService $audienceService,
        ClubPushMuteService $muteService,
        PushNotificationService $pushNotificationService,
        ProductEventService $eventService
    ): array {
        if ($dryRun) {
            $audience = $audienceService->resolveAudience($pichanga, ['target_degree' => $targetDegree]);
            $targets = collect($audience['target_user_ids'])
                ->map(fn($id) => (int) $id)
                ->unique()
                ->values();

            $confirmedUserIds = GroupPichangaParticipant::query()
                ->where('pichanga_id', $pichanga->id)
                ->where('status', 'confirmed')
                ->pluck('user_id')
                ->map(fn($id) => (int) $id);

            $targets = $targets->diff($confirmedUserIds)->values();
            $notMuted = $muteService->filterNotMutedUserIds($targets, (int) $pichanga->club_id);

            return [
                'executed' => true,
                'target_count' => $targets->count(),
                'sent_count' => $notMuted->count(),
            ];
        }

        return DB::transaction(function () use (
            $pichanga,
            $waveType,
            $targetDegree,
            $audienceService,
            $muteService,
            $pushNotificationService,
            $eventService
        ): array {
            $locked = GroupPichanga::query()
                ->whereKey($pichanga->id)
                ->lockForUpdate()
                ->first();
            if (!$locked) {
                return ['executed' => false, 'target_count' => 0, 'sent_count' => 0];
            }

            $field = $waveType === 'auto_48h' ? 'auto_reminder_48h_sent_at' : 'auto_reminder_24h_sent_at';
            if (!empty($locked->{$field})) {
                return ['executed' => false, 'target_count' => 0, 'sent_count' => 0];
            }

            $spotsLeft = $this->spotsLeft((int) $locked->id, (int) $locked->capacity);
            if ($spotsLeft <= 0) {
                return ['executed' => false, 'target_count' => 0, 'sent_count' => 0];
            }

            $audience = $audienceService->resolveAudience($locked, ['target_degree' => $targetDegree]);
            $targets = collect($audience['target_user_ids'])
                ->map(fn($id) => (int) $id)
                ->unique()
                ->values();

            $confirmedUserIds = GroupPichangaParticipant::query()
                ->where('pichanga_id', $locked->id)
                ->where('status', 'confirmed')
                ->pluck('user_id')
                ->map(fn($id) => (int) $id);

            $targets = $targets->diff($confirmedUserIds)->values();
            $notMuted = $muteService->filterNotMutedUserIds($targets, (int) $locked->club_id);
            $mutedSkipped = max(0, $targets->count() - $notMuted->count());

            $sent = 0;
            if ($notMuted->isNotEmpty()) {
                $sent = $pushNotificationService->createForUsers($notMuted->all(), [
                    'club_id' => $locked->club_id,
                    'group_pichanga_id' => $locked->id,
                    'type' => $waveType === 'auto_48h' ? 'pichanga_auto_48h' : 'pichanga_auto_24h',
                    'title' => 'Recordatorio automático',
                    'body' => (string) ($locked->title ?: 'Aún faltan jugadores para esta pichanga'),
                    'data_json' => ['pichanga_id' => $locked->id, 'club_id' => $locked->club_id, 'wave' => $waveType],
                ]);
            }

            GroupPichangaNotificationBatch::create([
                'pichanga_id' => $locked->id,
                'triggered_by_user_id' => $locked->created_by_user_id,
                'batch_type' => $this->resolveBatchType($waveType),
                'target_degree' => (int) $audience['target_degree'],
                'filters_json' => $audience['filters'],
                'target_count' => $targets->count(),
                'muted_skipped_count' => $mutedSkipped,
                'sent_count' => $sent,
            ]);

            $locked->update([$field => now()]);

            $eventService->track(
                $waveType === 'auto_48h' ? 'pichanga_auto_48h_sent' : 'pichanga_auto_24h_sent',
                (int) $locked->created_by_user_id,
                (int) $locked->club_id,
                (int) $locked->id,
                [
                    'target_count' => $targets->count(),
                    'sent_count' => $sent,
                    'muted_skipped_count' => $mutedSkipped,
                    'target_degree' => (int) $audience['target_degree'],
                ],
                'scheduler'
            );

            return [
                'executed' => true,
                'target_count' => $targets->count(),
                'sent_count' => $sent,
            ];
        });
    }

    private function resolveMaxConfiguredDegree(GroupPichanga $pichanga): int
    {
        $clubMax = (int) ($pichanga->club?->audience_max_degree ?? 1);
        $pichangaConfigured = (int) ($pichanga->notify_degree ?? 1);
        return max(1, min(3, max($clubMax, $pichangaConfigured)));
    }

    private function spotsLeft(int $pichangaId, int $capacity): int
    {
        $confirmed = GroupPichangaParticipant::query()
            ->where('pichanga_id', $pichangaId)
            ->where('status', 'confirmed')
            ->count();

        return max(0, $capacity - $confirmed);
    }

    private function resolveBatchType(string $desired): string
    {
        if ($desired === 'auto_48h') {
            return $this->supportsBatchType('auto_48h') ? 'auto_48h' : 'manual_renotify';
        }
        if ($desired === 'auto_24h') {
            return $this->supportsBatchType('auto_24h') ? 'auto_24h' : 'manual_renotify';
        }

        return 'manual_renotify';
    }

    private function supportsBatchType(string $type): bool
    {
        if ($type === 'auto_48h' && $this->supportsAuto48BatchType !== null) {
            return $this->supportsAuto48BatchType;
        }
        if ($type === 'auto_24h' && $this->supportsAuto24BatchType !== null) {
            return $this->supportsAuto24BatchType;
        }

        $connection = DB::connection();
        if ($connection->getDriverName() !== 'mysql') {
            return true;
        }

        $database = (string) $connection->getDatabaseName();
        $columnType = $connection->table('information_schema.COLUMNS')
            ->where('TABLE_SCHEMA', $database)
            ->where('TABLE_NAME', 'group_pichanga_notification_batches')
            ->where('COLUMN_NAME', 'batch_type')
            ->value('COLUMN_TYPE');
        $supported = is_string($columnType) && str_contains($columnType, "'{$type}'");

        if ($type === 'auto_48h') {
            $this->supportsAuto48BatchType = $supported;
        } else {
            $this->supportsAuto24BatchType = $supported;
        }

        return $supported;
    }
}
