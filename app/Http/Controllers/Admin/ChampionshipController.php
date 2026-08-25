<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Cancha;
use App\Models\Championship;
use App\Models\Club;
use App\Models\ClubUser;
use App\Models\ChampionshipMatchEvent;
use App\Models\ChampionshipMatch;
use App\Models\ChampionshipAdmin;
use App\Models\ChampionshipResultAudit;
use App\Models\ChampionshipTeamInvitation;
use App\Models\ChampionshipTeam;
use App\Models\Polideportivo;
use App\Models\GroupPichanga;
use App\Models\User;
use App\Services\AdminAccessService;
use App\Services\ChampionshipFixtureService;
use App\Services\ChampionshipStatisticsService;
use App\Services\ChampionshipDeletionService;
use App\Services\ClubNotificationService;
use App\Services\PushNotificationService;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use App\Models\ChampionshipTeamMember;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Str;
use Illuminate\Validation\Rule;
use Illuminate\Validation\ValidationException;
use Illuminate\View\View;

class ChampionshipController extends Controller
{
    public function __construct(
        private readonly AdminAccessService $adminAccess,
        private readonly ChampionshipFixtureService $fixtures,
        private readonly ChampionshipStatisticsService $statistics,
        private readonly PushNotificationService $push,
        private readonly ChampionshipDeletionService $deletion,
        private readonly ClubNotificationService $clubNotifications
    ) {
    }

    public function index(Request $request): View
    {
        $user = $request->user();
        abort_unless($user && ($user->canPerformCriticalAdminActions()
            || ChampionshipAdmin::query()->where('user_id', $user->id)->exists()), 403);
        $query = Championship::query();
        if (!$user->canPerformCriticalAdminActions()) {
            $query->whereHas('admins', fn ($admins) => $admins->where('user_id', $user->id));
        }

        return view('admin.championships.index', [
            'items' => $query
                ->withCount('teams')
                ->with('creator:id,name,nick')
                ->orderByDesc('id')
                ->paginate(25),
        ]);
    }

    public function create(Request $request): View
    {
        $this->adminAccess->ensureSuper($request->user());

        return view('admin.championships.create', [
            'venues' => Polideportivo::query()
                ->select(['id', 'nombre', 'direccion'])
                ->orderBy('nombre')
                ->limit(500)
                ->get(),
        ]);
    }

    public function searchGroups(Request $request)
    {
        $this->adminAccess->ensureSuper($request->user());
        $query = trim((string) $request->query('q', ''));
        abort_if(mb_strlen($query) < 2, 422, 'Escribe al menos dos caracteres.');

        return response()->json(Club::query()
            ->select(['id', 'nombre', 'logo_url', 'is_visible'])
            ->where(function ($clubs) use ($query): void {
                $clubs->where('nombre', 'like', '%' . $query . '%')
                    ->orWhere('slug', 'like', '%' . $query . '%');
            })
            ->orderBy('nombre')
            ->limit(20)
            ->get()
            ->map(fn (Club $club) => [
                'id' => (int) $club->id,
                'name' => $club->nombre,
                'logo_url' => $club->logo_url,
                'is_visible' => (bool) $club->is_visible,
            ]));
    }

    public function searchUsers(Request $request)
    {
        $this->adminAccess->ensureBackoffice($request->user());
        $query = trim((string) $request->query('q', ''));
        abort_if(mb_strlen($query) < 2, 422, 'Escribe al menos dos caracteres.');

        return response()->json(User::query()
            ->select(['id', 'name', 'nick', 'avatar_url'])
            ->where(function ($users) use ($query): void {
                $users->where('nick', 'like', '%' . $query . '%')
                    ->orWhere('name', 'like', '%' . $query . '%');
            })
            ->orderByRaw('CASE WHEN nick LIKE ? THEN 0 ELSE 1 END', [$query . '%'])
            ->orderBy('nick')
            ->limit(20)
            ->get()
            ->map(fn (User $user) => [
                'id' => (int) $user->id,
                'name' => $user->name,
                'nick' => $user->nick,
                'avatar_url' => $user->avatar_url,
            ]));
    }

