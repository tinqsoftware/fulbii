<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Club;
use App\Models\ClubChallenge;
use App\Models\ClubJoinRequest;
use App\Models\ClubUser;
use App\Models\GroupPichangaParticipant;
use App\Models\User;
use App\Services\CombinedSkillRatingService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;
use Illuminate\Validation\Rule;

class ClubApiController extends Controller
{
    public function index(Request $request)
    {
        $user = $request->user();

        $scope = (string) $request->query('scope', $user ? 'mine' : 'discover');
        if (!in_array($scope, ['mine', 'discover'], true)) {
            $scope = $user ? 'mine' : 'discover';
        }

        $q = trim((string) $request->query('q', ''));

        // A missing/invalid token must never turn "mine" into discovery.
        if (!$user && $scope === 'mine') {
            return response()->json([
                'scope' => 'mine',
                'items' => [],
            ]);
        }

        $hasMembershipState = Schema::hasColumn('club_user', 'estado');
        $hasClubState = Schema::hasColumn('clubs', 'estado');
        $hasCreatedBy = Schema::hasColumn('clubs', 'created_by');
        $hasGroupPichangas = Schema::hasTable('group_pichangas');
        $hasPichangaParticipants = Schema::hasTable('group_pichanga_participants');
        $memberClubIds = collect();
        $roles = collect();
        $ownerClubIds = collect();
        $pendingJoinClubIds = collect();

        if ($user) {
            $membershipQuery = ClubUser::query()
                ->where('user_id', $user->id)
                ->active();

            $activeMemberships = $membershipQuery->get(['club_id', 'rol']);
            $memberClubIds = $activeMemberships
                ->pluck('club_id')
                ->map(fn ($id) => (int) $id)
                ->unique()
                ->values();
            $roles = $activeMemberships->mapWithKeys(
                fn ($membership) => [(int) $membership->club_id => $membership->rol]
            );

            if ($hasCreatedBy) {
                $ownerClubIds = Club::query()
                    ->where('created_by', $user->id)
                    ->pluck('id')
                    ->map(fn ($id) => (int) $id)
                    ->unique()
                    ->values();
            }

            if (Schema::hasTable('club_join_requests')) {
                $pendingJoinClubIds = ClubJoinRequest::query()
                    ->where('requester_user_id', $user->id)
                    ->where('status', ClubJoinRequest::STATUS_PENDING)
                    ->pluck('club_id')
                    ->map(fn ($id) => (int) $id)
                    ->unique()
                    ->values();
            }
        }

        $query = Club::query()->withCount([
            'miembros' => function ($membershipQuery) use ($hasMembershipState) {
                if ($hasMembershipState) {
                    $membershipQuery->where('club_user.estado', 1);
                }
            },
        ]);

        if ($hasGroupPichangas) {
            $futureActivePichangas = function ($pichangaQuery) {
                $pichangaQuery
                    ->where('starts_at', '>=', now())
                    ->whereIn('status', ['published', 'confirmed']);
            };

            $query->withCount([
                'groupPichangas as pending_pichangas_count' => $futureActivePichangas,
                'groupPichangas as open_pichangas_count' => function ($pichangaQuery) use ($futureActivePichangas) {
                    $futureActivePichangas($pichangaQuery);
                    $pichangaQuery->where('is_open', true);
                },
            ]);

            if ($user && $hasPichangaParticipants) {
                $query->withCount([
                    'groupPichangas as my_confirmed_pichangas_count' => function ($pichangaQuery) use ($futureActivePichangas, $user) {
                        $futureActivePichangas($pichangaQuery);
                        $pichangaQuery->whereHas('participants', function ($participantQuery) use ($user) {
                            $participantQuery
                                ->where('user_id', (int) $user->id)
                                ->where('status', 'confirmed');
                        });
                    },
                ]);
            }
        }

        if ($scope === 'mine') {
            if ($memberClubIds->isEmpty()) {
                $query->whereRaw('1 = 0');
            } else {
                $query->whereIn('id', $memberClubIds->all());
            }
        } else {
            if ($hasClubState) {
                $query->where('estado', 1);
            }
            if (Schema::hasColumn('clubs', 'is_visible')) {
                $query->where('is_visible', 1);
            }
            if ($memberClubIds->isNotEmpty()) {
                $query->whereNotIn('id', $memberClubIds->all());
            }
        }

        if ($q !== '') {
            $query->where(function ($w) use ($q) {
                $w->where('nombre', 'like', "%{$q}%")
                    ->orWhere('slug', 'like', "%{$q}%");
            });
        }

        $clubs = $query->orderBy('nombre')->get();

        $items = $clubs->map(function (Club $club) use ($hasClubState, $hasGroupPichangas, $hasPichangaParticipants, $memberClubIds, $ownerClubIds, $pendingJoinClubIds, $roles, $user) {
            $clubId = (int) $club->id;
            $isMember = $memberClubIds->contains($clubId);
            $isOwner = $ownerClubIds->contains($clubId);

            return [
                'id' => $clubId,
                'nombre' => $club->nombre,
                'slug' => $club->slug,
                'descripcion' => $club->descripcion,
                'logo_url' => $this->publicLogoUrl($club->logo_url),
                'is_active' => !$hasClubState || (int) $club->estado === 1,
                'is_visible' => (bool) ($club->is_visible ?? true),
                'miembros_count' => (int) ($club->miembros_count ?? 0),
                'is_member' => $isMember,
                'is_owner' => $isOwner,
                'is_mine' => $isMember,
                'my_role' => $roles[$clubId] ?? null,
                'has_pending_join_request' => $pendingJoinClubIds->contains($clubId),
                'pending_pichangas_count' => $hasGroupPichangas
                    ? (int) ($club->pending_pichangas_count ?? 0)
                    : 0,
                'has_my_confirmed_pichanga' => $isMember && $user && $hasPichangaParticipants
                    ? (int) ($club->my_confirmed_pichangas_count ?? 0) > 0
                    : false,
                'my_confirmed_pichangas_count' => $isMember && $user && $hasPichangaParticipants
                    ? (int) ($club->my_confirmed_pichangas_count ?? 0)
                    : 0,
                'open_pichangas_count' => $hasGroupPichangas
                    ? (int) ($club->open_pichangas_count ?? 0)
                    : 0,
            ];
        })->values();

        return response()->json([
            'scope' => $scope,
            'items' => $items,
        ]);
    }

