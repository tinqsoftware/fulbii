<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Club;
use App\Models\ClubUser;
use App\Models\ClubNotificationCategory;
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

    public function categories(Request $request, Club $club)
    {
        $user = $request->user() ?? abort(401);
        $this->authorizeClubMembership($user->id, $club->id, (bool) $user->is_superadmin);
        $saved = ClubNotificationCategory::query()
            ->where('user_id', $user->id)->where('club_id', $club->id)
            ->pluck('is_enabled', 'category');

        return response()->json([
            'club_id' => (int) $club->id,
            'items' => collect(ClubNotificationCategory::CATEGORIES)->map(fn (string $category) => [
                'category' => $category,
                'is_enabled' => $saved->has($category) ? (bool) $saved[$category] : true,
            ])->values(),
        ]);
    }

    public function updateCategory(Request $request, Club $club, string $category)
    {
        $user = $request->user() ?? abort(401);
        $this->authorizeClubMembership($user->id, $club->id, (bool) $user->is_superadmin);
        abort_unless(in_array($category, ClubNotificationCategory::CATEGORIES, true), 404);
        $data = $request->validate(['is_enabled' => ['required', 'boolean']]);

        $item = ClubNotificationCategory::updateOrCreate(
            ['user_id' => $user->id, 'club_id' => $club->id, 'category' => $category],
            ['is_enabled' => (bool) $data['is_enabled']]
        );

        return response()->json(['category' => $item->category, 'is_enabled' => $item->is_enabled]);
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