    public function store(Request $request): RedirectResponse
    {
        $this->adminAccess->ensureSuper($request->user());
        $data = $request->validate([
            'name' => ['required', 'string', 'max:160'],
            'description' => ['nullable', 'string', 'max:10000'],
            'visibility' => ['required', Rule::in(['public', 'private', 'link'])],
            'format' => ['required', Rule::in(['league', 'knockout', 'hybrid'])],
            'double_round_robin' => ['sometimes', 'boolean'],
            'points_win' => ['required', 'integer', 'min:0', 'max:100'],
            'points_draw' => ['required', 'integer', 'min:0', 'max:100'],
            'points_loss' => ['required', 'integer', 'min:0', 'max:100'],
            'max_teams' => ['required', 'integer', 'min:2', 'max:32'],
            'players_per_team' => ['required', 'integer', 'min:5', 'max:11'],
            'field_id' => ['nullable', 'integer', 'exists:polideportivo,id'],
            'registration_starts_at' => ['nullable', 'date'],
            'registration_ends_at' => ['nullable', 'date', 'after_or_equal:registration_starts_at'],
            'starts_at' => ['nullable', 'date'],
            'ends_at' => ['nullable', 'date', 'after_or_equal:starts_at'],
            'club_ids' => ['required', 'array', 'min:1'],
            'club_ids.*' => ['integer', 'distinct', 'exists:clubs,id'],
        ]);
        $slug = Str::slug($data['name']) ?: 'campeonato';
        $baseSlug = $slug;
        $suffix = 2;
        while (Championship::query()->where('slug', $slug)->exists()) {
            $slug = $baseSlug . '-' . $suffix++;
        }

        $championshipData = $data;
        unset($championshipData['club_ids']);
        $championship = Championship::create([
            ...$championshipData,
            'slug' => $slug,
            'format' => $data['format'],
            'status' => 'draft',
            'double_round_robin' => (bool) ($data['double_round_robin'] ?? false),
            'created_by_user_id' => $request->user()->id,
        ]);
        $championship->admins()->create([
            'user_id' => $request->user()->id,
            'role' => 'owner',
            'permissions_json' => ['all' => true],
        ]);
        $clubIds = array_values(array_unique(array_map('intval', $data['club_ids'])));
        $championship->clubs()->sync($clubIds);
        $championship->update(['club_id' => $clubIds[0]]);

        return redirect()->route('admin.championships.show', $championship)->with('ok', 'Campeonato creado como borrador.');
    }

    public function show(Request $request, Championship $championship): View
    {
        // The web backoffice is intentionally limited to superadmins, owners
        // and delegated championship managers.
        $this->ensureChampionshipAdminAccess($request, $championship);
        $championship->load([
            'creator:id,name,nick',
            'clubs:id,nombre,logo_url',
            'venue:id,nombre,direccion',
            'admins.user:id,name,nick',
            'teams.captain:id,name,nick',
            'teams.members.user:id,name,nick,avatar_url',
            'teams.homeMatches:id,home_team_id,status',
            'teams.awayMatches:id,away_team_id,status',
            'matchdays.matches.homeTeam.members.user:id,name,nick,avatar_url',
            'matchdays.matches.awayTeam.members.user:id,name,nick,avatar_url',
            'matchdays.matches.events.player:id,name,nick,avatar_url',
            'matchdays.matches.events.secondaryPlayer:id,name,nick,avatar_url',
        ])->loadCount('teams');
        $captainChangeStatuses = ['draft', 'registration', 'published'];
        $startedMatchStatuses = ['live', 'pending_result', 'finished'];
        $championship->teams->each(function ($team) use ($championship, $captainChangeStatuses, $startedMatchStatuses): void {
            $hasStartedMatch = $team->homeMatches->contains(
                fn ($match): bool => in_array($match->status, $startedMatchStatuses, true)
            ) || $team->awayMatches->contains(
                fn ($match): bool => in_array($match->status, $startedMatchStatuses, true)
            );
            $team->setAttribute(
                'captain_change_allowed',
                in_array($championship->status, $captainChangeStatuses, true) && !$hasStartedMatch
            );
        });
        $venues = Polideportivo::query()
            ->with(['canchas:id,id_polideportivo,nombre'])
            ->select(['id', 'nombre', 'direccion'])
            ->orderBy('nombre')
            ->limit(500)
            ->get();

        $user = $request->user();
        $admin = $championship->admins()->where('user_id', $user?->id)->first();
        $permissions = (array) ($admin?->permissions_json ?? []);
        $allPermissions = (bool) ($user?->canPerformCriticalAdminActions()
            || $admin?->role === 'owner'
            || ($permissions['all'] ?? false));
        return view('admin.championships.show', [
            'championship' => $championship,
            'venues' => $venues,
            'canManageSettings' => $allPermissions || (bool) ($permissions['manage_settings'] ?? false),
            'canManageTeams' => $allPermissions || (bool) ($permissions['manage_teams'] ?? false),
            'canManageRosters' => $allPermissions || (bool) ($permissions['manage_rosters'] ?? false),
            'canManageFixture' => $allPermissions || (bool) ($permissions['manage_fixture'] ?? false),
            'canManageResults' => $allPermissions || (bool) ($permissions['manage_match_results'] ?? false),
            'canManageAdmins' => $allPermissions || (bool) ($permissions['manage_admins'] ?? false),
        ]);
    }

