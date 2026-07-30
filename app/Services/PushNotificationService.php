<?php

namespace App\Services;

use App\Jobs\SendPushNotificationJob;
use App\Models\PushNotification;

class PushNotificationService
{
    /**
     * @param array<string,mixed> $payload
     */
    public function createForUser(int $userId, array $payload): PushNotification
    {
        $notification = PushNotification::create([
            'user_id' => $userId,
            'club_id' => $payload['club_id'] ?? null,
            'group_pichanga_id' => $payload['group_pichanga_id'] ?? null,
            'type' => (string) ($payload['type'] ?? 'generic'),
            'title' => (string) ($payload['title'] ?? 'Notificación'),
            'body' => (string) ($payload['body'] ?? ''),
            'data_json' => $payload['data_json'] ?? null,
            'is_read' => false,
        ]);

        SendPushNotificationJob::dispatch((int) $notification->id)->onQueue('push');
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