    public function store(Request $request)
    {
        $user = $request->user() ?? abort(401);

        $data = $request->validate([
            'nombre' => ['required', 'string', 'min:3', 'max:150'],
            'descripcion' => ['nullable', 'string'],
            'logo' => ['nullable', 'image', 'max:2048'],
            'is_visible' => ['nullable', 'boolean'],
            'link_join_enabled' => ['nullable', 'boolean'],
            'pichanga_create_scope' => ['nullable', Rule::in(['admins', 'members'])],
            'renotify_scope' => ['nullable', Rule::in(['admins', 'members'])],
            'renotify_cooldown_minutes' => ['nullable', 'integer', 'min:1', 'max:10080'],
            'renotify_max_per_pichanga' => ['nullable', 'integer', 'min:1', 'max:100'],
            'audience_max_degree' => ['nullable', 'integer', 'min:1', 'max:3'],
            'auto_reminder_enabled' => ['nullable', 'boolean'],
            'auto_reminder_48h_enabled' => ['nullable', 'boolean'],
            'auto_reminder_24h_enabled' => ['nullable', 'boolean'],
        ]);

        $nombre = trim($data['nombre']);
        $nameExists = Club::whereRaw('LOWER(nombre) = ?', [mb_strtolower($nombre)])->exists();
        abort_if($nameExists, 422, 'Ya existe un grupo con ese nombre.');

        if (array_key_exists('is_visible', $data) && !$data['is_visible']) {
            $data['link_join_enabled'] = false;
        }

        $slug = $this->buildUniqueSlug($nombre);

        $payload = array_merge($data, [
            'nombre' => $nombre,
            'slug' => $slug,
            'estado' => 1,
            'created_by' => $user->id,
        ]);
        if (Schema::hasColumn('clubs', 'join_code')) {
            $payload['join_code'] = $this->generateUniqueJoinCode();
        }
        $payload = $this->filterPayloadByTableColumns('clubs', $payload);
        if ($request->hasFile('logo')) {
            $payload['logo_url'] = $request->file('logo')->store('clubs', 'public');
        }

        $club = Club::create($payload);

        ClubUser::firstOrCreate(
            ['club_id' => $club->id, 'user_id' => $user->id],
            ['rol' => 'admin', 'estado' => 1]
        );

        return response()->json([
            'message' => 'Grupo creado.',
            'club' => $club->fresh(),
            'my_role' => 'admin',
        ], 201);
    }