    public function generateFixture(Request $request, Championship $championship): RedirectResponse
    {
        $this->ensureChampionshipPermission($request, $championship, 'manage_fixture');
        $created = $this->fixtures->generate($championship);

        return back()->with('ok', "Fixture generado: {$created} partidos. Ahora asigna fechas, horarios y canchas.");
    }

    public function publish(Request $request, Championship $championship): RedirectResponse
    {
        $this->ensureChampionshipPermission($request, $championship, 'manage_settings');
        $data = $request->validate([
            'status' => ['required', Rule::in(['registration', 'published'])],
        ]);
        if ($data['status'] === 'registration') {
            if ($championship->status !== 'draft') {
                return back()->withErrors(['status' => 'Las inscripciones ya fueron abiertas.']);
            }
        }
        if ($data['status'] === 'registration' && $championship->clubs()->count() < 1) {
            return back()->withErrors(['club_ids' => 'Asocia al menos un grupo antes de abrir inscripciones.']);
        }
        if ($data['status'] === 'published') {
            if ($championship->clubs()->count() < 1) {
                return back()->withErrors(['club_ids' => 'Asocia al menos un grupo antes de publicar.']);
            }
            if ($championship->teams()->count() < 2) {
                return back()->withErrors(['teams' => 'Añade al menos dos equipos antes de publicar.']);
            }
            if (!$championship->matches()->exists()) {
                return back()->withErrors(['fixture' => 'Genera el fixture antes de publicar el campeonato.']);
            }
        }
        if ($championship->visibility === 'link' && !$championship->share_token) {
            $championship->share_token = Str::random(48);
        }
        $previousStatus = $championship->status;
        $championship->update(['status' => $data['status']]);
        if ($previousStatus !== $data['status']) {
            $this->notifyChampionshipUsers(
                $championship,
                $this->championshipAudienceIds($championship),
                [
                    'type' => $data['status'] === 'registration' ? 'championship_registration_opened' : 'championship_published',
                    'title' => $data['status'] === 'registration' ? 'Inscripciones abiertas' : 'Campeonato publicado',
                    'body' => "Ya puedes consultar {$championship->name} en Fulbii.",
                    'dedupe_key' => 'championship:' . $championship->id . ':status:' . $data['status'],
                    'data_json' => [
                        'target_type' => 'championship',
                        'target_id' => (string) $championship->id,
                        'club_ids' => $championship->clubs()->pluck('clubs.id')->map(fn ($id) => (string) $id)->all(),
                        'image_url' => $championship->clubs()->value('logo_url'),
                    ],
                ],
                (int) $request->user()->id
            );
        }
        return back()->with('ok', $data['status'] === 'registration' ? 'Inscripciones abiertas.' : 'Campeonato publicado.');
    }

    public function updateGroups(Request $request, Championship $championship): RedirectResponse
    {
        $this->ensureChampionshipPermission($request, $championship, 'manage_settings');
        abort_if(!in_array($championship->status, ['draft', 'registration'], true), 422, 'Los grupos solo pueden editarse antes de publicar.');
        $data = $request->validate([
            'club_ids' => ['required', 'array', 'min:1'],
            'club_ids.*' => ['integer', 'distinct', 'exists:clubs,id'],
        ]);
        $clubIds = array_values(array_unique(array_map('intval', $data['club_ids'])));
        $championship->clubs()->sync($clubIds);
        $championship->update(['club_id' => $clubIds[0]]);
        return back()->with('ok', 'Grupos asociados actualizados.');
    }

