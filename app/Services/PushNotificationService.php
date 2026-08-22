<?php

namespace App\Services;

use App\Jobs\SendPushNotificationJob;
use App\Models\PushNotification;
use Illuminate\Database\QueryException;
use Illuminate\Support\Facades\Schema;

class PushNotificationService
{
    /**
     * @param array<string,mixed> $payload
     */
    public function createForUser(int $userId, array $payload): PushNotification
    {
        $clubId = $payload['club_id'] ?? null;
        $pichangaId = $payload['group_pichanga_id'] ?? null;
        $data = (array) ($payload['data_json'] ?? []);
        $dedupeKey = isset($payload['dedupe_key']) ? trim((string) $payload['dedupe_key']) : null;
        if (!isset($data['club_id']) && $clubId) {
            $data['club_id'] = (string) $clubId;
        }
        if (!isset($data['pichanga_id']) && $pichangaId) {
            $data['pichanga_id'] = (string) $pichangaId;
        }
        if (!isset($data['target_type'])) {
            $data['target_type'] = $pichangaId ? 'pichanga' : 'club';
        }
        if (!isset($data['target_id'])) {
            $data['target_id'] = (string) ($pichangaId ?: $clubId ?: '');
        }

        $attributes = [
            'user_id' => $userId,
            'club_id' => $clubId,
            'group_pichanga_id' => $pichangaId,
            'type' => (string) ($payload['type'] ?? 'generic'),
            'dedupe_key' => $dedupeKey ?: null,
            'title' => (string) ($payload['title'] ?? 'Notificación'),
            'body' => (string) ($payload['body'] ?? ''),
            'data_json' => $data ?: null,
            'is_read' => false,
        ];
        // Legacy installations and focused SQLite tests can intentionally omit
        // the optional push tables. Domain actions must still succeed there.
        if (!Schema::hasTable('push_notifications')) {
            return new PushNotification($attributes);
        }

        $hasDedupeColumn = $dedupeKey && Schema::hasColumn('push_notifications', 'dedupe_key');
        if (!$hasDedupeColumn) {
            unset($attributes['dedupe_key']);
        }

        if ($hasDedupeColumn) {
            try {
                $notification = PushNotification::query()->firstOrCreate(
                    ['user_id' => $userId, 'dedupe_key' => $dedupeKey],
                    $attributes
                );
            } catch (QueryException $exception) {
                // A concurrent retry can race between the SELECT and INSERT.
                // The unique key is the final guard; return the row created by
                // the other request instead of failing the domain action.
                $notification = PushNotification::query()
                    ->forDedupeKey($userId, $dedupeKey)
                    ->first();
                if (!$notification) {
                    throw $exception;
                }
            }
        } else {
            $notification = PushNotification::create($attributes);
        }

        if ($notification->wasRecentlyCreated) {
            SendPushNotificationJob::dispatch((int) $notification->id)->onQueue('push');
        }
        return $notification;
    }

    /**
     * @param array<int> $userIds
     * @param array<string,mixed> $payload
     */
    public function createForUsers(array $userIds, array $payload): int
    {
        $uniqueUserIds = array_values(array_unique(array_map('intval', $userIds)));
        $created = 0;

        foreach ($uniqueUserIds as $userId) {
            $this->createForUser($userId, $payload);
            $created++;
        }

        return $created;
    }
}
