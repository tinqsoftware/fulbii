<?php

namespace App\Services;

use App\Models\ClubChallenge;
use App\Models\ClubUser;
use App\Models\ClubNotificationCategory;
use App\Models\UserChatPresence;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\Schema;

class ChallengeNotificationService
{
    public function __construct(
        private readonly ClubPushMuteService $muteService,
        private readonly PushNotificationService $pushNotificationService
    ) {
    }

    /**
     * @param array<string,mixed> $payload
     * @return array{target_count:int,muted_skipped_count:int,active_chat_skipped_count:int,sent_count:int}
     */
    public function notifyMembers(
        ClubChallenge $challenge,
        int $actorUserId,
        array $payload,
        bool $suppressIfActiveInChat = false
    ): array {
        $members = ClubUser::query()
            ->whereIn('club_id', [(int) $challenge->challenger_club_id, (int) $challenge->challenged_club_id])
            ->where('estado', 1)
            ->get(['club_id', 'user_id']);

        if ($members->isEmpty()) {
            return [
                'target_count' => 0,
                'muted_skipped_count' => 0,
                'active_chat_skipped_count' => 0,
                'sent_count' => 0,
            ];
        }

        $byUser = $members
            ->groupBy('user_id')
            ->map(fn(Collection $rows) => $rows->pluck('club_id')->map(fn($i) => (int) $i)->unique()->values()->all());

        $targetCount = 0;
        $mutedSkipped = 0;
        $activeChatSkipped = 0;
        $sentCount = 0;

        foreach ($byUser as $rawUserId => $clubIds) {
            $userId = (int) $rawUserId;
            if ($userId === $actorUserId) {
                continue;
            }
            $targetCount++;

            $clubForNotification = $this->firstUnmutedClubForUser($userId, $clubIds);
            if ($clubForNotification === null) {
                $mutedSkipped++;
                continue;
            }

            $category = (string) ($payload['category'] ?? ((string) ($payload['type'] ?? '') === 'challenge_chat_message' ? 'chat' : 'challenges'));
            if (Schema::hasTable('club_notification_categories') && ClubNotificationCategory::query()
                ->where('user_id', $userId)
                ->where('club_id', $clubForNotification)
                ->where('category', $category)
                ->where('is_enabled', false)
                ->exists()) {
                $mutedSkipped++;
                continue;
            }

            if ($suppressIfActiveInChat && $this->isUserActiveInChat($userId, (int) $challenge->id)) {
                $activeChatSkipped++;
                continue;
            }

            $dataJson = (array) ($payload['data_json'] ?? []);
            $challenge->loadMissing(['challengerClub:id,nombre,logo_url', 'challengedClub:id,nombre,logo_url']);
            $dataJson = array_merge($dataJson, [
                'challenge_id' => (int) $challenge->id,
                'target_type' => 'challenge',
                'target_id' => (string) $challenge->id,
                'image_kind' => 'challenge',
                'image_url' => (string) ($challenge->challengerClub?->logo_url ?? ''),
                'secondary_image_url' => (string) ($challenge->challengedClub?->logo_url ?? ''),
                'challenger_club_id' => (string) $challenge->challenger_club_id,
                'challenged_club_id' => (string) $challenge->challenged_club_id,
            ]);

            $this->pushNotificationService->createForUser($userId, [
                'club_id' => $clubForNotification,
                'group_pichanga_id' => $payload['group_pichanga_id'] ?? null,
                'type' => (string) ($payload['type'] ?? 'challenge_chat_message'),
                'title' => (string) ($payload['title'] ?? 'Nuevo mensaje del reto'),
                'body' => (string) ($payload['body'] ?? ''),
                'data_json' => $dataJson,
            ]);
            $sentCount++;
        }

        return [
            'target_count' => $targetCount,
            'muted_skipped_count' => $mutedSkipped,
            'active_chat_skipped_count' => $activeChatSkipped,
            'sent_count' => $sentCount,
        ];
    }

    /**
     * @param array<int> $clubIds
     */
    private function firstUnmutedClubForUser(int $userId, array $clubIds): ?int
    {
        foreach ($clubIds as $clubId) {
            if (!$this->muteService->isMuted($userId, (int) $clubId)) {
                return (int) $clubId;
            }
        }

        return null;
    }

    private function isUserActiveInChat(int $userId, int $challengeId): bool
    {
        if (!Schema::hasTable('user_chat_presence')) {
            return false;
        }

        return UserChatPresence::query()
            ->where('user_id', $userId)
            ->where('challenge_id', $challengeId)
            ->where('is_active', true)
            ->where('last_heartbeat_at', '>=', now()->subSeconds(90))
            ->exists();
    }
}
