<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Cancha;
use App\Models\Championship;
use App\Models\ChampionshipAdmin;
use App\Models\ChampionshipMatch;
use App\Models\ChampionshipMatchEvent;
use App\Models\ChampionshipMatchday;
use App\Models\ChampionshipMatchSquad;
use App\Models\ChampionshipPlayerStat;
use App\Models\ChampionshipTeamInvitation;
use App\Models\ChampionshipTeam;
use App\Models\ChampionshipTeamMember;
use App\Models\Club;
use App\Models\ClubUser;
use App\Models\GroupPichanga;
use App\Models\Polideportivo;
use App\Models\User;
use App\Services\ChampionshipFixtureService;
use App\Services\ChampionshipStatisticsService;
use App\Services\ClubNotificationService;
use App\Services\PushNotificationService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Str;
use Illuminate\Validation\Rule;

class ChampionshipController extends Controller
{
    public function __construct(
        private readonly ChampionshipFixtureService $fixtures,
        private readonly ChampionshipStatisticsService $statistics,
        private readonly ClubNotificationService $clubNotifications,
        private readonly PushNotificationService $push
    )
    {
    }

    public function index(Request $request)
    {
        $user = $request->user();
        $query = Championship::query()->withCount('teams');
        if (Schema::hasTable('championship_clubs')) {
            $query->with('clubs:id,nombre,logo_url');
        }

        if ($user && $user->is_superadmin) {
            // Superadmin sees drafts and private championships as well.
        } elseif ($user) {
            $query->where(function ($scope) use ($user) {
                $scope->where(function ($public) {
                    $public->whereIn('visibility', ['public', 'link'])
                        ->whereIn('status', ['registration', 'published', 'in_progress', 'completed']);
                })
                    ->orWhere('created_by_user_id', $user->id)
                    ->orWhereHas('admins', fn ($admins) => $admins->where('user_id', $user->id))
                    ->orWhereHas('teams.members', fn ($members) => $members->where('user_id', $user->id));
            });
        } else {
            $query->where('visibility', 'public')
                ->whereIn('status', ['registration', 'published', 'in_progress', 'completed']);
        }

        $items = $query->orderByRaw("FIELD(status, 'in_progress', 'registration', 'published', 'completed', 'draft', 'archived')")
            ->orderByDesc('starts_at')
            ->limit(100)
            ->get()
            ->map(fn (Championship $championship) => $this->serializeChampionship($championship));

        return response()->json(['items' => $items->values()]);
    }

    public function store(Request $request)
    {
        $user = $request->user();
        abort_unless((bool) $user->is_superadmin, 403, 'Solo un superadmin puede crear campeonatos por ahora.');

        $data = $request->validate([
            'name' => ['required', 'string', 'max:160'],
            'description' => ['nullable', 'string', 'max:10000'],
            'visibility' => ['required', Rule::in(['public', 'private', 'link'])],
            'format' => ['sometimes', Rule::in(['league', 'knockout', 'hybrid'])],
            'double_round_robin' => ['sometimes', 'boolean'],
            'points_win' => ['sometimes', 'integer', 'min:0', 'max:100'],
            'points_draw' => ['sometimes', 'integer', 'min:0', 'max:100'],
            'points_loss' => ['sometimes', 'integer', 'min:0', 'max:100'],
            'max_teams' => ['sometimes', 'integer', 'min:2', 'max:32'],
            'players_per_team' => ['sometimes', 'integer', 'min:5', 'max:11'],
            'club_id' => ['nullable', 'integer', 'exists:clubs,id'],
            'club_ids' => ['nullable', 'array', 'min:1'],
            'club_ids.*' => ['integer', 'distinct', 'exists:clubs,id'],
            'field_id' => ['nullable', 'integer', 'exists:polideportivo,id'],
            'registration_starts_at' => ['nullable', 'date'],
            'registration_ends_at' => ['nullable', 'date', 'after_or_equal:registration_starts_at'],
            'starts_at' => ['nullable', 'date'],
            'ends_at' => ['nullable', 'date', 'after_or_equal:starts_at'],
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
            'share_token' => ($data['visibility'] ?? null) === 'link' ? Str::random(48) : null,
            'format' => $data['format'] ?? 'league',
            'double_round_robin' => (bool) ($data['double_round_robin'] ?? false),
            'points_win' => (int) ($data['points_win'] ?? 3),
            'points_draw' => (int) ($data['points_draw'] ?? 1),
            'points_loss' => (int) ($data['points_loss'] ?? 0),
            'max_teams' => (int) ($data['max_teams'] ?? 8),
            'players_per_team' => (int) ($data['players_per_team'] ?? 7),
            'created_by_user_id' => $user->id,
            'status' => 'draft',
        ]);

        $championship->admins()->create([
            'user_id' => $user->id,
            'role' => 'owner',
            'permissions_json' => ['all' => true],
        ]);
        $clubIds = array_values(array_unique(array_map('intval', $data['club_ids'] ?? [])));
        if (empty($clubIds) && !empty($data['club_id'])) {
            $clubIds = [(int) $data['club_id']];
        }
        if (in_array($data['visibility'], ['public', 'link'], true) && !$clubIds) {
            abort(422, 'Asocia al menos un grupo para un campeonato dirigido a la comunidad.');
        }
        if (!empty($clubIds) && Schema::hasTable('championship_clubs')) {
            $championship->clubs()->sync($clubIds);
            $championship->update(['club_id' => $clubIds[0]]);
        }

        return response()->json([
            'message' => 'Campeonato creado como borrador.',
            'championship' => $this->serializeChampionship($championship->loadCount('teams')),
        ], 201);
    }

    public function show(Request $request, Championship $championship)
    {
        $this->authorizeView($request, $championship);

        $championship->load([
            'creator:id,name,nick,avatar_url',
            'venue:id,nombre,direccion',
            'admins.user:id,name,nick,avatar_url',
            'clubs:id,nombre,logo_url',
            'teams.captain:id,name,nick,avatar_url',
            'teams.members',
        ])->loadCount('teams');

        return response()->json([
            'championship' => $this->serializeChampionship($championship, true, $request->user()),
        ]);
    }

