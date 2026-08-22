<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Calificacion;
use App\Models\User;
use App\Services\MediaSanitizer;
use App\Services\PublicMediaService;
use App\Services\CombinedSkillRatingService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Illuminate\Validation\Rule;

class OnboardingController extends Controller
{
    public function __construct(
        private readonly MediaSanitizer $mediaSanitizer,
        private readonly PublicMediaService $media,
    ) {
    }

    public function store(Request $request)
    {
        $user = $request->user() ?? abort(401);
        $data = $request->validate([
            'nick' => ['sometimes', 'nullable', 'string', 'min:3', 'max:20', 'regex:/^[A-Za-z0-9_-]+$/'],
            'sexo' => ['sometimes', 'nullable', Rule::in(['M', 'F'])],
            'altura_cm' => ['sometimes', 'nullable', 'integer', 'min:90', 'max:260'],
            'fec_nac' => ['sometimes', 'nullable', 'date', 'before:today'],
            'theme_mode' => ['sometimes', 'nullable', Rule::in(['light', 'dark'])],
            'fisico' => ['sometimes', 'nullable', 'numeric', 'min:0', 'max:5', 'decimal:0,1'],
            'arquero' => ['sometimes', 'nullable', 'numeric', 'min:0', 'max:5', 'decimal:0,1'],
            'delantero' => ['sometimes', 'nullable', 'numeric', 'min:0', 'max:5', 'decimal:0,1'],
            'mediocampo' => ['sometimes', 'nullable', 'numeric', 'min:0', 'max:5', 'decimal:0,1'],
            'defensa' => ['sometimes', 'nullable', 'numeric', 'min:0', 'max:5', 'decimal:0,1'],
        ]);

        if ($request->hasFile('avatar')) {
            $request->validate(['avatar' => ['image', 'mimes:jpg,jpeg,png,webp', 'max:2048']]);
        }

        return DB::transaction(function () use ($request, $user, $data) {
            if (array_key_exists('nick', $data) && $data['nick'] !== null) {
                $normalizedNick = $this->normalizeNick($data['nick']);
                if (User::query()->whereRaw('LOWER(nick) = ?', [mb_strtolower($normalizedNick)])
                    ->where('id', '!=', $user->id)->exists()) {
                    return response()->json(['message' => 'El nick ya está en uso.', 'errors' => ['nick' => ['El nick ya está en uso.']]], 422);
                }
                $user->nick = $normalizedNick;
            }

            foreach (['sexo', 'altura_cm', 'fec_nac', 'theme_mode'] as $field) {
                if (array_key_exists($field, $data) && Schema::hasColumn('users', $field)) {
                    $user->{$field} = $data[$field];
                }
            }

            if ($request->hasFile('avatar')) {
                $previous = $user->avatar_url;
                $user->avatar_url = $this->mediaSanitizer->reencodeImage($request->file('avatar'), 'avatars', 'avatar');
                $this->media->deleteManaged($previous, ['avatars']);
            }

            $skills = ['fisico', 'arquero', 'delantero', 'mediocampo', 'defensa'];
            $hasAllSkills = collect($skills)->every(fn (string $skill) => array_key_exists($skill, $data) && $data[$skill] !== null);
            if ($hasAllSkills) {
                if ((bool) ($user->initial_self_rating_locked ?? false)) {
                    return response()->json(['message' => 'La autocalificación inicial ya está bloqueada.'], 422);
                }
                $rating = Calificacion::firstOrNew([
                    'user_calificador_id' => $user->id,
                    'user_calificado_id' => $user->id,
                    'club_id' => null,
                ]);
                $rating->fill(array_intersect_key($data, array_flip($skills)));
                $rating->save();
                if (Schema::hasColumn('users', 'initial_self_rating_locked')) {
                    $user->initial_self_rating_locked = true;
                }
            }

            $step = $this->nextStep($user, $hasAllSkills);
            if (Schema::hasColumn('users', 'onboarding_step')) {
                $user->onboarding_step = $step;
            }
            if ($step > 6 && Schema::hasColumn('users', 'onboarding_completed_at')) {
                $user->onboarding_completed_at = $user->onboarding_completed_at ?? now();
            }
            $user->save();

            $fresh = $user->fresh();
            $summary = app(CombinedSkillRatingService::class)->summaryForUser((int) $fresh->id);
            $freshPayload = array_merge($fresh->toArray(), [
                'onboarding_completed' => $step > 6,
                'onboarding_step' => $step,
                'sports_profile' => [
                    'star_average' => $summary['stars'],
                    'player_average' => $summary['player_average'],
                    'goalkeeper_average' => $summary['goalkeeper_average'],
                    'primary_position' => $summary['primary_position'],
                    'self_rating_locked' => (bool) ($fresh->initial_self_rating_locked ?? false),
                    'skills' => collect(['fisico', 'arquero', 'delantero', 'mediocampo', 'defensa'])
                        ->mapWithKeys(fn (string $skill) => [$skill => $summary[$skill]])->all(),
                ],
            ]);

            return response()->json([
                'message' => $step > 6 ? 'Onboarding completo.' : 'Paso guardado.',
                'onboarding_completed' => $step > 6,
                'onboarding_step' => $step,
                'needs_onboarding' => $step <= 6,
                'user' => $freshPayload,
            ]);
        });
    }

    public function nickAvailable(Request $request)
    {
        $user = $request->user() ?? abort(401);
        $nick = $this->normalizeNick((string) $request->query('nick', ''));
        $valid = (bool) preg_match('/^[A-Za-z0-9_-]{3,20}$/', $nick);
        return response()->json([
            'valid' => $valid,
            'available' => $valid && !User::whereRaw('LOWER(nick) = ?', [mb_strtolower($nick)])
                ->where('id', '!=', $user->id)->exists(),
        ]);
    }

    public static function needsOnboarding(User $user): bool
    {
        return empty($user->nick) || empty($user->sexo) || empty($user->altura_cm) || empty($user->fec_nac)
            || !(bool) ($user->initial_self_rating_locked ?? false)
            || empty($user->theme_mode);
    }

    private function nextStep(User $user, bool $skillsSaved): int
    {
        if (empty($user->nick)) return 2;
        if (empty($user->sexo) || empty($user->altura_cm) || empty($user->fec_nac)) return 4;
        if (!$skillsSaved && !(bool) ($user->initial_self_rating_locked ?? false)) return 5;
        if (empty($user->theme_mode)) return 6;
        return 7;
    }

    private function normalizeNick(string $nick): string
    {
        return mb_strtolower(ltrim(trim($nick), '@'));
    }
}