    public function storeAdmin(Request $request, Championship $championship): RedirectResponse
    {
        $this->ensureChampionshipPermission($request, $championship, 'manage_admins');
        $data = $request->validate([
            'user_ids' => ['nullable', 'array', 'min:1'],
            'user_ids.*' => ['integer', 'distinct', 'exists:users,id'],
            'user_id' => ['nullable', 'integer', 'exists:users,id'],
            'permissions' => ['nullable', 'array'],
        ]);
        $userIds = array_values(array_unique(array_map('intval', $data['user_ids'] ?? [])));
        if (empty($userIds) && !empty($data['user_id'])) {
            $userIds = [(int) $data['user_id']];
        }
        abort_if(empty($userIds), 422, 'Selecciona al menos un gestor.');
        $permissions = $data['permissions'] ?? [
            'manage_teams' => true,
            'manage_rosters' => true,
            'manage_fixture' => true,
            'manage_match_live' => true,
            'manage_match_results' => true,
        ];
        foreach ($userIds as $userId) {
            $championship->admins()->updateOrCreate(
                ['user_id' => $userId],
                ['role' => 'manager', 'permissions_json' => $permissions]
            );
        }
        return back()->with('ok', count($userIds) . ' gestor(es) añadido(s) al campeonato.');
    }

    public function destroyAdmin(Request $request, Championship $championship, ChampionshipAdmin $admin): RedirectResponse
    {
        $this->ensureChampionshipPermission($request, $championship, 'manage_admins');
        abort_unless((int) $admin->championship_id === (int) $championship->id, 404);
        abort_if($admin->role === 'owner', 422, 'El propietario no puede eliminarse del campeonato.');
        abort_if($championship->admins()->where('role', 'owner')->doesntExist(), 422, 'El campeonato debe conservar un propietario.');
        $admin->delete();
        return back()->with('ok', 'Gestor retirado del campeonato.');
    }

    public function destroy(Request $request, Championship $championship): RedirectResponse
    {
        $this->ensureChampionshipPermission($request, $championship, 'manage_settings');
        $data = $request->validate([
            'confirmation' => ['required', 'string'],
        ]);
        abort_unless(trim($data['confirmation']) === $championship->name, 422, 'Escribe exactamente el nombre del campeonato para eliminarlo.');
        $this->deletion->delete($championship);
        return redirect()->route('admin.championships.index')->with('ok', 'Campeonato eliminado con todos sus datos relacionados.');
    }

    public function scheduleMatch(Request $request, ChampionshipMatch $match): RedirectResponse
    {
        $championship = $match->championship()->firstOrFail();
        $this->ensureChampionshipPermission($request, $championship, 'manage_fixture');
        $data = $request->validate([
            'field_id' => ['required', 'integer', 'exists:polideportivo,id'],
            'cancha_id' => ['required', 'integer', 'exists:cancha,id'],
            'starts_at' => ['required', 'date'],
            'ends_at' => ['required', 'date', 'after:starts_at'],
            'duration_minutes' => ['required', 'integer', 'min:15', 'max:240'],
        ]);
        $court = Cancha::query()->findOrFail((int) $data['cancha_id']);
        abort_if((int) $court->id_polideportivo !== (int) $data['field_id'], 422, 'La cancha no pertenece a la sede seleccionada.');
        $field = Polideportivo::query()->findOrFail((int) $data['field_id']);

        DB::transaction(function () use ($match, $championship, $field, $court, $data, $request): void {
            $match->update([
                'field_id' => $field->id,
                'cancha_id' => $court->id,
                'starts_at' => $data['starts_at'],
                'ends_at' => $data['ends_at'],
                'duration_minutes' => $data['duration_minutes'],
                'status' => 'scheduled',
            ]);
            $pichanga = $this->upsertPichanga($match, $championship, $field, $court, $request);
            $match->update(['pichanga_id' => $pichanga->id]);
        });
        return back()->with('ok', 'Partido programado y vinculado a una pichanga.');
    }