    public function generateFixture(Request $request, Championship $championship)
    {
        $this->authorizeManage($request, $championship, 'manage_fixture');
        $created = $this->fixtures->generate($championship);
        $this->notifyChampionshipUsers(
            $championship,
            $this->championshipAudienceIds($championship),
            [
                'type' => 'championship_fixture_generated',
                'title' => 'Fixture generado',
                'body' => "Se generaron {$created} partidos para {$championship->name}.",
                'target_type' => 'championship',
                'target_id' => (int) $championship->id,
            ],
            (int) $request->user()->id
        );

        return response()->json([
            'message' => 'Fixture generado. Ahora asigna jornadas, horarios y canchas.',
            'matches_created' => $created,
        ], 201);
    }

    public function standings(Request $request, Championship $championship)
    {
        $this->authorizeView($request, $championship);
        $championship->load('teams');

        $rows = $championship->teams->mapWithKeys(fn (ChampionshipTeam $team) => [
            $team->id => [
                'team_id' => (int) $team->id,
                'team_name' => $team->name,
                'played' => 0,
                'won' => 0,
                'drawn' => 0,
                'lost' => 0,
                'goals_for' => 0,
                'goals_against' => 0,
                'goal_difference' => 0,
                'points' => 0,
            ],
        ]);

        ChampionshipMatch::query()
            ->where('championship_id', $championship->id)
            ->where('status', 'finished')
            ->whereNotNull('home_score')
            ->whereNotNull('away_score')
            ->get()
            ->each(function (ChampionshipMatch $match) use (&$rows, $championship) {
                $home = $rows->get($match->home_team_id);
                $away = $rows->get($match->away_team_id);
                if (!$home || !$away) {
                    return;
                }
                $homeGoals = (int) $match->home_score;
                $awayGoals = (int) $match->away_score;
                $home['played']++;
                $away['played']++;
                $home['goals_for'] += $homeGoals;
                $home['goals_against'] += $awayGoals;
                $away['goals_for'] += $awayGoals;
                $away['goals_against'] += $homeGoals;
                if ($homeGoals === $awayGoals) {
                    $home['drawn']++;
                    $away['drawn']++;
                    $home['points'] += (int) $championship->points_draw;
                    $away['points'] += (int) $championship->points_draw;
                } elseif ($homeGoals > $awayGoals) {
                    $home['won']++;
                    $away['lost']++;
                    $home['points'] += (int) $championship->points_win;
                    $away['points'] += (int) $championship->points_loss;
                } else {
                    $away['won']++;
                    $home['lost']++;
                    $away['points'] += (int) $championship->points_win;
                    $home['points'] += (int) $championship->points_loss;
                }
                $home['goal_difference'] = $home['goals_for'] - $home['goals_against'];
                $away['goal_difference'] = $away['goals_for'] - $away['goals_against'];
                $rows->put($home['team_id'], $home);
                $rows->put($away['team_id'], $away);
            });

        $sorted = $rows->values()->sort(function (array $a, array $b) {
            return [$b['points'], $b['goal_difference'], $b['goals_for'], $a['team_name']]
                <=> [$a['points'], $a['goal_difference'], $a['goals_for'], $b['team_name']];
        })->values()->map(function (array $row, int $index) {
            $row['position'] = $index + 1;
            return $row;
        });

        return response()->json([
            'championship_id' => (int) $championship->id,
            'tie_breakers' => ['points', 'goal_difference', 'goals_for', 'manual_creator_decision'],
            'items' => $sorted,
        ]);
    }

    public function storeAdmin(Request $request, Championship $championship)
    {
        $this->authorizeManage($request, $championship, 'manage_admins');
        $data = $request->validate([
            'user_id' => ['required', 'integer', 'exists:users,id'],
            'role' => ['sometimes', Rule::in(['manager'])],
            'permissions' => ['nullable', 'array'],
        ]);

        $admin = ChampionshipAdmin::updateOrCreate(
            ['championship_id' => $championship->id, 'user_id' => (int) $data['user_id']],
            [
                'role' => $data['role'] ?? 'manager',
                'permissions_json' => $data['permissions'] ?? [
                    'manage_teams' => true,
                    'manage_rosters' => true,
                    'manage_fixture' => true,
                    'manage_match_live' => true,
                    'manage_match_results' => true,
                ],
            ]
        );

        return response()->json(['admin' => $admin->load('user:id,name,nick,avatar_url')], 201);
    }

    public function removeAdmin(Request $request, Championship $championship, int $user)
    {
        $this->authorizeManage($request, $championship, 'manage_admins');
        $admin = $championship->admins()->where('user_id', $user)->firstOrFail();
        abort_if($admin->role === 'owner', 422, 'El creador no puede retirarse como propietario.');
        $admin->delete();

        return response()->json(['message' => 'Gestor retirado.']);
    }

