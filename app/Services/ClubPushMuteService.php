<?php

namespace App\Services;

use App\Models\UserGroupNotificationPref;
use Illuminate\Support\Collection;

class ClubPushMuteService
{
    public function isMuted(int $userId, int $clubId): bool
    {
        $pref = UserGroupNotificationPref::query()
            ->where('user_id', $userId)
            ->where('club_id', $clubId)
            ->first();

        return $pref ? $pref->isMuted() : false;
    }

    /**
     * @param  Collection<int, int>  $userIds
     * @return Collection<int, int>
     */
    public function filterNotMutedUserIds(Collection $userIds, int $clubId): Collection
    {
        if ($userIds->isEmpty()) {
            return collect();
        }

        $prefs = UserGroupNotificationPref::query()
            ->where('club_id', $clubId)
            ->whereIn('user_id', $userIds->all())
            ->get()
            ->keyBy('user_id');

        return $userIds->filter(function (int $userId) use ($prefs): bool {
            $pref = $prefs->get($userId);
            return $pref ? !$pref->isMuted() : true;
        })->values();
    }
}
