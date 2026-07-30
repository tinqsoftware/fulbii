<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Club;
use App\Models\ClubChallenge;
use App\Models\ClubUser;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Str;
use Illuminate\Validation\Rule;

class ClubApiController extends Controller
{
    public function index(Request $request)
    {
        $user = $request->user() ?? abort(401);

        $scope = (string) $request->query('scope', 'mine');
        if (!in_array($scope, ['mine', 'discover'], true)) {
            $scope = 'mine';
        }

        $q = trim((string) $request->query('q', ''));

        $memberClubIds = ClubUser::where('user_id', $user->id)->pluck('club_id');

        $query = Club::query()->withCount('miembros');

        if ($scope === 'mine') {
            $query->whereIn('id', $memberClubIds);
        } else {
            if (Schema::hasColumn('clubs', 'is_visible')) {
                $query->where('is_visible', 1);
            }
            $query->whereNotIn('id', $memberClubIds);
        }

        if ($q !== '') {
            $query->where(function ($w) use ($q) {
                $w->where('nombre', 'like', "%{$q}%")
                    ->orWhere('slug', 'like', "%{$q}%");
            });
        }

        $clubs = $query->orderBy('nombre')->get();
        $roles = ClubUser::where('user_id', $user->id)->pluck('rol', 'club_id');

        $items = $clubs->map(function (Club $club) use ($roles) {
            return [
                'id' => $club->id,
                'nombre' => $club->nombre,
                'slug' => $club->slug,
                'descripcion' => $club->descripcion,
                'logo_url' => $club->logo_url,
                'is_visible' => (bool) ($club->is_visible ?? true),
                'miembros_count' => (int) ($club->miembros_count ?? 0),
                'my_role' => $roles[$club->id] ?? null,
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
        $user = $request->user() ?? abort(401);
        $isSuper = (bool) $user->is_superadmin;
        $isMember = $this->isMember($club->id, $user->id);

        $isVisible = true;
        if (Schema::hasColumn('clubs', 'is_visible')) {
            $isVisible = (bool) $club->is_visible;
        }

        abort_unless($isSuper || $isMember || $isVisible, 404);

        $myRole = ClubUser::where('club_id', $club->id)
            ->where('user_id', $user->id)
            ->value('rol');

        return response()->json([
            'club' => [
                'id' => $club->id,
                'nombre' => $club->nombre,
                'slug' => $club->slug,
                'descripcion' => $club->descripcion,
                'logo_url' => $club->logo_url,
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

        $payload = $this->filterPayloadByTableColumns('clubs', $data);
        $club->update($payload);

        return response()->json([
            'message' => 'Grupo actualizado.',
            'club' => $club->fresh(),
        ]);
    }

    public function members(Request $request, Club $club)
    {
        $user = $request->user() ?? abort(401);
        $isMember = $this->isMember($club->id, $user->id);
        $isSuper = (bool) $user->is_superadmin;
        $isVisible = (bool) ($club->is_visible ?? true);

        $challengeContextAllowed = false;
        $challengeId = (int) $request->query('challenge_id', 0);
        if ($challengeId > 0 && Schema::hasTable('club_challenges')) {
            $challenge = ClubChallenge::query()->find($challengeId);
            if ($challenge) {
                $viewerClubIds = ClubUser::query()
                    ->where('user_id', $user->id)
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
        abort_unless($isSuper || $isMember || $isVisible || $challengeContextAllowed, 403);

        $items = ClubUser::query()
            ->where('club_id', $club->id)
            ->with($publicMode
                ? 'user:id,name,nick,sexo,fec_nac,avatar_url'
                : 'user:id,name,nick,email,sexo,fec_nac,avatar_url')
            ->orderByRaw("CASE WHEN rol = 'admin' THEN 0 ELSE 1 END")
            ->orderBy('id')
            ->get()
            ->map(function (ClubUser $member) {
                return [
                    'user_id' => $member->user_id,
                    'rol' => $member->rol,
                    'estado' => (int) ($member->estado ?? 1),
                    'joined_at' => optional($member->joined_at)->toISOString(),
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

    public function setMemberRole(Request $request, Club $club, User $member)
    {
        $user = $request->user() ?? abort(401);
        abort_unless($this->isClubAdminOrSuper($club->id, $user->id, (bool) $user->is_superadmin), 403);

        $data = $request->validate([
            'rol' => ['required', Rule::in(['admin', 'miembro'])],
        ]);

        $row = ClubUser::where('club_id', $club->id)->where('user_id', $member->id)->first();
        abort_unless($row, 404, 'El usuario no pertenece al grupo.');

        if ($row->rol === 'admin' && $data['rol'] === 'miembro') {
            $admins = ClubUser::where('club_id', $club->id)->where('rol', 'admin')->count();
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

        $row = ClubUser::where('club_id', $club->id)->where('user_id', $member->id)->first();
        abort_unless($row, 404, 'El usuario no pertenece al grupo.');

        if ($row->rol === 'admin') {
            $admins = ClubUser::where('club_id', $club->id)->where('rol', 'admin')->count();
            abort_if($admins <= 1, 422, 'No puedes quitar al último administrador del grupo.');
        }

        $row->delete();

        return response()->json(['message' => 'Miembro removido.']);
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
        return ClubUser::where('club_id', $clubId)->where('user_id', $userId)->exists();
    }

    private function isClubAdminOrSuper(int $clubId, int $userId, bool $isSuper): bool
    {
        if ($isSuper) {
            return true;
        }

        return ClubUser::where('club_id', $clubId)
            ->where('user_id', $userId)
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
}