    public function scheduleMatchday(Request $request, \App\Models\ChampionshipMatchday $matchday): RedirectResponse
    {
        $championship = $matchday->championship()->firstOrFail();
        $this->ensureChampionshipPermission($request, $championship, 'manage_fixture');
        $data = $request->validate([
            'match_date' => ['required', 'date'],
            'starts_at' => ['required', 'date'],
            'ends_at' => ['required', 'date', 'after:starts_at'],
        ]);
        $matchday->update([
            'match_date' => $data['match_date'],
            'starts_at' => $data['starts_at'],
            'ends_at' => $data['ends_at'],
            'status' => 'scheduled',
        ]);
        return back()->with('ok', 'Horario de la jornada guardado.');
    }

    public function recordResult(Request $request, ChampionshipMatch $match): RedirectResponse
    {
        $championship = $match->championship()->firstOrFail();
        $this->ensureChampionshipPermission($request, $championship, 'manage_match_results');
        abort_if(!$match->home_team_id || !$match->away_team_id, 422, 'El partido todavía no tiene dos equipos definidos.');
        $data = $request->validate([
            'home_score' => ['required', 'integer', 'min:0', 'max:99'],
            'away_score' => ['required', 'integer', 'min:0', 'max:99'],
            'events_json' => ['nullable', 'string', 'max:40000'],
        ]);
        $events = $this->decodeEvents($data['events_json'] ?? null);
        $match->loadMissing(['homeTeam', 'awayTeam']);
        $teamIds = array_values(array_filter([(int) $match->home_team_id, (int) $match->away_team_id]));
        $memberIds = ChampionshipTeamMember::query()
            ->whereIn('championship_team_id', $teamIds)
            ->where('status', 'approved')
            ->pluck('user_id')->map(fn ($id) => (int) $id)->all();
        foreach ($events as $event) {
            if (!empty($event['championship_team_id']) && !in_array((int) $event['championship_team_id'], $teamIds, true)) {
                throw ValidationException::withMessages(['events_json' => 'Uno de los eventos no pertenece a los equipos de este partido.']);
            }
            foreach (['player_user_id', 'secondary_player_user_id'] as $key) {
                if (!empty($event[$key])) {
                    if (!in_array((int) $event[$key], $memberIds, true)) {
                        throw ValidationException::withMessages(['events_json' => 'El acta solo puede incluir jugadores aprobados de los equipos.']);
                    }
                }
            }
        }
        $before = $match->only(['status', 'home_score', 'away_score']);
        DB::transaction(function () use ($match, $data, $request, $events): void {
            $match->update([
                'home_score' => $data['home_score'],
                'away_score' => $data['away_score'],
                'status' => 'finished',
                'result_confirmed_by' => $request->user()->id,
                'result_confirmed_at' => now(),
            ]);
            $match->events()->delete();
            foreach ($events as $event) {
                $match->events()->create([
                    ...$event,
                    'created_by_user_id' => (int) $request->user()->id,
                ]);
            }
            ChampionshipResultAudit::create([
                'championship_match_id' => $match->id,
                'actor_user_id' => $request->user()->id,
                'action' => 'result_recorded_web',
                'before_json' => $before,
                'after_json' => $match->only(['status', 'home_score', 'away_score']),
            ]);
        });
        $this->fixtures->advanceWinner($match->fresh());
        $this->statistics->rebuild($championship);
        $this->notifyChampionshipUsers(
            $championship,
            $this->matchAudienceIds($match),
            [
                'type' => 'championship_match_result',
                'title' => 'Resultado actualizado',
                'body' => sprintf(
                    '%s %d–%d %s',
                    $match->homeTeam?->name ?: 'Local',
                    (int) $data['home_score'],
                    (int) $data['away_score'],
                    $match->awayTeam?->name ?: 'Visitante'
                ),
                'data_json' => [
                    'target_type' => 'championship_match',
                    'target_id' => (string) $match->id,
                    'championship_match_id' => (string) $match->id,
                ],
            ],
            (int) $request->user()->id
        );
        return back()->with('ok', 'Resultado guardado y estadísticas recalculadas.');
    }

