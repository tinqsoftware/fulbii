<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Club;
use App\Models\ClubUser;
use App\Models\UserGroupNotificationPref;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class ClubNotificationPreferenceController extends Controller
{
    public function show(Request $request, Club $club)
    {
        $user = $request->user() ?? abort(401);
        $this->authorizeClubMembership($user->id, $club->id, (bool) $user->is_superadmin);

        $pref = UserGroupNotificationPref::firstWhere([
            'user_id' => $user->id,
            'club_id' => $club->id,
        ]);

        if (!$pref) {
            return response()->json([
                'club_id' => $club->id,
                'mode' => UserGroupNotificationPref::MODE_ALWAYS_ON,
                'muted_until' => null,
                'is_muted_now' => false,
            ]);
        }

        return response()->json([
            'club_id' => $club->id,
            'mode' => $pref->mode,
            'muted_until' => optional($pref->muted_until)->toISOString(),
            'is_muted_now' => $pref->isMuted(),
            'updated_at' => optional($pref->updated_at)->toISOString(),
        ]);
    }

    public function update(Request $request, Club $club)
    {
        $user = $request->user() ?? abort(401);
        $this->authorizeClubMembership($user->id, $club->id, (bool) $user->is_superadmin);

        $data = $request->validate([
            'mode' => ['required', 'string', Rule::in(UserGroupNotificationPref::validModes())],
        ]);

        $pref = UserGroupNotificationPref::firstOrNew([
            'user_id' => $user->id,
            'club_id' => $club->id,
        ]);

        $pref->mode = $data['mode'];
        $pref->muted_until = UserGroupNotificationPref::mutedUntilForMode($data['mode']);
        $pref->updated_by_user = true;
        $pref->save();

        return response()->json([
            'club_id' => $club->id,
            'mode' => $pref->mode,
            'muted_until' => optional($pref->muted_until)->toISOString(),
            'is_muted_now' => $pref->isMuted(),
            'updated_at' => optional($pref->updated_at)->toISOString(),
        ]);
    }

    private function authorizeClubMembership(int $userId, int $clubId, bool $isSuperAdmin): void
    {
        if ($isSuperAdmin) {
            return;
        }

        $isMember = ClubUser::where('club_id', $clubId)
            ->where('user_id', $userId)
            ->active()
            ->exists();

        abort_unless($isMember, 403, 'No perteneces a este grupo.');
    }
}