    public function show(Request $request, Club $club)
    {
        $user = $request->user();
        $isSuper = (bool) ($user?->is_superadmin ?? false);
        $isMember = $user ? $this->isMember($club->id, $user->id) : false;
        $isActive = !Schema::hasColumn('clubs', 'estado') || (int) $club->estado === 1;

        $isVisible = true;
        if (Schema::hasColumn('clubs', 'is_visible')) {
            $isVisible = (bool) $club->is_visible;
        }

        abort_unless($isSuper || $isMember || ($isActive && $isVisible), 404);

        $myRole = $user
            ? ClubUser::where('club_id', $club->id)
                ->where('user_id', $user->id)
                ->active()
                ->value('rol')
            : null;
        $pendingJoinRequest = $user
            && Schema::hasTable('club_join_requests')
            ? ClubJoinRequest::query()
                ->where('club_id', $club->id)
                ->where('requester_user_id', $user->id)
                ->where('status', ClubJoinRequest::STATUS_PENDING)
                ->first()
            : null;
        $hasPendingJoinRequest = $pendingJoinRequest !== null;

        $rating = $this->ratingStatsForClub($club->id);

        return response()->json([
            'club' => [
                'id' => $club->id,
                'nombre' => $club->nombre,
                'slug' => $club->slug,
                'descripcion' => $club->descripcion,
                'logo_url' => $this->publicLogoUrl($club->logo_url),
                'is_active' => $isActive,
                'is_visible' => $isVisible,
                'link_join_enabled' => (bool) ($club->link_join_enabled ?? true),
                'pichanga_create_scope' => $club->pichanga_create_scope ?? 'admins',
                'renotify_scope' => $club->renotify_scope ?? 'admins',
                'renotify_cooldown_minutes' => (int) ($club->renotify_cooldown_minutes ?? 30),
                'renotify_max_per_pichanga' => (int) ($club->renotify_max_per_pichanga ?? 5),
                'audience_max_degree' => (int) ($club->audience_max_degree ?? 1),
                'auto_reminder_enabled' => (bool) ($club->auto_reminder_enabled ?? true),
                'auto_reminder_48h_enabled' => (bool) ($club->auto_reminder_48h_enabled ?? true),
                'auto_reminder_24h_enabled' => (bool) ($club->auto_reminder_24h_enabled ?? true),
                'share_url' => $this->buildClubShareUrl((int) $club->id),
                'rating_average' => $rating['average'],
                'rating_member_count' => $rating['count'],
                'has_pending_join_request' => $hasPendingJoinRequest,
                'pending_join_request_id' => $pendingJoinRequest?->id,
                'join_code' => $isMember || $isSuper ? $club->join_code : null,
                'join_url' => ($isMember || $isSuper) ? $this->buildJoinUrl($club->join_code) : null,
            ],
            'membership' => [
                'is_member' => $isMember,
                'my_role' => $myRole,
            ],
        ]);
    }

    public function update(Request $request, Club $club)
    {
        $user = $request->user() ?? abort(401);
        abort_unless($this->isClubAdminOrSuper($club->id, $user->id, (bool) $user->is_superadmin), 403);

        $data = $request->validate([
            'nombre' => ['sometimes', 'string', 'min:3', 'max:150'],
            'descripcion' => ['sometimes', 'nullable', 'string'],
            'logo' => ['sometimes', 'nullable', 'image', 'max:2048'],
            'is_visible' => ['sometimes', 'boolean'],
            'link_join_enabled' => ['sometimes', 'boolean'],
            'pichanga_create_scope' => ['sometimes', Rule::in(['admins', 'members'])],
            'renotify_scope' => ['sometimes', Rule::in(['admins', 'members'])],
            'renotify_cooldown_minutes' => ['sometimes', 'integer', 'min:1', 'max:10080'],
            'renotify_max_per_pichanga' => ['sometimes', 'integer', 'min:1', 'max:100'],
            'audience_max_degree' => ['sometimes', 'integer', 'min:1', 'max:3'],
            'auto_reminder_enabled' => ['sometimes', 'boolean'],
            'auto_reminder_48h_enabled' => ['sometimes', 'boolean'],
            'auto_reminder_24h_enabled' => ['sometimes', 'boolean'],
        ]);

        if (array_key_exists('nombre', $data)) {
            $nombre = trim((string) $data['nombre']);
            $nameExists = Club::where('id', '!=', $club->id)
                ->whereRaw('LOWER(nombre) = ?', [mb_strtolower($nombre)])
                ->exists();
            abort_if($nameExists, 422, 'Ya existe un grupo con ese nombre.');
            $data['nombre'] = $nombre;
        }

        $willBeVisible = array_key_exists('is_visible', $data)
            ? (bool) $data['is_visible']
            : (bool) ($club->is_visible ?? true);
        if (!$willBeVisible) {
            $data['link_join_enabled'] = false;
        }

        if ($request->hasFile('logo')) {
            $data['logo_url'] = $request->file('logo')->store('clubs', 'public');
        }
        unset($data['logo']);

        $payload = $this->filterPayloadByTableColumns('clubs', $data);
        $club->update($payload);

        return response()->json([
            'message' => 'Grupo actualizado.',
            'club' => $club->fresh(),
        ]);
    }