    public function inviteTeamMember(Request $request, ChampionshipTeam $team): RedirectResponse
    {
        $championship = $team->championship()->firstOrFail();
        $this->ensureChampionshipPermission($request, $championship, 'manage_rosters');
        $data = $request->validate([
            'nick' => ['required', 'string', 'max:40'],
        ]);
        $user = User::query()->where('nick', trim($data['nick']))->firstOrFail();
        abort_if(
            ChampionshipTeamMember::query()->where('user_id', $user->id)
                ->whereHas('team', fn ($teams) => $teams->where('championship_id', $championship->id)->where('id', '<>', $team->id))
                ->whereIn('status', ['approved', 'invited', 'pending'])->exists(),
            422,
            'El jugador ya pertenece a otro equipo de este campeonato.'
        );
        abort_if($team->members()->where('user_id', $user->id)->whereIn('status', ['approved', 'invited', 'pending'])->exists(), 422, 'El jugador ya está en esta plantilla.');
        $invitation = DB::transaction(function () use ($team, $user, $request) {
            $team->members()->create([
                'user_id' => $user->id,
                'invited_by_user_id' => $request->user()->id,
                'status' => 'invited',
                'role' => 'player',
            ]);
            return ChampionshipTeamInvitation::create([
                'championship_id' => $team->championship_id,
                'championship_team_id' => $team->id,
                'invited_user_id' => $user->id,
                'invited_by_user_id' => $request->user()->id,
                'token' => Str::random(48),
                'status' => 'pending',
            ]);
        });
        $this->push->createForUser((int) $user->id, [
            'type' => 'championship_team_invitation',
            'title' => 'Invitación a equipo',
            'body' => "Te invitaron a {$team->name}.",
            'data_json' => [
                'target_type' => 'championship_team_invitation',
                'target_id' => (string) $invitation->id,
                'championship_id' => (string) $championship->id,
                'championship_team_id' => (string) $team->id,
                'invitation_id' => (string) $invitation->id,
            ],
        ]);
        return back()->with('ok', "Invitación enviada a @{$user->nick}.");
    }

    public function storeTeam(Request $request, Championship $championship): RedirectResponse
    {
        $this->ensureChampionshipPermission($request, $championship, 'manage_teams');
        abort_if($championship->teams()->count() >= $championship->max_teams, 422, 'Se alcanzó la cantidad máxima de equipos.');
        $data = $request->validate([
            'name' => ['required', 'string', 'max:120'],
            'color' => ['nullable', 'string', 'max:20'],
            'logo_url' => ['nullable', 'url', 'max:500'],
            'captain_user_id' => ['nullable', 'integer', 'exists:users,id'],
        ]);
        if (!empty($data['captain_user_id'])) {
            abort_if(
                ChampionshipTeamMember::query()
                    ->where('user_id', (int) $data['captain_user_id'])
                    ->whereHas('team', fn ($teams) => $teams->where('championship_id', $championship->id))
                    ->whereIn('status', ['approved', 'invited', 'pending'])
                    ->exists(),
                422,
                'Ese usuario ya es miembro de un equipo de este campeonato.'
            );
        }
        $team = $championship->teams()->create([
            'name' => trim($data['name']),
            'color' => $data['color'] ?? null,
            'logo_url' => $data['logo_url'] ?? null,
            'captain_user_id' => $data['captain_user_id'] ?? null,
            'status' => 'draft',
            'sort_order' => (int) $championship->teams()->max('sort_order') + 1,
        ]);
        if (!empty($data['captain_user_id'])) {
            $team->members()->create([
                'user_id' => (int) $data['captain_user_id'],
                'invited_by_user_id' => $request->user()->id,
                'status' => 'approved',
                'role' => 'captain',
                'joined_at' => now(),
            ]);
        }
        return back()->with('ok', 'Equipo añadido al campeonato.');
    }