    public function storeTeam(Request $request, Championship $championship)
    {
        $this->authorizeManage($request, $championship, 'manage_teams');
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
                    ->whereHas('team', fn ($teams) => $teams
                        ->where('championship_id', $championship->id))
                    ->whereIn('status', ['approved', 'invited', 'pending'])
                    ->exists(),
                422,
                'Ese usuario ya está asignado a un equipo de este campeonato.'
            );
        }

        $team = DB::transaction(function () use ($championship, $data) {
            $team = $championship->teams()->create([
                'name' => trim((string) $data['name']),
                'color' => $data['color'] ?? null,
                'logo_url' => $data['logo_url'] ?? null,
                'captain_user_id' => $data['captain_user_id'] ?? null,
                'status' => 'draft',
                'sort_order' => (int) $championship->teams()->max('sort_order') + 1,
            ]);

            if (!empty($data['captain_user_id'])) {
                $team->members()->create([
                    'user_id' => (int) $data['captain_user_id'],
                    'invited_by_user_id' => $championship->created_by_user_id,
                    'status' => 'approved',
                    'role' => 'captain',
                    'joined_at' => now(),
                ]);
            }

            return $team;
        });

        return response()->json(['team' => $team->load('captain:id,name,nick,avatar_url')], 201);
    }

    public function inviteTeamMember(Request $request, ChampionshipTeam $team)
    {
        $this->authorizeTeamRoster($request, $team);
        $data = $request->validate([
            'user_id' => ['nullable', 'integer', 'exists:users,id'],
            'nick' => ['nullable', 'string', 'max:40'],
        ]);
        abort_if(empty($data['user_id']) && trim((string) ($data['nick'] ?? '')) === '', 422, 'Indica el ID o nickname del jugador.');
        $userId = (int) ($data['user_id'] ?? User::query()->where('nick', trim((string) $data['nick']))->value('id'));
        abort_if($userId <= 0, 404, 'No encontramos ese jugador.');
        $authId = (int) $request->user()->id;

        abort_if(
            ChampionshipTeamMember::query()
                ->where('user_id', $userId)
                ->whereHas('team', fn ($teams) => $teams
                    ->where('championship_id', $team->championship_id)
                    ->where('id', '<>', $team->id))
                ->whereIn('status', ['approved', 'invited', 'pending'])
                ->exists(),
            422,
            'El jugador ya pertenece a otro equipo de este campeonato.'
        );

        abort_if($team->members()->where('user_id', $userId)->whereIn('status', ['approved', 'invited', 'pending'])->exists(), 422, 'El jugador ya está en proceso de incorporación.');

        $invitation = DB::transaction(function () use ($team, $userId, $authId) {
            $member = $team->members()->where('user_id', $userId)->first();
            if ($member) {
                $member->update([
                    'invited_by_user_id' => $authId,
                    'status' => 'invited',
                    'removed_at' => null,
                ]);
            } else {
                $member = $team->members()->create([
                    'user_id' => $userId,
                    'invited_by_user_id' => $authId,
                    'status' => 'invited',
                    'role' => 'player',
                ]);
            }

            return ChampionshipTeamInvitation::create([
                'championship_id' => $team->championship_id,
                'championship_team_id' => $team->id,
                'invited_user_id' => $userId,
                'invited_by_user_id' => $authId,
                'token' => Str::random(48),
                'status' => 'pending',
            ]);
        });

        $this->notifyChampionshipUsers(
            $team->championship()->firstOrFail(),
            [$userId],
            [
                'type' => 'championship_team_invitation',
                'title' => 'Invitación a equipo',
                'body' => 'Te invitaron a ' . $team->name . '.',
                'target_type' => 'championship_team_invitation',
                'target_id' => (int) $invitation->id,
                'data_json' => [
                    'championship_team_id' => (string) $team->id,
                    'invitation_id' => (string) $invitation->id,
                ],
            ],
            $authId
        );

        return response()->json(['invitation' => $invitation], 201);
    }

    public function respondTeamInvitation(Request $request, ChampionshipTeamInvitation $invitation)
    {
        abort_unless((int) $invitation->invited_user_id === (int) $request->user()->id, 403);
        abort_if($invitation->status !== 'pending', 422, 'La invitación ya fue resuelta.');
        abort_if($invitation->expires_at && $invitation->expires_at->isPast(), 422, 'La invitación expiró.');
        $data = $request->validate(['decision' => ['required', Rule::in(['accept', 'reject'])]]);
        $accepted = $data['decision'] === 'accept';

        DB::transaction(function () use ($invitation, $accepted) {
            $invitation->update([
                'status' => $accepted ? 'accepted' : 'rejected',
                'responded_at' => now(),
            ]);
            ChampionshipTeamMember::query()
                ->where('championship_team_id', $invitation->championship_team_id)
                ->where('user_id', $invitation->invited_user_id)
                ->update([
                    'status' => $accepted ? 'approved' : 'rejected',
                    'joined_at' => $accepted ? now() : null,
                ]);
        });

        $team = $invitation->team()->first();
        if ($team) {
            $this->notifyChampionshipUsers(
                $invitation->championship()->firstOrFail(),
                array_filter([(int) $invitation->invited_by_user_id, (int) $team->captain_user_id]),
                [
                    'type' => 'championship_team_invitation_response',
                    'title' => $accepted ? 'Invitación aceptada' : 'Invitación rechazada',
                    'body' => ($invitation->invitedUser?->nick ?: 'El jugador')
                        . ($accepted ? ' se unió a ' : ' rechazó la invitación de ')
                        . $team->name . '.',
                    'target_type' => 'championship_team',
                    'target_id' => (int) $team->id,
                    'data_json' => ['championship_team_id' => (string) $team->id],
                ],
                (int) $request->user()->id
            );
        }

        return response()->json(['message' => $accepted ? 'Te uniste al equipo.' : 'Invitación rechazada.']);
    }

    public function teamMembers(Request $request, ChampionshipTeam $team)
    {
        $championship = $team->championship()->firstOrFail();
        $this->authorizeView($request, $championship);

        $items = $team->members()
            ->with('user:id,name,nick,avatar_url')
            ->whereIn('status', ['invited', 'pending', 'approved'])
            ->orderByRaw("FIELD(status, 'approved', 'pending', 'invited')")
            ->orderBy('id')
            ->get()
            ->map(fn (ChampionshipTeamMember $member) => [
                'id' => (int) $member->id,
                'user_id' => (int) $member->user_id,
                'role' => $member->role,
                'status' => $member->status,
                'joined_at' => optional($member->joined_at)->toISOString(),
                'user' => $member->user ? [
                    'id' => (int) $member->user->id,
                    'nick' => $member->user->nick,
                    'name' => $member->user->name,
                    'avatar_url' => $member->user->avatar_url,
                ] : null,
            ]);

        return response()->json(['team_id' => (int) $team->id, 'items' => $items->values()]);
    }

    public function teamInvitations(Request $request, ChampionshipTeam $team)
    {
        $championship = $team->championship()->firstOrFail();
        $this->authorizeView($request, $championship);

        $items = $team->invitations()
            ->with(['invitedUser:id,name,nick,avatar_url', 'inviter:id,name,nick'])
            ->latest('id')
            ->limit(100)
            ->get()
            ->map(fn (ChampionshipTeamInvitation $invitation) => [
                'id' => (int) $invitation->id,
                'status' => $invitation->status,
                'created_at' => optional($invitation->created_at)->toISOString(),
                'responded_at' => optional($invitation->responded_at)->toISOString(),
                'user' => $invitation->invitedUser ? [
                    'id' => (int) $invitation->invitedUser->id,
                    'nick' => $invitation->invitedUser->nick,
                    'name' => $invitation->invitedUser->name,
                    'avatar_url' => $invitation->invitedUser->avatar_url,
                ] : null,
                'invited_by' => $invitation->inviter ? [
                    'id' => (int) $invitation->inviter->id,
                    'nick' => $invitation->inviter->nick,
                    'name' => $invitation->inviter->name,
                ] : null,
            ]);

        return response()->json([
            'team_id' => (int) $team->id,
            'items' => $items->values(),
        ]);
    }

    /**
     * Invitations addressed to the authenticated player. A push is only a
     * shortcut; the invitation remains actionable after the alert is dismissed.
     */
    public function myTeamInvitations(Request $request)
    {
        $items = ChampionshipTeamInvitation::query()
            ->where('invited_user_id', $request->user()->id)
            ->where('status', 'pending')
            ->where(function ($query) {
                $query->whereNull('expires_at')->orWhere('expires_at', '>', now());
            })
            ->with([
                'championship:id,name,logo_url,status,visibility',
                'team:id,championship_id,name,color,logo_url,captain_user_id',
                'inviter:id,name,nick,avatar_url',
            ])
            ->latest('id')
            ->limit(100)
            ->get()
            ->map(fn (ChampionshipTeamInvitation $invitation) => [
                'id' => (int) $invitation->id,
                'token' => $invitation->token,
                'created_at' => optional($invitation->created_at)->toISOString(),
                'expires_at' => optional($invitation->expires_at)->toISOString(),
                'championship' => $invitation->championship ? [
                    'id' => (int) $invitation->championship->id,
                    'name' => $invitation->championship->name,
                    'logo_url' => $invitation->championship->logo_url,
                    'status' => $invitation->championship->status,
                    'visibility' => $invitation->championship->visibility,
                ] : null,
                'team' => $invitation->team ? [
                    'id' => (int) $invitation->team->id,
                    'name' => $invitation->team->name,
                    'color' => $invitation->team->color,
                    'logo_url' => $invitation->team->logo_url,
                ] : null,
                'invited_by' => $invitation->inviter ? [
                    'id' => (int) $invitation->inviter->id,
                    'nick' => $invitation->inviter->nick,
                    'name' => $invitation->inviter->name,
                    'avatar_url' => $invitation->inviter->avatar_url,
                ] : null,
            ]);

        return response()->json(['items' => $items->values()]);
    }

    /** Resolve a private team invitation share token for its recipient only. */
    public function invitationByToken(Request $request, string $token)
    {
        $invitation = ChampionshipTeamInvitation::query()
            ->where('token', $token)
            ->where('status', 'pending')
            ->where(function ($query) {
                $query->whereNull('expires_at')->orWhere('expires_at', '>', now());
            })
            ->with(['championship:id,name,logo_url', 'team:id,name,color,logo_url'])
            ->firstOrFail();

        abort_unless((int) $invitation->invited_user_id === (int) $request->user()->id, 403);

        return response()->json([
            'invitation' => [
                'id' => (int) $invitation->id,
                'championship' => $invitation->championship ? [
                    'id' => (int) $invitation->championship->id,
                    'name' => $invitation->championship->name,
                    'logo_url' => $invitation->championship->logo_url,
                ] : null,
                'team' => $invitation->team ? [
                    'id' => (int) $invitation->team->id,
                    'name' => $invitation->team->name,
                    'color' => $invitation->team->color,
                    'logo_url' => $invitation->team->logo_url,
                ] : null,
            ],
        ]);
    }

    public function removeTeamMember(Request $request, ChampionshipTeam $team, int $user)
    {
        $this->authorizeTeamRoster($request, $team);
        $member = $team->members()->where('user_id', $user)->firstOrFail();
        abort_if($member->role === 'captain', 422, 'Cambia el capitán antes de retirarlo de la plantilla.');
        $member->update(['status' => 'removed', 'removed_at' => now()]);

        return response()->json(['message' => 'Jugador retirado de la plantilla.']);
    }

    public function revokeTeamInvitation(Request $request, ChampionshipTeamInvitation $invitation)
    {
        $team = $invitation->team()->firstOrFail();
        $this->authorizeTeamRoster($request, $team);
        abort_if($invitation->status !== 'pending', 422, 'La invitación ya fue resuelta.');
        $invitation->update(['status' => 'revoked', 'responded_at' => now()]);
        $team->members()->where('user_id', $invitation->invited_user_id)->where('status', 'invited')->update([
            'status' => 'removed',
            'removed_at' => now(),
        ]);

        return response()->json(['message' => 'Invitación revocada.']);
    }

    public function setTeamCaptain(Request $request, ChampionshipTeam $team)
    {
        $championship = $team->championship()->firstOrFail();
        $this->authorizeManage($request, $championship, 'manage_teams');
        $data = $request->validate(['user_id' => ['required', 'integer', 'exists:users,id']]);
        $member = $team->members()
            ->where('user_id', (int) $data['user_id'])
            ->where('status', 'approved')
            ->first();
        abort_unless($member, 422, 'El capitán debe ser un miembro aprobado del equipo.');

        DB::transaction(function () use ($team, $member) {
            $team->members()->where('role', 'captain')->update(['role' => 'player']);
            $member->update(['role' => 'captain']);
            $team->update(['captain_user_id' => $member->user_id]);
        });

        return response()->json([
            'team' => $team->fresh('captain:id,name,nick,avatar_url'),
        ]);
    }

    public function scheduleMatchday(Request $request, ChampionshipMatchday $matchday)
    {
        $championship = $matchday->championship()->firstOrFail();
        $this->authorizeManage($request, $championship, 'manage_fixture');
        $data = $request->validate([
            'match_date' => ['required', 'date'],
            'starts_at' => ['required', 'date'],
            'ends_at' => ['required', 'date', 'after:starts_at'],
            'status' => ['sometimes', Rule::in(['draft', 'scheduled', 'in_progress', 'completed', 'cancelled'])],
        ]);
        $matchday->update([
            'match_date' => $data['match_date'],
            'starts_at' => $data['starts_at'],
            'ends_at' => $data['ends_at'],
            'status' => $data['status'] ?? 'scheduled',
        ]);
        $this->notifyChampionshipUsers(
            $championship,
            $this->championshipAudienceIds($championship),
            [
                'type' => 'championship_matchday_scheduled',
                'title' => 'Nueva fecha del campeonato',
                'body' => ($matchday->name ?: 'La jornada') . ' ya tiene horario.',
                'target_type' => 'championship_matchday',
                'target_id' => (int) $matchday->id,
                'data_json' => ['matchday_id' => (string) $matchday->id],
            ],
            (int) $request->user()->id
        );

        return response()->json(['matchday' => [
            'id' => (int) $matchday->id,
            'number' => (int) $matchday->number,
            'match_date' => $matchday->match_date?->toDateString(),
            'starts_at' => $matchday->starts_at?->toISOString(),
            'ends_at' => $matchday->ends_at?->toISOString(),
            'status' => $matchday->status,
        ]]);
    }

    public function scheduleMatch(Request $request, ChampionshipMatch $match)
    {
        $this->authorizeManage($request, $match->championship()->firstOrFail(), 'manage_fixture');
        $data = $request->validate([
            'field_id' => ['required', 'integer', 'exists:polideportivo,id'],
            'cancha_id' => ['required', 'integer', 'exists:cancha,id'],
            'starts_at' => ['required', 'date'],
            'ends_at' => ['required', 'date', 'after:starts_at'],
            'duration_minutes' => ['sometimes', 'integer', 'min:15', 'max:240'],
        ]);
        $court = Cancha::query()->findOrFail((int) $data['cancha_id']);
        abort_if((int) $court->id_polideportivo !== (int) $data['field_id'], 422, 'La cancha no pertenece al polideportivo seleccionado.');

        $field = Polideportivo::query()->findOrFail((int) $data['field_id']);
        $championship = $match->championship()->firstOrFail();
        $match->update([
            'field_id' => (int) $data['field_id'],
            'cancha_id' => (int) $data['cancha_id'],
            'starts_at' => $data['starts_at'],
            'ends_at' => $data['ends_at'],
            'duration_minutes' => (int) ($data['duration_minutes'] ?? 60),
            'status' => 'scheduled',
        ]);

        $pichanga = $this->createOrUpdateChampionshipPichanga($match, $championship, $field, $court, $request);
        $match->update(['pichanga_id' => $pichanga->id]);
        $this->notifyChampionshipUsers(
            $championship,
            $this->matchAudienceIds($match),
            [
                'type' => 'championship_match_scheduled',
                'title' => 'Partido programado',
                'body' => ($match->homeTeam?->name ?: 'Local') . ' vs ' . ($match->awayTeam?->name ?: 'Visitante') . ' ya tiene cancha y horario.',
                'target_type' => 'championship_match',
                'target_id' => (int) $match->id,
                'group_pichanga_id' => (int) $pichanga->id,
                'data_json' => ['match_id' => (string) $match->id, 'pichanga_id' => (string) $pichanga->id],
            ],
            (int) $request->user()->id
        );

        return response()->json(['match' => $this->serializeMatch($match->fresh(['homeTeam', 'awayTeam'])), 'pichanga_id' => (int) $pichanga->id]);
    }

    public function recordResult(Request $request, ChampionshipMatch $match)
    {
        $championship = $match->championship()->firstOrFail();
        $this->authorizeManage($request, $championship, 'manage_match_results');
        $data = $request->validate([
            'home_score' => ['required', 'integer', 'min:0', 'max:99'],
            'away_score' => ['required', 'integer', 'min:0', 'max:99'],
            'events' => ['nullable', 'array', 'max:100'],
            'events.*.event_type' => ['required', Rule::in(['goal', 'own_goal', 'assist', 'yellow_card', 'red_card', 'substitution_in', 'substitution_out'])],
            'events.*.player_user_id' => ['nullable', 'integer', 'exists:users,id'],
            'events.*.secondary_player_user_id' => ['nullable', 'integer', 'exists:users,id'],
            'events.*.championship_team_id' => ['nullable', 'integer', 'exists:championship_teams,id'],
            'events.*.minute' => ['nullable', 'integer', 'min:0', 'max:200'],
        ]);

        $match->loadMissing(['homeTeam', 'awayTeam']);
        abort_if(!$match->home_team_id || !$match->away_team_id, 422, 'Este partido todavía no tiene dos equipos definidos.');
        $teamIds = array_values(array_filter([
            (int) $match->home_team_id,
            (int) $match->away_team_id,
        ]));
        $memberIds = ChampionshipTeamMember::query()
            ->whereIn('championship_team_id', $teamIds)
            ->where('status', 'approved')
            ->pluck('user_id')
            ->map(fn ($id) => (int) $id)
            ->all();
        foreach ((array) ($data['events'] ?? []) as $event) {
            $eventTeamId = (int) ($event['championship_team_id'] ?? 0);
            $eventPlayerIds = array_values(array_filter([
                (int) ($event['player_user_id'] ?? 0),
                (int) ($event['secondary_player_user_id'] ?? 0),
            ]));
            abort_if($eventTeamId > 0 && !in_array($eventTeamId, $teamIds, true), 422, 'El evento no pertenece a los equipos del partido.');
            abort_if(
                collect($eventPlayerIds)->diff($memberIds)->isNotEmpty(),
                422,
                'Todos los jugadores del acta deben pertenecer a los equipos confirmados.'
            );
        }

        DB::transaction(function () use ($match, $data, $request) {
            $before = $match->only(['status', 'home_score', 'away_score']);
            $match->update([
                'home_score' => (int) $data['home_score'],
                'away_score' => (int) $data['away_score'],
                'status' => 'finished',
                'result_confirmed_by' => $request->user()->id,
                'result_confirmed_at' => now(),
            ]);
            $match->events()->delete();
            foreach ((array) ($data['events'] ?? []) as $event) {
                $match->events()->create([
                    ...$event,
                    'created_by_user_id' => $request->user()->id,
                ]);
            }
            $match->resultAudits()->create([
                'actor_user_id' => $request->user()->id,
                'action' => 'result_recorded',
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
                'title' => 'Resultado confirmado',
                'body' => ($match->homeTeam?->name ?: 'Local') . ' ' . (int) $data['home_score'] . ' - ' . (int) $data['away_score'] . ' ' . ($match->awayTeam?->name ?: 'Visitante'),
                'target_type' => 'championship_match',
                'target_id' => (int) $match->id,
                'group_pichanga_id' => $match->pichanga_id ? (int) $match->pichanga_id : null,
                'data_json' => ['match_id' => (string) $match->id],
            ],
            (int) $request->user()->id
        );

        return response()->json(['message' => 'Acta confirmada.', 'match' => $this->serializeMatch($match->fresh(['homeTeam', 'awayTeam', 'events']))]);
    }

    public function updateSquad(Request $request, ChampionshipMatch $match)
    {
        $match->loadMissing(['homeTeam', 'awayTeam', 'championship']);
        $data = $request->validate([
            'team_id' => ['required', 'integer', 'exists:championship_teams,id'],
            'players' => ['required', 'array', 'max:22'],
            'players.*.user_id' => ['required', 'integer', 'exists:users,id'],
            'players.*.status' => ['sometimes', Rule::in(['called', 'starter', 'substitute', 'played', 'withdrawn'])],
            'players.*.minutes_played' => ['sometimes', 'integer', 'min:0', 'max:240'],
        ]);
        $teamId = (int) $data['team_id'];
        abort_unless(in_array($teamId, [(int) $match->home_team_id, (int) $match->away_team_id], true), 422, 'El equipo no participa en este partido.');
        $team = $teamId === (int) $match->home_team_id ? $match->homeTeam : $match->awayTeam;
        $this->authorizeTeamRoster($request, $team);

        $playerIds = collect($data['players'])->pluck('user_id')->map(fn ($id) => (int) $id);
        abort_if($playerIds->duplicates()->isNotEmpty(), 422, 'No repitas jugadores en la convocatoria.');
        $approvedIds = $team->members()->where('status', 'approved')->pluck('user_id')->map(fn ($id) => (int) $id);
        abort_if($playerIds->diff($approvedIds)->isNotEmpty(), 422, 'Solo puedes convocar miembros aprobados del equipo.');

        DB::transaction(function () use ($match, $teamId, $data): void {
            ChampionshipMatchSquad::query()
                ->where('championship_match_id', $match->id)
                ->where('championship_team_id', $teamId)
                ->delete();
            foreach ($data['players'] as $player) {
                ChampionshipMatchSquad::create([
                    'championship_match_id' => $match->id,
                    'championship_team_id' => $teamId,
                    'user_id' => (int) $player['user_id'],
                    'status' => $player['status'] ?? 'called',
                    'minutes_played' => (int) ($player['minutes_played'] ?? 0),
                ]);
            }
        });

        return response()->json([
            'message' => 'Convocatoria guardada.',
            'match' => $this->serializeMatch($match->fresh(['homeTeam', 'awayTeam', 'squads.user', 'events'])),
        ]);
    }

    public function playerStats(Request $request, Championship $championship)
    {
        $this->authorizeView($request, $championship);
        $items = ChampionshipPlayerStat::query()
            ->where('championship_id', $championship->id)
            ->with(['user:id,name,nick,avatar_url', 'currentTeam:id,name,color'])
            ->orderByDesc('goals')
            ->orderByDesc('assists')
            ->orderByDesc('matches_played')
            ->orderBy('user_id')
            ->limit(500)
            ->get()
            ->map(fn (ChampionshipPlayerStat $stat) => [
                'user_id' => (int) $stat->user_id,
                'matches_played' => (int) $stat->matches_played,
                'minutes_played' => (int) $stat->minutes_played,
                'goals' => (int) $stat->goals,
                'assists' => (int) $stat->assists,
                'goals_conceded' => (int) $stat->goals_conceded,
                'clean_sheets' => (int) $stat->clean_sheets,
                'yellow_cards' => (int) $stat->yellow_cards,
                'red_cards' => (int) $stat->red_cards,
                'team' => $stat->currentTeam ? [
                    'id' => (int) $stat->currentTeam->id,
                    'name' => $stat->currentTeam->name,
                    'color' => $stat->currentTeam->color,
                ] : null,
                'user' => $stat->user ? [
                    'id' => (int) $stat->user->id,
                    'nick' => $stat->user->nick,
                    'name' => $stat->user->name,
                    'avatar_url' => $stat->user->avatar_url,
                ] : null,
            ]);

        return response()->json([
            'championship_id' => (int) $championship->id,
            'items' => $items->values(),
        ]);
    }

    public function fixture(Request $request, Championship $championship)
    {
        $this->authorizeView($request, $championship);
        $days = $championship->matchdays()->with(['matches.homeTeam', 'matches.awayTeam'])->get();

        return response()->json([
            'championship_id' => (int) $championship->id,
            'items' => $days->map(fn ($day) => [
                'id' => (int) $day->id,
                'number' => (int) $day->number,
                'name' => $day->name ?: 'Fecha ' . $day->number,
                'date' => optional($day->match_date)->toDateString(),
                'starts_at' => optional($day->starts_at)->toISOString(),
                'ends_at' => optional($day->ends_at)->toISOString(),
                'status' => $day->status,
                'matches' => $day->matches->map(fn ($match) => $this->serializeMatch($match)),
            ]),
        ]);
    }

    public function match(Request $request, ChampionshipMatch $match)
    {
        $this->authorizeView($request, $match->championship()->firstOrFail());
        $match->load(['championship', 'matchday', 'homeTeam', 'awayTeam', 'squads.user', 'events.player', 'events.secondaryPlayer']);

        return response()->json(['match' => $this->serializeMatch($match, true)]);
    }

    private function serializeChampionship(Championship $championship, bool $full = false, ?User $viewer = null): array
    {
        $payload = [
            'id' => (int) $championship->id,
            'name' => $championship->name,
            'slug' => $championship->slug,
            'description' => $championship->description,
            'field_id' => $championship->field_id ? (int) $championship->field_id : null,
            'venue' => $championship->relationLoaded('venue') && $championship->venue
                ? [
                    'id' => (int) $championship->venue->id,
                    'name' => $championship->venue->nombre,
                    'address' => $championship->venue->direccion,
                ]
                : null,
            'share_token' => $full && $championship->visibility === 'link'
                ? $championship->share_token
                : null,
            'logo_url' => $championship->logo_url,
            'visibility' => $championship->visibility,
            'status' => $championship->status,
            'format' => $championship->format,
            'double_round_robin' => (bool) $championship->double_round_robin,
            'points' => [
                'win' => (int) $championship->points_win,
                'draw' => (int) $championship->points_draw,
                'loss' => (int) $championship->points_loss,
            ],
            'max_teams' => (int) $championship->max_teams,
            'players_per_team' => (int) $championship->players_per_team,
            'starts_at' => optional($championship->starts_at)->toISOString(),
            'ends_at' => optional($championship->ends_at)->toISOString(),
            'teams_count' => (int) ($championship->teams_count ?? $championship->teams?->count() ?? 0),
            'groups' => $championship->relationLoaded('clubs')
                ? $championship->clubs->map(fn ($club) => [
                    'id' => (int) $club->id,
                    'name' => $club->nombre,
                    'logo_url' => $club->logo_url,
                ])->values()
                : [],
        ];

        if ($full) {
            $viewerAdmin = $viewer
                ? $championship->admins()->where('user_id', $viewer->id)->first()
                : null;
            $viewerTeam = $viewer
                ? $championship->teams()
                    ->whereHas('members', fn ($members) => $members
                        ->where('user_id', $viewer->id)
                        ->whereIn('status', ['approved', 'invited']))
                    ->first()
                : null;
            $permissions = (array) ($viewerAdmin?->permissions_json ?? []);
            if ($viewerAdmin?->role === 'owner' || $viewer?->is_superadmin) {
                $permissions = ['all' => true];
            }
            $payload['viewer'] = $viewer ? [
                'user_id' => (int) $viewer->id,
                'is_superadmin' => (bool) $viewer->is_superadmin,
                'admin_role' => $viewerAdmin?->role,
                'team_id' => $viewerTeam?->id ? (int) $viewerTeam->id : null,
                'is_captain' => $viewerTeam && (int) $viewerTeam->captain_user_id === (int) $viewer->id,
                'permissions' => $permissions,
            ] : null;
            $payload['creator'] = $championship->creator ? [
                'id' => (int) $championship->creator->id,
                'nick' => $championship->creator->nick,
                'name' => $championship->creator->name,
                'avatar_url' => $championship->creator->avatar_url,
            ] : null;
            $payload['admins'] = $championship->admins->map(fn ($admin) => [
                'user_id' => (int) $admin->user_id,
                'role' => $admin->role,
                'permissions' => $admin->permissions_json ?: [],
                'user' => $admin->user ? [
                    'nick' => $admin->user->nick,
                    'name' => $admin->user->name,
                    'avatar_url' => $admin->user->avatar_url,
                ] : null,
            ])->values();
            $payload['teams'] = $championship->teams->map(fn ($team) => [
                'id' => (int) $team->id,
                'name' => $team->name,
                'color' => $team->color,
                'logo_url' => $team->logo_url,
                'status' => $team->status,
                'members_count' => (int) $team->members->whereIn('status', ['approved', 'invited'])->count(),
                'captain' => $team->captain ? [
                    'id' => (int) $team->captain->id,
                    'nick' => $team->captain->nick,
                    'name' => $team->captain->name,
                    'avatar_url' => $team->captain->avatar_url,
                ] : null,
            ])->values();
        }

        return $payload;
    }

    private function createOrUpdateChampionshipPichanga(
        ChampionshipMatch $match,
        Championship $championship,
        Polideportivo $field,
        Cancha $court,
        Request $request
    ): GroupPichanga {
        $match->loadMissing(['homeTeam', 'awayTeam']);
        $title = sprintf(
            '%s vs %s · %s',
            $match->homeTeam?->name ?: 'Local',
            $match->awayTeam?->name ?: 'Visitante',
            $championship->name
        );
        $payload = [
            'club_id' => null,
            'created_by_user_id' => (int) $request->user()->id,
            'title' => mb_substr($title, 0, 160),
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
        $payload = array_filter($payload, fn ($value) => $value !== null);
        $columns = array_flip(Schema::getColumnListing('group_pichangas'));
        $payload = array_intersect_key($payload, $columns);

        $pichanga = $match->pichanga_id
            ? GroupPichanga::query()->find((int) $match->pichanga_id)
            : null;
        if (!$pichanga) {
            return GroupPichanga::query()->create($payload);
        }

        $pichanga->update($payload);
        return $pichanga->fresh();
    }

    private function serializeMatch(ChampionshipMatch $match, bool $full = false): array
    {
        $payload = [
            'id' => (int) $match->id,
            'matchday_id' => $match->matchday_id ? (int) $match->matchday_id : null,
            'round_number' => $match->round_number ? (int) $match->round_number : null,
            'fixture_order' => $match->fixture_order ? (int) $match->fixture_order : null,
            'phase' => $match->phase ?: 'league',
            'bracket_round' => $match->bracket_round ? (int) $match->bracket_round : null,
            'bracket_position' => $match->bracket_position ? (int) $match->bracket_position : null,
            'status' => $match->status,
            'starts_at' => optional($match->starts_at)->toISOString(),
            'ends_at' => optional($match->ends_at)->toISOString(),
            'duration_minutes' => (int) $match->duration_minutes,
            'field_id' => $match->field_id ? (int) $match->field_id : null,
            'cancha_id' => $match->cancha_id ? (int) $match->cancha_id : null,
            'pichanga_id' => $match->pichanga_id ? (int) $match->pichanga_id : null,
            'score' => [
                'home' => $match->home_score,
                'away' => $match->away_score,
            ],
            'home_team' => $match->homeTeam ? ['id' => (int) $match->homeTeam->id, 'name' => $match->homeTeam->name, 'color' => $match->homeTeam->color, 'logo_url' => $match->homeTeam->logo_url] : null,
            'away_team' => $match->awayTeam ? ['id' => (int) $match->awayTeam->id, 'name' => $match->awayTeam->name, 'color' => $match->awayTeam->color, 'logo_url' => $match->awayTeam->logo_url] : null,
        ];

        if ($full) {
            $payload['squad'] = $match->squads->map(fn ($squad) => [
                'team_id' => (int) $squad->championship_team_id,
                'user_id' => (int) $squad->user_id,
                'status' => $squad->status,
                'minutes_played' => (int) $squad->minutes_played,
                'user' => $squad->user ? ['nick' => $squad->user->nick, 'name' => $squad->user->name, 'avatar_url' => $squad->user->avatar_url] : null,
            ])->values();
            $payload['events'] = $match->events->map(fn ($event) => [
                'id' => (int) $event->id,
                'type' => $event->event_type,
                'minute' => $event->minute,
                'team_id' => $event->championship_team_id ? (int) $event->championship_team_id : null,
                'player' => $event->player ? ['id' => (int) $event->player->id, 'nick' => $event->player->nick, 'name' => $event->player->name] : null,
                'secondary_player' => $event->secondaryPlayer ? ['id' => (int) $event->secondaryPlayer->id, 'nick' => $event->secondaryPlayer->nick, 'name' => $event->secondaryPlayer->name] : null,
            ])->values();
        }

        return $payload;
    }

    private function authorizeView(Request $request, Championship $championship): void
    {
        $user = $request->user();
        $shareToken = (string) $request->query('token', '');
        if ($championship->visibility === 'public' && $championship->status !== 'draft') {
            return;
        }
        if ($championship->visibility === 'link'
            && $championship->status !== 'draft'
            && $championship->share_token
            && hash_equals((string) $championship->share_token, $shareToken)) {
            return;
        }
        abort_unless($user, 401);
        $allowed = (bool) $user->is_superadmin
            || (int) $championship->created_by_user_id === (int) $user->id
            || $championship->admins()->where('user_id', $user->id)->exists()
            || $championship->teams()->whereHas('members', fn ($members) => $members->where('user_id', $user->id))->exists();
        abort_unless($allowed, 403);
    }

    private function notifyChampionshipUsers(
        Championship $championship,
        array $userIds,
        array $payload,
        ?int $actor = null
    ): void {
        $data = array_merge((array) ($payload['data_json'] ?? []), [
            'target_type' => (string) ($payload['target_type'] ?? 'championship'),
            'target_id' => (string) ($payload['target_id'] ?? $championship->id),
            'championship_id' => (string) $championship->id,
            'image_kind' => 'championship',
        ]);

        $recipients = array_values(array_diff(
            array_unique(array_map('intval', $userIds)),
            $actor ? [(int) $actor] : []
        ));
        if (!$recipients) {
            return;
        }

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
        $clubIds = $this->associatedClubIds($championship);
        if ($clubIds) {
            foreach (Club::query()->whereIn('id', $clubIds)->get() as $club) {
                $this->clubNotifications->notifyUsers($club, $recipients, $notificationPayload, $actor);
            }
            return;
        }

        $this->push->createForUsers($recipients, $notificationPayload);
    }

    /** @return array<int> */
    private function championshipAudienceIds(Championship $championship): array
    {
        $groupMembers = ClubUser::query()
            ->whereIn('club_id', $this->associatedClubIds($championship))
            ->active()
            ->pluck('user_id')
            ->all();
        $admins = $championship->admins()->pluck('user_id')->all();
        $members = ChampionshipTeamMember::query()
            ->whereHas('team', fn ($teams) => $teams->where('championship_id', $championship->id))
            ->whereIn('status', ['approved', 'invited'])
            ->pluck('user_id')
            ->all();

        return array_values(array_unique(array_merge($groupMembers, $admins, $members)));
    }

    /** @return array<int> */
    private function associatedClubIds(Championship $championship): array
    {
        if (Schema::hasTable('championship_clubs')) {
            return $championship->clubs()->pluck('clubs.id')->map(fn ($id) => (int) $id)->all();
        }

        return $championship->club_id ? [(int) $championship->club_id] : [];
    }

    /** @return array<int> */
    private function matchAudienceIds(ChampionshipMatch $match): array
    {
        $match->loadMissing(['championship', 'homeTeam', 'awayTeam']);
        $ids = ChampionshipTeamMember::query()
            ->whereIn('championship_team_id', [$match->home_team_id, $match->away_team_id])
            ->whereIn('status', ['approved', 'invited'])
            ->pluck('user_id')
            ->all();

        return array_values(array_unique(array_merge(
            $ids,
            $match->championship ? $match->championship->admins()->pluck('user_id')->all() : []
        )));
    }

    private function authorizeManage(Request $request, Championship $championship, string $permission): void
    {
        $user = $request->user();
        $allowed = (bool) ($user && $user->is_superadmin);
        if (!$allowed && $user) {
            $admin = $championship->admins()->where('user_id', $user->id)->first();
            $allowed = (bool) ($admin && (
                $admin->role === 'owner'
                || (((array) $admin->permissions_json)[$permission] ?? false)
            ));
        }
        abort_unless($allowed, 403, 'No tienes permisos para gestionar este campeonato.');
    }

    private function authorizeTeamRoster(Request $request, ChampionshipTeam $team): void
    {
        $championship = $team->championship()->firstOrFail();
        $user = $request->user();
        $isCaptain = (int) $team->captain_user_id === (int) ($user?->id ?? 0);
        $isManager = false;
        if ($user) {
            $admin = $championship->admins()->where('user_id', $user->id)->first();
            $isManager = (bool) ($admin && (
                $admin->role === 'owner'
                || (((array) $admin->permissions_json)['manage_rosters'] ?? false)
            ));
        }
        abort_unless($user && ($user->is_superadmin || $isCaptain || $isManager), 403, 'No tienes permisos para administrar esta plantilla.');
    }
}
