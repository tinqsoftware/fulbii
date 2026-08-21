<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Services\CombinedSkillRatingService;
use App\Services\MediaSanitizer;
use App\Services\PublicMediaService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class MeController extends Controller
{
    public function __construct(
        private readonly PublicMediaService $media,
        private readonly MediaSanitizer $mediaSanitizer,
    ) {
    }

    public function show(Request $request)
    {
        $user = $request->user() ?? abort(401);
        $summary = [
            'votos' => 0,
            'fisico' => null,
            'arquero' => null,
            'delantero' => null,
            'mediocampo' => null,
            'defensa' => null,
            'player_average' => null,
            'goalkeeper_average' => null,
            'stars' => null,
            'primary_role' => null,
            'primary_position' => null,
        ];
        if (Schema::hasTable('calificaciones') || Schema::hasTable('group_pichanga_ratings')) {
            $summary = app(CombinedSkillRatingService::class)->summaryForUser((int) $user->id);
        }

        $pichangasPlayed = 0;
        if (Schema::hasTable('group_pichanga_participants')) {
            $pichangasPlayed = DB::table('group_pichanga_participants')
                ->where('user_id', $user->id)
                ->where('status', 'confirmed')
                ->count();
        }

        return response()->json([
            ...$user->toArray(),
            'sports_profile' => [
                'star_average' => $summary['stars'],
                'player_average' => $summary['player_average'],
                'goalkeeper_average' => $summary['goalkeeper_average'],
                'primary_role' => $summary['primary_role'],
                'primary_position' => $summary['primary_position'],
                'pichangas_played' => $pichangasPlayed,
                'self_rating_locked' => (bool) ($user->initial_self_rating_locked ?? false),
                'skills' => [
                    'fisico' => $summary['fisico'],
                    'arquero' => $summary['arquero'],
                    'defensa' => $summary['defensa'],
                    'mediocampo' => $summary['mediocampo'],
                    'delantero' => $summary['delantero'],
                ],
            ],
            'onboarding_completed' => !\App\Http\Controllers\Api\V1\OnboardingController::needsOnboarding($user),
            'onboarding_step' => (int) ($user->onboarding_step ?? 1),
        ]);
    }

    public function update(Request $request)
    {
        $user = $request->user() ?? abort(401);

        $data = $request->validate([
            'name' => ['sometimes', 'string', 'max:255'],
            'nick' => ['sometimes', 'required', 'regex:/^[A-Za-z0-9_\-]{3,20}$/', 'unique:users,nick,' . $user->id],
            'avatar_url' => ['sometimes', 'nullable', 'string', 'max:500'],
            'fec_nac' => ['sometimes', 'nullable', 'date'],
            'altura_cm' => ['sometimes', 'nullable', 'integer', 'min:90', 'max:260'],
            'sexo' => ['sometimes', 'nullable', 'in:M,F'],
            'theme_mode' => ['sometimes', 'nullable', 'in:light,dark'],
        ]);

        if ($request->hasFile('avatar')) {
            $request->validate([
                'avatar' => ['image', 'mimes:jpg,jpeg,png,webp', 'max:2048', 'dimensions:max_width=4096,max_height=4096']
            ]);
            $previousAvatar = $user->avatar_url;
            $path = $this->mediaSanitizer->reencodeImage($request->file('avatar'), 'avatars', 'avatar');
            $user->avatar_url = $path;
            $this->media->deleteManaged($previousAvatar, ['avatars']);
        }

        foreach ($data as $field => $value) {
            if (Schema::hasColumn('users', $field)) {
                $user->{$field} = $value;
            }
        }

        $user->save();

        return response()->json($user->fresh());
    }
}