    public function setCaptain(Request $request, ChampionshipTeam $team): RedirectResponse
    {
        $championship = $team->championship()->firstOrFail();
        $this->ensureChampionshipPermission($request, $championship, 'manage_teams');
        abort_if(
            !in_array($championship->status, ['draft', 'registration', 'published'], true),
            422,
            'El capitán solo puede cambiarse mientras el campeonato esté activo.'
        );
        abort_if(
            $team->homeMatches()->whereIn('status', ['live', 'pending_result', 'finished'])->exists()
            || $team->awayMatches()->whereIn('status', ['live', 'pending_result', 'finished'])->exists(),
            422,
            'No puedes cambiar el capitán después de iniciar un partido.'
        );
        $data = $request->validate([
            'user_id' => ['required', 'integer', 'exists:users,id'],
        ]);
        $userId = (int) $data['user_id'];
        abort_if(
            ChampionshipTeamMember::query()
                ->where('user_id', $userId)
                ->whereHas('team', fn ($teams) => $teams
                    ->where('championship_id', $championship->id)
                    ->where('id', '<>', $team->id))
                ->whereIn('status', ['approved', 'invited', 'pending'])
                ->exists(),
            422,
            'Ese usuario ya es miembro de otro equipo de este campeonato.'
        );

        DB::transaction(function () use ($team, $userId, $request): void {
            $team->members()->where('role', 'captain')->update(['role' => 'player']);
            $team->members()->updateOrCreate(
                ['user_id' => $userId],
                [
                    'invited_by_user_id' => $request->user()->id,
                    'status' => 'approved',
                    'role' => 'captain',
                    'joined_at' => now(),
                    'removed_at' => null,
                ]
            );
            $team->update(['captain_user_id' => $userId]);
        });

        return back()->with('ok', 'Capitán actualizado.');
    }

    private function ensureChampionshipPermission(
        Request $request,
        Championship $championship,
        string $permission
    ): void {
        $user = $request->user();
        if ($user?->canPerformCriticalAdminActions()) {
            return;
        }

        $admin = $championship->admins()->where('user_id', $user?->id)->first();
        $allowed = $admin && (
            $admin->role === 'owner'
            || (((array) $admin->permissions_json)[$permission] ?? false)
        );
        abort_unless($allowed, 403, 'No tienes permisos para gestionar este campeonato.');
    }

    private function ensureChampionshipAdminAccess(Request $request, Championship $championship): void
    {
        $user = $request->user();
        if ($user?->canPerformCriticalAdminActions()) {
            return;
        }

        abort_unless(
            $user && $championship->admins()->where('user_id', $user->id)->exists(),
            403,
            'No tienes acceso de gestión a este campeonato.'
        );
    }

    /** @return array<int> */
    private function matchAudienceIds(ChampionshipMatch $match): array
    {
        $match->loadMissing(['championship', 'homeTeam', 'awayTeam']);
        $teamIds = array_values(array_filter([
            (int) $match->home_team_id,
            (int) $match->away_team_id,
        ]));
        $members = ChampionshipTeamMember::query()
            ->whereIn('championship_team_id', $teamIds)
            ->whereIn('status', ['approved', 'invited'])
            ->pluck('user_id')
            ->all();
        $admins = $match->championship
            ? $match->championship->admins()->pluck('user_id')->all()
            : [];

        return array_values(array_unique(array_merge($members, $admins)));
    }

    /** @return array<int, array<string, mixed>> */
    private function decodeEvents(?string $json): array
    {
        if (trim((string) $json) === '') {
            return [];
        }
        $decoded = json_decode($json, true);
        if (!is_array($decoded)) {
            throw ValidationException::withMessages(['events_json' => 'El contenido avanzado de eventos no es una lista válida.']);
        }
        $allowed = ['goal', 'own_goal', 'assist', 'yellow_card', 'red_card', 'substitution_in', 'substitution_out'];
        return collect($decoded)->map(function ($event) use ($allowed) {
            if (!is_array($event) || !in_array($event['event_type'] ?? null, $allowed, true)) {
                throw ValidationException::withMessages(['events_json' => 'El tipo de evento no es válido.']);
            }
            $minute = $event['minute'] ?? null;
            if ($minute !== null && (!is_numeric($minute) || floor((float) $minute) !== (float) $minute || (float) $minute < 0 || (float) $minute > 200)) {
                throw ValidationException::withMessages(['events_json' => 'El minuto de un evento debe estar entre 0 y 200.']);
            }
            return [
                'event_type' => $event['event_type'],
                'championship_team_id' => !empty($event['championship_team_id']) ? (int) $event['championship_team_id'] : null,
                'player_user_id' => !empty($event['player_user_id']) ? (int) $event['player_user_id'] : null,
                'secondary_player_user_id' => !empty($event['secondary_player_user_id']) ? (int) $event['secondary_player_user_id'] : null,
                'minute' => $minute !== null ? (int) $minute : null,
            ];
        })->values()->all();
    }

