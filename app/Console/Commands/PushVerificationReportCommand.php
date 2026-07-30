<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class PushVerificationReportCommand extends Command
{
    protected $signature = 'push:verification-report {--minutes=240 : Ventana de tiempo para metricas} {--user_id= : Filtrar por user_id}';

    protected $description = 'Muestra evidencia tecnica del pipeline de push (tokens, notificaciones, dispatch y colas).';

    public function handle(): int
    {
        $minutes = max(5, (int) $this->option('minutes'));
        $userId = $this->option('user_id');
        $userId = $userId !== null && $userId !== '' ? (int) $userId : null;
        $since = now()->subMinutes($minutes);

        $pushDriver = (string) config('push.driver', 'log');
        $queueConnection = (string) config('queue.default', 'sync');
        $fcmV1Ready = $pushDriver !== 'fcm'
            || (
                trim((string) config('push.fcm_project_id', '')) !== ''
                && trim((string) config('push.fcm_service_account_path', '')) !== ''
            );

        $this->info('=== Push Verification Report ===');
        $this->line("window_minutes: {$minutes}");
        $this->line('since: ' . $since->toDateTimeString());
        $this->line("queue_connection: {$queueConnection}");
        $this->line("push_driver: {$pushDriver}");
        $this->line('fcm_v1_ready: ' . ($fcmV1Ready ? 'true' : 'false'));
        if ($userId !== null) {
            $this->line("user_id_filter: {$userId}");
        }

        if (!Schema::hasTable('user_devices')) {
            $this->warn('Tabla user_devices no existe.');
            return self::SUCCESS;
        }
        if (!Schema::hasTable('push_notifications')) {
            $this->warn('Tabla push_notifications no existe.');
            return self::SUCCESS;
        }
        if (!Schema::hasTable('push_dispatch_logs')) {
            $this->warn('Tabla push_dispatch_logs no existe.');
            return self::SUCCESS;
        }

        $this->line('');
        $this->info('1) Tokens registrados (user_devices)');
        $devicesQuery = DB::table('user_devices');
        if ($userId !== null) {
            $devicesQuery->where('user_id', $userId);
        }

        $totalDevices = (clone $devicesQuery)->count();
        $activeDevices = (clone $devicesQuery)->where('is_active', 1)->count();
        $this->line("total_devices: {$totalDevices}");
        $this->line("active_devices: {$activeDevices}");

        $byPlatform = (clone $devicesQuery)
            ->selectRaw('platform, COUNT(*) as total')
            ->groupBy('platform')
            ->orderBy('platform')
            ->get();

        foreach ($byPlatform as $row) {
            $platform = (string) ($row->platform ?: 'unknown');
            $count = (int) ($row->total ?? 0);
            $this->line(" - {$platform}: {$count}");
        }

        $this->line('');
        $this->info('2) Notificaciones creadas (push_notifications)');
        $notifQuery = DB::table('push_notifications')->where('created_at', '>=', $since);
        if ($userId !== null) {
            $notifQuery->where('user_id', $userId);
        }

        $notifTotal = (clone $notifQuery)->count();
        $notifUnread = (clone $notifQuery)->where('is_read', 0)->count();
        $this->line("notifications_created_in_window: {$notifTotal}");
        $this->line("notifications_unread_in_window: {$notifUnread}");

        $this->line('');
        $this->info('3) Dispatch (push_dispatch_logs)');
        $dispatchQuery = DB::table('push_dispatch_logs as l')
            ->join('push_notifications as n', 'n.id', '=', 'l.push_notification_id')
            ->where('l.created_at', '>=', $since);

        if ($userId !== null) {
            $dispatchQuery->where('n.user_id', $userId);
        }

        $byStatusProvider = (clone $dispatchQuery)
            ->selectRaw('l.status, l.provider, COUNT(*) as total')
            ->groupBy('l.status', 'l.provider')
            ->orderBy('l.status')
            ->orderBy('l.provider')
            ->get();

        foreach ($byStatusProvider as $row) {
            $status = (string) ($row->status ?: 'unknown');
            $provider = (string) ($row->provider ?: 'unknown');
            $count = (int) ($row->total ?? 0);
            $this->line(" - status={$status}, provider={$provider}, total={$count}");
        }

        $recentFailures = (clone $dispatchQuery)
            ->where('l.status', 'failed')
            ->orderByDesc('l.id')
            ->limit(10)
            ->get([
                'l.id',
                'n.user_id',
                'l.provider',
                'l.error_message',
                'l.created_at',
            ]);

        if ($recentFailures->isNotEmpty()) {
            $this->line('');
            $this->warn('4) Ultimos fallos');
            foreach ($recentFailures as $row) {
                $id = (int) $row->id;
                $rowUserId = (int) $row->user_id;
                $provider = (string) $row->provider;
                $error = trim((string) $row->error_message);
                $createdAt = (string) $row->created_at;
                $this->line("#{$id} user={$rowUserId} provider={$provider} at={$createdAt}");
                $this->line("   error: {$error}");
            }
        }

        if (Schema::hasTable('jobs')) {
            $this->line('');
            $this->info('5) Cola jobs');
            $jobRows = DB::table('jobs')
                ->selectRaw('queue, COUNT(*) as total')
                ->groupBy('queue')
                ->orderBy('queue')
                ->get();
            foreach ($jobRows as $row) {
                $queue = (string) ($row->queue ?: 'default');
                $count = (int) ($row->total ?? 0);
                $this->line(" - queue={$queue}, total={$count}");
            }
        }

        if (Schema::hasTable('failed_jobs')) {
            $failedCount = (int) DB::table('failed_jobs')->count();
            $this->line("failed_jobs_total: {$failedCount}");
        }

        $this->line('');
        $this->info('Reporte completado.');

        return self::SUCCESS;
    }
}