    public function members(Request $request, Club $club)
    {
        $user = $request->user();
        $isMember = $user ? $this->isMember($club->id, $user->id) : false;
        $isSuper = (bool) ($user?->is_superadmin ?? false);
        $isActive = !Schema::hasColumn('clubs', 'estado') || (int) $club->estado === 1;
        $isVisible = (bool) ($club->is_visible ?? true);

        $challengeContextAllowed = false;
        $challengeId = (int) $request->query('challenge_id', 0);
        if ($user && $challengeId > 0 && Schema::hasTable('club_challenges')) {
            $challenge = ClubChallenge::query()->find($challengeId);
            if ($challenge) {
                $viewerClubIds = ClubUser::query()
                    ->where('user_id', $user->id)
                    ->active()
                    ->pluck('club_id')
                    ->map(fn($i) => (int) $i)
                    ->all();

                $challengeContextAllowed =
                    in_array((int) $club->id, [(int) $challenge->challenger_club_id, (int) $challenge->challenged_club_id], true)
                    && (
                        in_array((int) $challenge->challenger_club_id, $viewerClubIds, true)
                        || in_array((int) $challenge->challenged_club_id, $viewerClubIds, true)
                    )
                    && in_array((string) $challenge->status, ['pending', 'negotiating', 'configuring', 'confirmed'], true);
            }
        }

        $publicMode = !$isSuper && !$isMember;
        abort_unless($isSuper || $isMember || ($isActive && $isVisible) || $challengeContextAllowed, 403);

        $ratingByUser = $this->ratingStatsForClub($club->id)['by_user'];

        $items = ClubUser::query()
            ->where('club_id', $club->id)
            ->active()
            ->with($publicMode
                ? 'user:id,name,nick,sexo,fec_nac,avatar_url'
                : 'user:id,name,nick,email,sexo,fec_nac,avatar_url')
            ->orderByRaw("CASE WHEN rol = 'admin' THEN 0 ELSE 1 END")
            ->orderBy('id')
            ->get()
            ->map(function (ClubUser $member) use ($ratingByUser) {
                $summary = $ratingByUser[(int) $member->user_id] ?? null;
                return [
                    'user_id' => $member->user_id,
                    'rol' => $member->rol,
                    'estado' => (int) ($member->estado ?? 1),
                    'joined_at' => optional($member->joined_at)->toISOString(),
                    'skill_average' => $summary['skill_average'] ?? null,
                    'stars' => $summary['stars'] ?? null,
                    'user' => $member->user,
                ];
            })->values();

        if ($publicMode && Schema::hasTable('group_pichanga_participants')) {
            $userIds = $items->pluck('user.id')->filter()->map(fn($i) => (int) $i)->all();
            $stats = DB::table('group_pichanga_participants')
                ->selectRaw('user_id, COUNT(*) as total')
                ->whereIn('user_id', $userIds)
                ->where('status', 'confirmed')
                ->groupBy('user_id')
                ->pluck('total', 'user_id')
                ->map(fn($v) => (int) $v)
                ->all();

            $items = $items->map(function (array $row) use ($stats) {
                $userId = (int) ($row['user']['id'] ?? 0);
                $row['user']['pichangas_confirmadas'] = (int) ($stats[$userId] ?? 0);
                return $row;
            })->values();
        }

        return response()->json([
            'items' => $items,
            'public_mode' => $publicMode,
        ]);
    }

