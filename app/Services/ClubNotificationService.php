<?php

namespace App\Services;

use App\Models\Club;
use App\Models\ClubAdminActivity;
use App\Models\ClubNotificationCategory;
use App\Models\ClubUser;
use App\Models\User;
use Illuminate\Support\Facades\Schema;

/**
 * Builds a single notification contract for group-related events.
 * The payload is deliberately stored in data_json so old clients continue to
 * render a normal notification while new clients can navigate and render media.
 */
class ClubNotificationService
{
    public function __construct(
        private readonly PushNotificationService $push,
        private readonly ClubPushMuteService $muteService
    ) {
    }

    /** @return array<int> */
    public function adminIds(Club $club): array
    {
        return ClubUser::query()
            ->where('club_id', $club->id)
            ->active()
            ->where('rol', 'admin')
            ->pluck('user_id')
            ->map(fn ($id) => (int) $id)
            ->all();
    }

    /** @return array<int> */
    public function memberIds(Club $club): array
    {
        return ClubUser::query()
            ->where('club_id', $club->id)
            ->active()
            ->pluck('user_id')
            ->map(fn ($id) => (int) $id)
            ->all();
    }

    /** @param array<string,mixed> $payload */
    public function notifyAdmins(Club $club, array $payload, ?int $actorUserId = null): int
    {
        return $this->notifyUsers($club, $this->adminIds($club), $payload, $actorUserId);
    }

    /** @param array<int> $userIds @param array<string,mixed> $payload */
    public function notifyUsers(Club $club, array $userIds, array $payload, ?int $actorUserId = null): int
    {
        $category = (string) ($payload['category'] ?? 'social');
        $sent = 0;

        foreach (array_values(array_unique(array_map('intval', $userIds))) as $userId) {
            if ($userId <= 0 || $userId === $actorUserId || !$this->canNotify($userId, (int) $club->id, $category)) {
                continue;
            }
            $this->push->createForUser($userId, $this->payloadFor($club, $payload, $actorUserId));
            $sent++;
        }

        return $sent;
    }

    /** @param array<string,mixed> $meta */
    public function audit(Club $club, ?int $actorUserId, string $type, ?int $targetUserId = null, array $meta = []): void
    {
        if (!Schema::hasTable('club_admin_activities')) {
            return;
        }
        ClubAdminActivity::create([
            'club_id' => $club->id,
            'actor_user_id' => $actorUserId,
            'target_user_id' => $targetUserId,
            'type' => $type,
            'meta_json' => $meta ?: null,
        ]);
    }

    private function canNotify(int $userId, int $clubId, string $category): bool
    {
        if ($this->muteService->isMuted($userId, $clubId)) {
            return false;
        }

        if (!Schema::hasTable('club_notification_categories')) {
            return true;
        }

        return !ClubNotificationCategory::query()
            ->where('user_id', $userId)
            ->where('club_id', $clubId)
            ->where('category', $category)
            ->where('is_enabled', false)
            ->exists();
    }

    /** @param array<string,mixed> $payload @return array<string,mixed> */
    private function payloadFor(Club $club, array $payload, ?int $actorUserId): array
    {
        $data = (array) ($payload['data_json'] ?? []);
        $targetType = (string) ($payload['target_type'] ?? $data['target_type'] ?? 'club');
        $targetId = (int) ($payload['target_id'] ?? $data['target_id'] ?? $club->id);
        $imageUrl = (string) ($payload['image_url'] ?? $data['image_url'] ?? $club->logo_url ?? '');

        $data = array_merge($data, [
            'target_type' => $targetType,
            'target_id' => (string) $targetId,
            'club_id' => (string) $club->id,
            'actor_user_id' => $actorUserId ? (string) $actorUserId : '',
            'image_url' => $imageUrl,
            'image_kind' => (string) ($payload['image_kind'] ?? $data['image_kind'] ?? 'club'),
        ]);

        return [
            'club_id' => $club->id,
            'group_pichanga_id' => $payload['group_pichanga_id'] ?? null,
            'type' => (string) ($payload['type'] ?? 'club_update'),
            'title' => (string) ($payload['title'] ?? $club->nombre),
            'body' => (string) ($payload['body'] ?? ''),
            'data_json' => $data,
        ];
    }
}