    /** @return array<int> */
    private function championshipAudienceIds(Championship $championship): array
    {
        $clubIds = $this->associatedClubIds($championship);
        $groupMembers = ClubUser::query()
            ->whereIn('club_id', $clubIds)
            ->active()
            ->pluck('user_id')
            ->all();
        return array_values(array_unique(array_merge(
            $groupMembers,
            $championship->admins()->pluck('user_id')->all(),
            ChampionshipTeamMember::query()->whereHas('team', fn ($teams) => $teams->where('championship_id', $championship->id))
                ->whereIn('status', ['approved', 'invited'])->pluck('user_id')->all()
        )));
    }

    private function notifyChampionshipUsers(Championship $championship, array $userIds, array $payload, ?int $actor = null): void
    {
        $recipients = array_values(array_diff(
            array_unique(array_map('intval', $userIds)),
            $actor ? [(int) $actor] : []
        ));
        if (!$recipients) {
            return;
        }

        $data = array_merge((array) ($payload['data_json'] ?? []), [
            'target_type' => $payload['data_json']['target_type'] ?? 'championship',
            'target_id' => $payload['data_json']['target_id'] ?? (string) $championship->id,
            'championship_id' => (string) $championship->id,
            'image_kind' => 'championship',
        ]);
        $notificationPayload = [
            ...$payload,
            'category' => $payload['category'] ?? 'pichangas',
            'dedupe_key' => $payload['dedupe_key'] ?? implode(':', [
                'championship',
                $championship->id,
                (string) ($payload['type'] ?? 'update'),
                (string) ($payload['target_id'] ?? $data['target_id']),
            ]),
            'data_json' => $data,
        ];

        // Deliver through every associated group so each user's mute and
        // category preference is respected. The shared key keeps members of
        // multiple groups from receiving duplicate rows.
        $clubIds = $this->associatedClubIds($championship);
        if ($clubIds) {
            foreach (Club::query()->whereIn('id', $clubIds)->get() as $club) {
                $this->clubNotifications->notifyUsers($club, $recipients, $notificationPayload, $actor);
            }
            return;
        }

        // Legacy championships without an association remain deliverable.
        $this->push->createForUsers($recipients, $notificationPayload);
    }

    /** @return array<int> */
    private function associatedClubIds(Championship $championship): array
    {
        if (Schema::hasTable('championship_clubs')) {
            return $championship->clubs()->pluck('clubs.id')->map(fn ($id) => (int) $id)->all();
        }

        return $championship->club_id ? [(int) $championship->club_id] : [];
    }

    private function upsertPichanga(
        ChampionshipMatch $match,
        Championship $championship,
        Polideportivo $field,
        Cancha $court,
        Request $request
    ): GroupPichanga {
        $match->loadMissing(['homeTeam', 'awayTeam']);
        $payload = [
            'club_id' => null,
            'created_by_user_id' => (int) $request->user()->id,
            'title' => mb_substr(($match->homeTeam?->name ?: 'Local') . ' vs ' . ($match->awayTeam?->name ?: 'Visitante') . ' · ' . $championship->name, 0, 160),
            'description' => 'Partido oficial del campeonato ' . $championship->name,
            'field_id' => (int) $field->id,
            'cancha_id' => (int) $court->id,
            'address' => $field->direccion,
            'starts_at' => $match->starts_at,
            'duration_minutes' => (int) $match->duration_minutes,
            'capacity' => (int) $championship->players_per_team * 2,
            'status' => 'published',
            'confirmation_mode' => 'auto_by_capacity',
            'is_open' => false,
            'allow_external_requests' => false,
            'match_format' => 'versus',
            'team_count' => 2,
            'players_per_team' => (int) $championship->players_per_team,
            'match_context' => 'championship',
            'championship_id' => (int) $championship->id,
            'championship_match_id' => (int) $match->id,
        ];
        $payload = array_filter($payload, static fn ($value) => $value !== null);
        $columns = array_flip(Schema::getColumnListing('group_pichangas'));
        $payload = array_intersect_key($payload, $columns);
        $pichanga = $match->pichanga_id ? GroupPichanga::query()->find((int) $match->pichanga_id) : null;
        if (!$pichanga) {
            return GroupPichanga::query()->create($payload);
        }
        $pichanga->update($payload);
        return $pichanga->fresh();
    }
}