    public function publicMemberProfile(Request $request, Club $club, User $member)
    {
        $viewer = $request->user();
        $isViewerMember = $viewer ? $this->isMember($club->id, $viewer->id) : false;
        $isSuper = (bool) ($viewer?->is_superadmin ?? false);
        $isActive = !Schema::hasColumn('clubs', 'estado') || (int) $club->estado === 1;
        $isVisible = !Schema::hasColumn('clubs', 'is_visible') || (bool) $club->is_visible;
        abort_unless($isSuper || $isViewerMember || ($isActive && $isVisible), 404);

        $membership = ClubUser::query()
            ->where('club_id', $club->id)
            ->where('user_id', $member->id)
            ->active()
            ->first();
        abort_unless($membership, 404);

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
        ];
        if (Schema::hasTable('calificaciones') && Schema::hasTable('group_pichanga_ratings')) {
            $summary = app(CombinedSkillRatingService::class)->summaryForUser((int) $member->id);
        }
        $pichangasPlayed = 0;
        $latestPichangas = [];
        if (Schema::hasTable('group_pichanga_participants') && Schema::hasTable('group_pichangas')) {
            $pichangasPlayed = GroupPichangaParticipant::query()
                ->join('group_pichangas as gp', 'gp.id', '=', 'group_pichanga_participants.pichanga_id')
                ->where('group_pichanga_participants.user_id', $member->id)
                ->where('group_pichanga_participants.status', 'confirmed')
                ->count();

            $latestPichangas = GroupPichangaParticipant::query()
                ->join('group_pichangas as gp', 'gp.id', '=', 'group_pichanga_participants.pichanga_id')
                ->where('group_pichanga_participants.user_id', $member->id)
                ->where('group_pichanga_participants.status', 'confirmed')
                ->orderBy('gp.starts_at', 'desc')
                ->limit(5)
                ->select([
                    'gp.id',
                    'gp.title',
                    'gp.starts_at',
                    'gp.status',
                ])
                ->get()
                ->toArray();
        }

        return response()->json([
            'club' => [
                'id' => (int) $club->id,
                'nombre' => $club->nombre,
            ],
            'member' => [
                'id' => (int) $member->id,
                'nick' => $member->nick ?: $member->name,
                'avatar_url' => $member->avatar_url,
                'rol' => $membership->rol,
            ],
            'stats' => [
                'star_average' => $summary['stars'],
                'player_average' => $summary['player_average'],
                'goalkeeper_average' => $summary['goalkeeper_average'],
                'primary_role' => $summary['primary_role'],
                'rating_count' => (int) $summary['votos'],
                'pichangas_played' => $pichangasPlayed,
                'skills' => [
                    'fisico' => $summary['fisico'],
                    'arquero' => $summary['arquero'],
                    'defensa' => $summary['defensa'],
                    'mediocampo' => $summary['mediocampo'],
                    'delantero' => $summary['delantero'],
                ],
            ],
            'ranking' => app(\App\Services\PlayerRankingService::class)->summaryForUser($member),
            'latest_pichangas' => $latestPichangas,
        ]);
    }

    public function setMemberRole(Request $request, Club $club, User $member)
    {
        $user = $request->user() ?? abort(401);
        abort_unless($this->isClubAdminOrSuper($club->id, $user->id, (bool) $user->is_superadmin), 403);

        $data = $request->validate([
            'rol' => ['required', Rule::in(['admin', 'miembro'])],
        ]);

        $row = ClubUser::where('club_id', $club->id)->where('user_id', $member->id)->active()->first();
        abort_unless($row, 404, 'El usuario no pertenece al grupo.');

        if ($row->rol === 'admin' && $data['rol'] === 'miembro') {
            $admins = ClubUser::where('club_id', $club->id)->active()->where('rol', 'admin')->count();
            abort_if($admins <= 1, 422, 'No puedes dejar el grupo sin administradores.');
        }

        $row->update(['rol' => $data['rol']]);

        return response()->json([
            'message' => 'Rol actualizado.',
            'user_id' => $member->id,
            'rol' => $data['rol'],
        ]);
    }

    public function removeMember(Request $request, Club $club, User $member)
    {
        $user = $request->user() ?? abort(401);
        abort_unless($this->isClubAdminOrSuper($club->id, $user->id, (bool) $user->is_superadmin), 403);

        $row = ClubUser::where('club_id', $club->id)->where('user_id', $member->id)->active()->first();
        abort_unless($row, 404, 'El usuario no pertenece al grupo.');

        if ($row->rol === 'admin') {
            $admins = ClubUser::where('club_id', $club->id)->active()->where('rol', 'admin')->count();
            abort_if($admins <= 1, 422, 'No puedes quitar al último administrador del grupo.');
        }

        $row->delete();

        return response()->json(['message' => 'Miembro removido.']);
    }

    /**
     * @return array{average:?float,count:int,by_user:array<int,array{skill_average:?float,stars:?float}>}
     */
    private function ratingStatsForClub(int $clubId): array
    {
        if (!Schema::hasTable('calificaciones') || !Schema::hasTable('group_pichanga_ratings')) {
            return ['average' => null, 'count' => 0, 'by_user' => []];
        }

        $memberIds = ClubUser::query()
            ->where('club_id', $clubId)
            ->active()
            ->pluck('user_id')
            ->map(fn ($id) => (int) $id)
            ->all();

        if (empty($memberIds)) {
            return ['average' => null, 'count' => 0, 'by_user' => []];
        }

        $ratings = app(CombinedSkillRatingService::class)
            ->averagesByUserIds($memberIds);
        $byUser = [];

        foreach ($ratings as $userId => $rating) {
            $summary = app(CombinedSkillRatingService::class)->deriveSummary($rating);
            if ($summary['stars'] !== null) {
                $byUser[(int) $userId] = [
                    'skill_average' => $summary['player_average'],
                    'stars' => $summary['stars'],
                ];
            }
        }

        return [
            'average' => empty($byUser) ? null : round((float) collect($byUser)->pluck('stars')->avg(), 2),
            'count' => count($byUser),
            'by_user' => $byUser,
        ];
    }

    private function buildUniqueSlug(string $name): string
    {
        $base = Str::slug($name);
        if ($base === '') {
            $base = 'grupo';
        }

        $slug = $base;
        $i = 2;
        while (Club::where('slug', $slug)->exists()) {
            $slug = "{$base}-{$i}";
            $i++;
        }

        return $slug;
    }

    private function generateUniqueJoinCode(): string
    {
        for ($attempt = 0; $attempt < 20; $attempt++) {
            $code = strtoupper(Str::random(12));
            if (!Club::whereRaw('UPPER(join_code) = ?', [$code])->exists()) {
                return $code;
            }
        }

        return strtoupper(Str::uuid()->toString()[0]) . strtoupper(Str::random(11));
    }

    private function isMember(int $clubId, int $userId): bool
    {
        return ClubUser::where('club_id', $clubId)->where('user_id', $userId)->active()->exists();
    }

    private function isClubAdminOrSuper(int $clubId, int $userId, bool $isSuper): bool
    {
        if ($isSuper) {
            return true;
        }

        return ClubUser::where('club_id', $clubId)
            ->where('user_id', $userId)
            ->active()
            ->where('rol', 'admin')
            ->exists();
    }

    private function filterPayloadByTableColumns(string $table, array $payload): array
    {
        return collect($payload)
            ->filter(fn($_, $key) => Schema::hasColumn($table, (string) $key))
            ->all();
    }

    private function buildJoinUrl(?string $joinCode): ?string
    {
        $code = strtoupper(trim((string) $joinCode));
        if ($code === '') {
            return null;
        }

        $base = rtrim((string) config('services.app_links.base_url', config('app.url')), '/');
        return $base . '/join/' . $code;
    }

    private function buildClubShareUrl(int $clubId): string
    {
        $base = rtrim((string) config('services.app_links.base_url', config('app.url')), '/');
        return $base . '/club/' . $clubId;
    }

    private function publicLogoUrl(?string $logoUrl): ?string
    {
        $logoUrl = trim((string) $logoUrl);
        if ($logoUrl === '') {
            return null;
        }

        if (Str::startsWith($logoUrl, ['http://', 'https://'])) {
            return $logoUrl;
        }

        return url(Storage::disk('public')->url(ltrim($logoUrl, '/')));
    }
}
