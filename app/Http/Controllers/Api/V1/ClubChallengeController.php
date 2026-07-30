<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Club;
use App\Models\ClubChallenge;
use App\Models\ClubChallengeConfiguration;
use App\Models\ClubChallengeFieldOption;
use App\Models\ClubChallengeMessage;
use App\Models\ClubChallengeTimeOption;
use App\Models\ClubUser;
use App\Models\GroupPichanga;
use App\Models\PushNotification;
use App\Models\User;
use App\Models\UserChatPresence;
use App\Services\ChallengeNotificationService;
use App\Services\ProductEventService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Str;
use Illuminate\Validation\Rule;

class ClubChallengeController extends Controller
{
    public function __construct(
        private readonly ChallengeNotificationService $challengeNotificationService,
        private readonly ProductEventService $eventService
    ) {
    }

    public function indexMine(Request $request)
    {
        $auth = $request->user() ?? abort(401);
        abort_unless(Schema::hasTable('club_challenges'), 422, 'Ejecuta el SQL de retos para habilitar este módulo.');

        $this->expireChallengesIfNeeded();

        $status = trim((string) $request->query('status', 'active'));
        $memberClubIds = ClubUser::query()
            ->where('user_id', $auth->id)
            ->pluck('club_id')
            ->map(fn($i) => (int) $i)
            ->all();

        $query = ClubChallenge::query()
            ->where(function ($q) use ($memberClubIds) {
                $q->whereIn('challenger_club_id', $memberClubIds)
                    ->orWhereIn('challenged_club_id', $memberClubIds);
            });

        if ($status === 'active') {
            $query->whereIn('status', ['pending', 'negotiating', 'configuring']);
        } elseif ($status !== 'all') {
            $query->where('status', $status);
        }

        $items = $query
            ->with([
                'challengerClub:id,nombre,slug,is_visible',
                'challengedClub:id,nombre,slug,is_visible',
                'coordinatorChallenger:id,name,nick,avatar_url',
                'coordinatorChallenged:id,name,nick,avatar_url',
            ])
            ->orderByDesc('id')
            ->limit(200)
            ->get()
            ->map(fn(ClubChallenge $challenge) => $this->serializeChallenge($challenge, (int) $auth->id))
            ->values();

        return response()->json(['items' => $items]);
    }

    public function indexByClub(Request $request, Club $club)
    {
        $auth = $request->user() ?? abort(401);
        abort_unless(Schema::hasTable('club_challenges'), 422, 'Ejecuta el SQL de retos para habilitar este módulo.');

        $this->expireChallengesIfNeeded();

        $isMember = $this->isMember((int) $club->id, (int) $auth->id);
        $isVisible = (bool) ($club->is_visible ?? true);
        abort_unless($isMember || $isVisible || (bool) $auth->is_superadmin, 403);

        $status = trim((string) $request->query('status', 'active'));

        $query = ClubChallenge::query()
            ->where(function ($q) use ($club) {
                $q->where('challenger_club_id', (int) $club->id)
                    ->orWhere('challenged_club_id', (int) $club->id);
            });

        if ($status === 'active') {
            $query->whereIn('status', ['pending', 'negotiating', 'configuring']);
        } elseif ($status !== 'all') {
            $query->where('status', $status);
        }

        $items = $query
            ->with([
                'challengerClub:id,nombre,slug,is_visible',
                'challengedClub:id,nombre,slug,is_visible',
                'coordinatorChallenger:id,name,nick,avatar_url',
                'coordinatorChallenged:id,name,nick,avatar_url',
            ])
            ->orderByDesc('id')
            ->limit(200)
            ->get()
            ->map(fn(ClubChallenge $challenge) => $this->serializeChallenge($challenge, (int) $auth->id))
            ->values();

        return response()->json(['items' => $items]);
    }

    public function store(Request $request, Club $club)
    {
        $auth = $request->user() ?? abort(401);
        abort_unless(Schema::hasTable('club_challenges'), 422, 'Ejecuta el SQL de retos para habilitar este módulo.');
        abort_unless($this->isMember((int) $club->id, (int) $auth->id), 403, 'Debes pertenecer al grupo para retar.');

        $data = $request->validate([
            'challenged_club_id' => ['required', 'integer', 'exists:clubs,id'],
            'team_size' => ['required', 'integer', 'min:3', 'max:14'],
            'challenge_window' => ['required', Rule::in(['next_week', 'next_fortnight', 'next_month'])],
            'requested_note' => ['nullable', 'string', 'max:500'],
        ]);

        $challengedClubId = (int) $data['challenged_club_id'];
        abort_if((int) $club->id === $challengedClubId, 422, 'No puedes retar al mismo grupo.');

        $challengedClub = Club::query()->findOrFail($challengedClubId);
        abort_if(!(bool) ($challengedClub->is_visible ?? true), 422, 'Solo puedes retar grupos visibles.');

        $existing = ClubChallenge::query()
            ->whereIn('status', ['pending', 'negotiating', 'configuring'])
            ->where(function ($q) use ($club, $challengedClubId) {
                $q->where(function ($q2) use ($club, $challengedClubId) {
                    $q2->where('challenger_club_id', (int) $club->id)
                        ->where('challenged_club_id', $challengedClubId);
                })->orWhere(function ($q2) use ($club, $challengedClubId) {
                    $q2->where('challenger_club_id', $challengedClubId)
                        ->where('challenged_club_id', (int) $club->id);
                });
            })
            ->first();
        abort_if($existing !== null, 422, 'Ya existe un reto activo entre estos grupos.');

        $expiresAt = $this->windowToExpireAt((string) $data['challenge_window']);

        $challenge = ClubChallenge::query()->create([
            'challenger_club_id' => (int) $club->id,
            'challenged_club_id' => $challengedClubId,
            'created_by_user_id' => (int) $auth->id,
            'coordinator_challenger_user_id' => (int) $auth->id,
            'team_size' => (int) $data['team_size'],
            'challenge_window' => (string) $data['challenge_window'],
            'status' => 'pending',
            'requested_note' => $data['requested_note'] ?? null,
            'expires_at' => $expiresAt,
        ]);

        $systemMessage = ClubChallengeMessage::query()->create([
            'challenge_id' => (int) $challenge->id,
            'sender_user_id' => (int) $auth->id,
            'message_type' => 'system',
            'content' => sprintf(
                '%s retó a %s (%d vs %d).',
                (string) $club->nombre,
                (string) $challengedClub->nombre,
                (int) $challenge->team_size,
                (int) $challenge->team_size
            ),
            'metadata_json' => [
                'challenge_id' => (int) $challenge->id,
                'window' => (string) $challenge->challenge_window,
            ],
        ]);

        $notify = $this->challengeNotificationService->notifyMembers(
            $challenge,
            (int) $auth->id,
            [
                'club_id' => $challengedClubId,
                'type' => 'challenge_chat_message',
                'title' => 'Nuevo reto recibido',
                'body' => (string) ($challenge->requested_note ?: 'Te retaron a una pichanga.'),
                'data_json' => [
                    'challenge_id' => (int) $challenge->id,
                    'chat_message_id' => (int) $systemMessage->id,
                ],
            ],
            false
        );

        $this->eventService->track(
            'challenge_created',
            (int) $auth->id,
            (int) $club->id,
            null,
            [
                'challenge_id' => (int) $challenge->id,
                'challenged_club_id' => $challengedClubId,
                'team_size' => (int) $challenge->team_size,
                'notify_sent_count' => $notify['sent_count'],
            ]
        );

        return response()->json([
            'message' => 'Reto enviado.',
            'challenge' => $this->serializeChallenge($challenge->fresh([
                'challengerClub:id,nombre,slug,is_visible',
                'challengedClub:id,nombre,slug,is_visible',
                'coordinatorChallenger:id,name,nick,avatar_url',
                'coordinatorChallenged:id,name,nick,avatar_url',
            ]), (int) $auth->id),
        ], 201);
    }

    public function show(Request $request, ClubChallenge $challenge)
    {
        $auth = $request->user() ?? abort(401);
        abort_unless(Schema::hasTable('club_challenges'), 422, 'Ejecuta el SQL de retos para habilitar este módulo.');

        $this->expireChallengeIfNeeded($challenge);
        abort_unless($this->canAccessChallenge($challenge, (int) $auth->id, (bool) $auth->is_superadmin), 403);

        $challenge->load([
            'challengerClub:id,nombre,slug,is_visible',
            'challengedClub:id,nombre,slug,is_visible',
            'coordinatorChallenger:id,name,nick,avatar_url',
            'coordinatorChallenged:id,name,nick,avatar_url',
            'confirmedPichanga:id,club_id,rival_club_id,challenge_id,title,starts_at,status,invited_link_enabled,invited_link_code',
            'fieldOptions:id,challenge_id,proposed_by_user_id,polideportivo_id,field_name,field_address,latitude,longitude,status,created_at',
            'timeOptions:id,challenge_id,proposed_by_user_id,starts_at,duration_minutes,status,created_at',
        ]);

        return response()->json([
            'challenge' => $this->serializeChallenge($challenge, (int) $auth->id),
            'teams' => [
                'challenger_members' => $this->serializeClubMembersPublic((int) $challenge->challenger_club_id),
                'challenged_members' => $this->serializeClubMembersPublic((int) $challenge->challenged_club_id),
            ],
            'field_options' => $challenge->fieldOptions,
            'time_options' => $challenge->timeOptions,
        ]);
    }

    public function coordinate(Request $request, ClubChallenge $challenge)
    {
        $auth = $request->user() ?? abort(401);
        abort_unless(Schema::hasTable('club_challenges'), 422, 'Ejecuta el SQL de retos para habilitar este módulo.');

        $this->expireChallengeIfNeeded($challenge);
        abort_if(in_array($challenge->status, ['rejected', 'cancelled', 'expired'], true), 422, 'Este reto ya no se puede coordinar.');

        $side = $this->sideOfUser($challenge, (int) $auth->id);
        abort_unless($side !== null || (bool) $auth->is_superadmin, 403, 'Debes pertenecer a uno de los grupos del reto.');

        $updates = [];
        if ($side === 'challenger') {
            $updates['coordinator_challenger_user_id'] = (int) $auth->id;
        } elseif ($side === 'challenged') {
            $updates['coordinator_challenged_user_id'] = (int) $auth->id;
        } else {
            $updates['coordinator_challenger_user_id'] = (int) $auth->id;
        }

        $challenge->update($updates);
        $challenge->refresh();

        if ($challenge->status === 'pending' && $challenge->coordinator_challenger_user_id && $challenge->coordinator_challenged_user_id) {
            $challenge->update(['status' => 'negotiating']);
            $challenge->refresh();
        }

        $message = ClubChallengeMessage::query()->create([
            'challenge_id' => (int) $challenge->id,
            'sender_user_id' => (int) $auth->id,
            'message_type' => 'system',
            'content' => sprintf('%s está coordinando el reto.', (string) ($auth->nick ?: $auth->name)),
            'metadata_json' => ['side' => $side],
        ]);

        $notify = $this->challengeNotificationService->notifyMembers(
            $challenge,
            (int) $auth->id,
            [
                'club_id' => $side === 'challenged' ? (int) $challenge->challenger_club_id : (int) $challenge->challenged_club_id,
                'type' => 'challenge_chat_message',
                'title' => 'Reto en coordinación',
                'body' => (string) ($auth->nick ?: $auth->name) . ' está coordinando.',
                'data_json' => [
                    'challenge_id' => (int) $challenge->id,
                    'chat_message_id' => (int) $message->id,
                ],
            ],
            false
        );

        $this->eventService->track(
            'challenge_coordinator_set',
            (int) $auth->id,
            $side === 'challenged' ? (int) $challenge->challenged_club_id : (int) $challenge->challenger_club_id,
            null,
            [
                'challenge_id' => (int) $challenge->id,
                'side' => $side,
                'sent_count' => $notify['sent_count'],
            ]
        );

        return response()->json([
            'message' => 'Coordinación activada.',
            'challenge' => $this->serializeChallenge($challenge, (int) $auth->id),
        ]);
    }

    public function reject(Request $request, ClubChallenge $challenge)
    {
        $auth = $request->user() ?? abort(401);
        abort_unless(Schema::hasTable('club_challenges'), 422, 'Ejecuta el SQL de retos para habilitar este módulo.');
        $this->expireChallengeIfNeeded($challenge);

        $side = $this->sideOfUser($challenge, (int) $auth->id);
        abort_unless($side === 'challenged' || (bool) $auth->is_superadmin, 403, 'Solo el grupo retado puede rechazar.');
        abort_if(!in_array($challenge->status, ['pending', 'negotiating', 'configuring'], true), 422, 'Este reto ya fue cerrado.');

        $data = $request->validate([
            'reason' => ['nullable', 'string', 'max:255'],
        ]);

        $challenge->update([
            'status' => 'rejected',
            'rejected_by_user_id' => (int) $auth->id,
            'rejected_reason' => $data['reason'] ?? null,
        ]);

        $message = ClubChallengeMessage::query()->create([
            'challenge_id' => (int) $challenge->id,
            'sender_user_id' => (int) $auth->id,
            'message_type' => 'system',
            'content' => 'El reto fue rechazado.',
            'metadata_json' => ['reason' => $data['reason'] ?? null],
        ]);

        $this->challengeNotificationService->notifyMembers(
            $challenge,
            (int) $auth->id,
            [
                'type' => 'challenge_rejected',
                'title' => 'Reto rechazado',
                'body' => (string) ($data['reason'] ?? 'El grupo retado rechazó la propuesta.'),
                'data_json' => [
                    'challenge_id' => (int) $challenge->id,
                    'chat_message_id' => (int) $message->id,
                ],
            ],
            false
        );

        $this->eventService->track(
            'challenge_rejected',
            (int) $auth->id,
            (int) $challenge->challenged_club_id,
            null,
            ['challenge_id' => (int) $challenge->id]
        );

        return response()->json(['message' => 'Reto rechazado.']);
    }

    public function cancel(Request $request, ClubChallenge $challenge)
    {
        $auth = $request->user() ?? abort(401);
        abort_unless(Schema::hasTable('club_challenges'), 422, 'Ejecuta el SQL de retos para habilitar este módulo.');
        $this->expireChallengeIfNeeded($challenge);

        $side = $this->sideOfUser($challenge, (int) $auth->id);
        abort_unless($side === 'challenger' || (bool) $auth->is_superadmin, 403, 'Solo el grupo que retó puede cancelar.');
        abort_if(!in_array($challenge->status, ['pending', 'negotiating', 'configuring'], true), 422, 'Este reto ya fue cerrado.');

        $data = $request->validate([
            'reason' => ['nullable', 'string', 'max:255'],
        ]);

        $challenge->update([
            'status' => 'cancelled',
            'cancelled_by_user_id' => (int) $auth->id,
            'cancelled_reason' => $data['reason'] ?? null,
        ]);

        $message = ClubChallengeMessage::query()->create([
            'challenge_id' => (int) $challenge->id,
            'sender_user_id' => (int) $auth->id,
            'message_type' => 'system',
            'content' => 'El reto fue cancelado.',
            'metadata_json' => ['reason' => $data['reason'] ?? null],
        ]);

        $this->challengeNotificationService->notifyMembers(
            $challenge,
            (int) $auth->id,
            [
                'type' => 'challenge_cancelled',
                'title' => 'Reto cancelado',
                'body' => (string) ($data['reason'] ?? 'El reto fue cancelado por el grupo retador.'),
                'data_json' => [
                    'challenge_id' => (int) $challenge->id,
                    'chat_message_id' => (int) $message->id,
                ],
            ],
            false
        );

        $this->eventService->track(
            'challenge_cancelled',
            (int) $auth->id,
            (int) $challenge->challenger_club_id,
            null,
            ['challenge_id' => (int) $challenge->id]
        );

        return response()->json(['message' => 'Reto cancelado.']);
    }

    public function messages(Request $request, ClubChallenge $challenge)
    {
        $auth = $request->user() ?? abort(401);
        abort_unless(Schema::hasTable('club_challenge_messages'), 422, 'Ejecuta el SQL de retos para habilitar este módulo.');
        $this->expireChallengeIfNeeded($challenge);
        abort_unless($this->canAccessChallenge($challenge, (int) $auth->id, (bool) $auth->is_superadmin), 403);

        $limit = max(20, min(300, (int) $request->query('limit', 120)));
        $items = ClubChallengeMessage::query()
            ->where('challenge_id', (int) $challenge->id)
            ->with('sender:id,name,nick,avatar_url')
            ->orderByDesc('id')
            ->limit($limit)
            ->get()
            ->reverse()
            ->values()
            ->map(fn(ClubChallengeMessage $row) => $this->serializeMessage($row));

        $this->markChallengeNotificationsRead((int) $auth->id, (int) $challenge->id);

        return response()->json([
            'items' => $items,
            'challenge_id' => (int) $challenge->id,
        ]);
    }

    public function sendMessage(Request $request, ClubChallenge $challenge)
    {
        $auth = $request->user() ?? abort(401);
        abort_unless(Schema::hasTable('club_challenge_messages'), 422, 'Ejecuta el SQL de retos para habilitar este módulo.');
        $this->expireChallengeIfNeeded($challenge);
        abort_unless($this->canAccessChallenge($challenge, (int) $auth->id, (bool) $auth->is_superadmin), 403);
        abort_if(in_array($challenge->status, ['rejected', 'cancelled', 'expired'], true), 422, 'Este reto ya fue cerrado.');

        $data = $request->validate([
            'content' => ['required', 'string', 'min:1', 'max:1200'],
        ]);

        $message = ClubChallengeMessage::query()->create([
            'challenge_id' => (int) $challenge->id,
            'sender_user_id' => (int) $auth->id,
            'message_type' => 'text',
            'content' => trim((string) $data['content']),
        ]);

        if ($challenge->status === 'pending') {
            $challenge->update(['status' => 'negotiating']);
        }

        $notify = $this->challengeNotificationService->notifyMembers(
            $challenge,
            (int) $auth->id,
            [
                'type' => 'challenge_chat_message',
                'title' => 'Nuevo mensaje del reto',
                'body' => Str::limit((string) $message->content, 120),
                'data_json' => [
                    'challenge_id' => (int) $challenge->id,
                    'chat_message_id' => (int) $message->id,
                ],
            ],
            true
        );

        $this->eventService->track(
            'challenge_chat_message',
            (int) $auth->id,
            $this->sideOfUser($challenge, (int) $auth->id) === 'challenged'
                ? (int) $challenge->challenged_club_id
                : (int) $challenge->challenger_club_id,
            null,
            [
                'challenge_id' => (int) $challenge->id,
                'message_id' => (int) $message->id,
                'sent_count' => (int) $notify['sent_count'],
                'active_chat_skipped_count' => (int) $notify['active_chat_skipped_count'],
            ]
        );

        return response()->json([
            'message' => 'Mensaje enviado.',
            'item' => $this->serializeMessage($message->load('sender:id,name,nick,avatar_url')),
            'dispatch' => $notify,
        ], 201);
    }

    public function proposeFieldOption(Request $request, ClubChallenge $challenge)
    {
        $auth = $request->user() ?? abort(401);
        abort_unless(Schema::hasTable('club_challenge_field_options'), 422, 'Ejecuta el SQL de retos para habilitar este módulo.');
        $this->expireChallengeIfNeeded($challenge);
        abort_unless($this->canAccessChallenge($challenge, (int) $auth->id, (bool) $auth->is_superadmin), 403);

        $data = $request->validate([
            'polideportivo_id' => ['nullable', 'integer'],
            'field_name' => ['nullable', 'string', 'max:255'],
            'field_address' => ['nullable', 'string', 'max:255'],
            'latitude' => ['nullable', 'numeric', 'between:-90,90'],
            'longitude' => ['nullable', 'numeric', 'between:-180,180'],
        ]);

        abort_if(
            empty($data['polideportivo_id']) && empty($data['field_name']),
            422,
            'Debes indicar al menos una cancha o nombre de cancha.'
        );

        $option = ClubChallengeFieldOption::query()->create([
            'challenge_id' => (int) $challenge->id,
            'proposed_by_user_id' => (int) $auth->id,
            'polideportivo_id' => $data['polideportivo_id'] ?? null,
            'field_name' => $data['field_name'] ?? null,
            'field_address' => $data['field_address'] ?? null,
            'latitude' => $data['latitude'] ?? null,
            'longitude' => $data['longitude'] ?? null,
            'status' => 'proposed',
        ]);

        ClubChallengeMessage::query()->create([
            'challenge_id' => (int) $challenge->id,
            'sender_user_id' => (int) $auth->id,
            'message_type' => 'system',
            'content' => 'Se propuso una cancha para el reto.',
            'metadata_json' => [
                'field_option_id' => (int) $option->id,
            ],
        ]);

        return response()->json([
            'message' => 'Cancha propuesta.',
            'item' => $option,
        ], 201);
    }

    public function proposeTimeOption(Request $request, ClubChallenge $challenge)
    {
        $auth = $request->user() ?? abort(401);
        abort_unless(Schema::hasTable('club_challenge_time_options'), 422, 'Ejecuta el SQL de retos para habilitar este módulo.');
        $this->expireChallengeIfNeeded($challenge);
        abort_unless($this->canAccessChallenge($challenge, (int) $auth->id, (bool) $auth->is_superadmin), 403);

        $data = $request->validate([
            'starts_at' => ['required', 'date'],
            'duration_minutes' => ['nullable', 'integer', 'min:30', 'max:240'],
        ]);

        $option = ClubChallengeTimeOption::query()->create([
            'challenge_id' => (int) $challenge->id,
            'proposed_by_user_id' => (int) $auth->id,
            'starts_at' => $data['starts_at'],
            'duration_minutes' => (int) ($data['duration_minutes'] ?? 90),
            'status' => 'proposed',
        ]);

        ClubChallengeMessage::query()->create([
            'challenge_id' => (int) $challenge->id,
            'sender_user_id' => (int) $auth->id,
            'message_type' => 'system',
            'content' => 'Se propuso fecha/hora para el reto.',
            'metadata_json' => [
                'time_option_id' => (int) $option->id,
            ],
        ]);

        return response()->json([
            'message' => 'Fecha/hora propuesta.',
            'item' => $option,
        ], 201);
    }

    public function listConfigurations(Request $request, ClubChallenge $challenge)
    {
        $auth = $request->user() ?? abort(401);
        abort_unless(Schema::hasTable('club_challenge_configurations'), 422, 'Ejecuta el SQL de retos para habilitar este módulo.');
        $this->expireChallengeIfNeeded($challenge);
        abort_unless($this->canAccessChallenge($challenge, (int) $auth->id, (bool) $auth->is_superadmin), 403);

        $items = ClubChallengeConfiguration::query()
            ->where('challenge_id', (int) $challenge->id)
            ->with([
                'proposedBy:id,name,nick,avatar_url',
                'fieldOption:id,challenge_id,field_name,field_address,latitude,longitude,polideportivo_id,status',
                'timeOption:id,challenge_id,starts_at,duration_minutes,status',
            ])
            ->orderByDesc('id')
            ->limit(100)
            ->get()
            ->map(fn(ClubChallengeConfiguration $row) => $this->serializeConfiguration($row))
            ->values();

        return response()->json(['items' => $items]);
    }

    public function proposeConfiguration(Request $request, ClubChallenge $challenge)
    {
        $auth = $request->user() ?? abort(401);
        abort_unless(Schema::hasTable('club_challenge_configurations'), 422, 'Ejecuta el SQL de retos para habilitar este módulo.');
        $this->expireChallengeIfNeeded($challenge);
        abort_unless($this->canAccessChallenge($challenge, (int) $auth->id, (bool) $auth->is_superadmin), 403);
        abort_if(in_array($challenge->status, ['rejected', 'cancelled', 'expired'], true), 422, 'Este reto ya fue cerrado.');

        $messageCount = ClubChallengeMessage::query()
            ->where('challenge_id', (int) $challenge->id)
            ->where('message_type', 'text')
            ->count();
        abort_if($messageCount < 5, 422, 'Primero coordinen en el chat (mínimo 5 mensajes).');

        $data = $request->validate([
            'field_option_id' => ['required', 'integer'],
            'time_option_id' => ['required', 'integer'],
            'invited_link_enabled' => ['nullable', 'boolean'],
        ]);

        $fieldOption = ClubChallengeFieldOption::query()
            ->where('challenge_id', (int) $challenge->id)
            ->where('id', (int) $data['field_option_id'])
            ->first();
        abort_unless($fieldOption, 422, 'La cancha propuesta no corresponde a este reto.');

        $timeOption = ClubChallengeTimeOption::query()
            ->where('challenge_id', (int) $challenge->id)
            ->where('id', (int) $data['time_option_id'])
            ->first();
        abort_unless($timeOption, 422, 'La fecha/hora propuesta no corresponde a este reto.');

        $configuration = ClubChallengeConfiguration::query()->create([
            'challenge_id' => (int) $challenge->id,
            'proposed_by_user_id' => (int) $auth->id,
            'field_option_id' => (int) $fieldOption->id,
            'time_option_id' => (int) $timeOption->id,
            'status' => 'pending',
        ]);

        $challenge->update(['status' => 'configuring']);

        $message = ClubChallengeMessage::query()->create([
            'challenge_id' => (int) $challenge->id,
            'sender_user_id' => (int) $auth->id,
            'message_type' => 'system',
            'content' => 'Se propuso configuración de pichanga.',
            'metadata_json' => [
                'configuration_id' => (int) $configuration->id,
                'field_option_id' => (int) $fieldOption->id,
                'time_option_id' => (int) $timeOption->id,
                'invited_link_enabled' => (bool) ($data['invited_link_enabled'] ?? false),
            ],
        ]);

        $notify = $this->challengeNotificationService->notifyMembers(
            $challenge,
            (int) $auth->id,
            [
                'type' => 'challenge_configuration_proposed',
                'title' => 'Configuración propuesta',
                'body' => 'Revisa y responde la propuesta del reto.',
                'data_json' => [
                    'challenge_id' => (int) $challenge->id,
                    'configuration_id' => (int) $configuration->id,
                    'chat_message_id' => (int) $message->id,
                    'invited_link_enabled' => (bool) ($data['invited_link_enabled'] ?? false),
                ],
            ],
            false
        );

        return response()->json([
            'message' => 'Configuración propuesta.',
            'item' => $this->serializeConfiguration($configuration->load([
                'proposedBy:id,name,nick,avatar_url',
                'fieldOption:id,challenge_id,field_name,field_address,latitude,longitude,polideportivo_id,status',
                'timeOption:id,challenge_id,starts_at,duration_minutes,status',
            ])),
            'dispatch' => $notify,
        ], 201);
    }

    public function decideConfiguration(Request $request, ClubChallenge $challenge, ClubChallengeConfiguration $configuration)
    {
        $auth = $request->user() ?? abort(401);
        abort_unless(Schema::hasTable('club_challenge_configurations'), 422, 'Ejecuta el SQL de retos para habilitar este módulo.');
        abort_unless((int) $configuration->challenge_id === (int) $challenge->id, 404);
        $this->expireChallengeIfNeeded($challenge);
        abort_if($configuration->status !== 'pending', 422, 'La configuración ya fue resuelta.');

        $side = $this->sideOfUser($challenge, (int) $auth->id);
        abort_unless($side !== null || (bool) $auth->is_superadmin, 403);

        if (!(bool) $auth->is_superadmin) {
            if ($side === 'challenger') {
                abort_unless((int) $challenge->coordinator_challenger_user_id === (int) $auth->id, 403, 'Solo el coordinador de tu grupo puede responder.');
            }
            if ($side === 'challenged') {
                abort_unless((int) $challenge->coordinator_challenged_user_id === (int) $auth->id, 403, 'Solo el coordinador de tu grupo puede responder.');
            }
        }

        $data = $request->validate([
            'action' => ['required', Rule::in(['accept', 'reject'])],
            'reason' => ['nullable', 'string', 'max:255'],
            'invited_link_enabled' => ['nullable', 'boolean'],
        ]);

        if ($data['action'] === 'reject') {
            $configuration->update([
                'status' => 'rejected',
                'rejected_by_user_id' => (int) $auth->id,
                'rejected_reason' => $data['reason'] ?? null,
            ]);
            $challenge->update(['status' => 'negotiating']);

            $message = ClubChallengeMessage::query()->create([
                'challenge_id' => (int) $challenge->id,
                'sender_user_id' => (int) $auth->id,
                'message_type' => 'system',
                'content' => 'Configuración rechazada.',
                'metadata_json' => [
                    'configuration_id' => (int) $configuration->id,
                    'reason' => $data['reason'] ?? null,
                ],
            ]);

            $this->challengeNotificationService->notifyMembers(
                $challenge,
                (int) $auth->id,
                [
                    'type' => 'challenge_configuration_rejected',
                    'title' => 'Configuración rechazada',
                    'body' => (string) ($data['reason'] ?? 'Se rechazó la propuesta de configuración.'),
                    'data_json' => [
                        'challenge_id' => (int) $challenge->id,
                        'configuration_id' => (int) $configuration->id,
                        'chat_message_id' => (int) $message->id,
                    ],
                ],
                false
            );

            return response()->json(['message' => 'Configuración rechazada.']);
        }

        $updates = [];
        if ($side === 'challenger' || (bool) $auth->is_superadmin) {
            $updates['accepted_by_challenger_at'] = now();
        }
        if ($side === 'challenged' || (bool) $auth->is_superadmin) {
            $updates['accepted_by_challenged_at'] = now();
        }
        $configuration->update($updates);
        $configuration->refresh();

        $bothAccepted = !empty($configuration->accepted_by_challenger_at) && !empty($configuration->accepted_by_challenged_at);
        if (!$bothAccepted) {
            $message = ClubChallengeMessage::query()->create([
                'challenge_id' => (int) $challenge->id,
                'sender_user_id' => (int) $auth->id,
                'message_type' => 'system',
                'content' => 'Configuración aceptada por un grupo. Falta la otra confirmación.',
                'metadata_json' => ['configuration_id' => (int) $configuration->id],
            ]);

            $this->challengeNotificationService->notifyMembers(
                $challenge,
                (int) $auth->id,
                [
                    'type' => 'challenge_configuration_accepted',
                    'title' => 'Configuración aceptada parcialmente',
                    'body' => 'Una parte aceptó. Falta la confirmación final.',
                    'data_json' => [
                        'challenge_id' => (int) $challenge->id,
                        'configuration_id' => (int) $configuration->id,
                        'chat_message_id' => (int) $message->id,
                    ],
                ],
                false
            );

            return response()->json([
                'message' => 'Aceptado por tu grupo. Falta la confirmación del otro grupo.',
                'item' => $this->serializeConfiguration($configuration->load([
                    'proposedBy:id,name,nick,avatar_url',
                    'fieldOption:id,challenge_id,field_name,field_address,latitude,longitude,polideportivo_id,status',
                    'timeOption:id,challenge_id,starts_at,duration_minutes,status',
                ])),
            ]);
        }

        DB::transaction(function () use ($challenge, $configuration, $auth, $data) {
            $configuration->update(['status' => 'accepted']);

            ClubChallengeFieldOption::query()
                ->where('challenge_id', (int) $challenge->id)
                ->where('id', '!=', (int) $configuration->field_option_id)
                ->where('status', 'proposed')
                ->update(['status' => 'rejected']);
            ClubChallengeFieldOption::query()
                ->where('id', (int) $configuration->field_option_id)
                ->update(['status' => 'accepted']);

            ClubChallengeTimeOption::query()
                ->where('challenge_id', (int) $challenge->id)
                ->where('id', '!=', (int) $configuration->time_option_id)
                ->where('status', 'proposed')
                ->update(['status' => 'rejected']);
            ClubChallengeTimeOption::query()
                ->where('id', (int) $configuration->time_option_id)
                ->update(['status' => 'accepted']);

            $fieldOption = ClubChallengeFieldOption::query()->findOrFail((int) $configuration->field_option_id);
            $timeOption = ClubChallengeTimeOption::query()->findOrFail((int) $configuration->time_option_id);

            $pichangaPayload = [
                'club_id' => (int) $challenge->challenger_club_id,
                'rival_club_id' => (int) $challenge->challenged_club_id,
                'challenge_id' => (int) $challenge->id,
                'match_context' => 'club_challenge',
                'created_by_user_id' => (int) $auth->id,
                'title' => sprintf(
                    'Reto %d vs %d',
                    (int) $challenge->challenger_club_id,
                    (int) $challenge->challenged_club_id
                ),
                'description' => (string) ($challenge->requested_note ?: 'Pichanga por reto entre grupos.'),
                'field_id' => $fieldOption->polideportivo_id,
                'address' => $fieldOption->field_address ?: $fieldOption->field_name,
                'starts_at' => $timeOption->starts_at,
                'duration_minutes' => (int) $timeOption->duration_minutes,
                'capacity' => (int) $challenge->team_size * 2,
                'status' => 'published',
                'confirmation_mode' => 'auto_by_capacity',
                'is_open' => false,
                'notify_degree' => 1,
                'allow_external_requests' => false,
                'invited_link_enabled' => (bool) ($data['invited_link_enabled'] ?? false),
                'invited_link_code' => (bool) ($data['invited_link_enabled'] ?? false)
                    ? strtoupper(Str::random(16))
                    : null,
            ];

            $pichanga = GroupPichanga::query()->create($this->filterPayloadByTableColumns('group_pichangas', $pichangaPayload));

            $challenge->update([
                'status' => 'confirmed',
                'confirmed_at' => now(),
                'confirmed_pichanga_id' => (int) $pichanga->id,
            ]);
        });

        $challenge->refresh();

        $message = ClubChallengeMessage::query()->create([
            'challenge_id' => (int) $challenge->id,
            'sender_user_id' => (int) $auth->id,
            'message_type' => 'system',
            'content' => 'Reto confirmado. Se creó una pichanga compartida.',
            'metadata_json' => [
                'configuration_id' => (int) $configuration->id,
                'pichanga_id' => (int) $challenge->confirmed_pichanga_id,
            ],
        ]);

        $notify = $this->challengeNotificationService->notifyMembers(
            $challenge,
            (int) $auth->id,
            [
                'group_pichanga_id' => (int) $challenge->confirmed_pichanga_id,
                'type' => 'challenge_confirmed',
                'title' => 'Reto confirmado',
                'body' => 'La pichanga quedó confirmada. Revisa fecha, hora y cancha.',
                'data_json' => [
                    'challenge_id' => (int) $challenge->id,
                    'pichanga_id' => (int) $challenge->confirmed_pichanga_id,
                    'chat_message_id' => (int) $message->id,
                ],
            ],
            false
        );

        $this->eventService->track(
            'challenge_confirmed',
            (int) $auth->id,
            (int) $challenge->challenger_club_id,
            (int) $challenge->confirmed_pichanga_id,
            [
                'challenge_id' => (int) $challenge->id,
                'configuration_id' => (int) $configuration->id,
                'sent_count' => (int) $notify['sent_count'],
            ]
        );

        return response()->json([
            'message' => 'Reto confirmado y pichanga creada.',
            'challenge' => $this->serializeChallenge($challenge->fresh([
                'challengerClub:id,nombre,slug,is_visible',
                'challengedClub:id,nombre,slug,is_visible',
                'coordinatorChallenger:id,name,nick,avatar_url',
                'coordinatorChallenged:id,name,nick,avatar_url',
                'confirmedPichanga:id,club_id,rival_club_id,challenge_id,title,starts_at,status,invited_link_enabled,invited_link_code',
            ]), (int) $auth->id),
        ]);
    }

    public function updateChatPresence(Request $request)
    {
        $auth = $request->user() ?? abort(401);
        abort_unless(Schema::hasTable('user_chat_presence'), 422, 'Ejecuta el SQL de retos para habilitar presencia de chat.');

        $data = $request->validate([
            'challenge_id' => ['nullable', 'integer'],
            'is_active' => ['required', 'boolean'],
            'updated_at_client' => ['nullable', 'date'],
        ]);

        $challengeId = !empty($data['challenge_id']) ? (int) $data['challenge_id'] : null;
        if ((bool) $data['is_active']) {
            abort_if($challengeId === null, 422, 'Debes indicar challenge_id cuando is_active=true.');
            $challenge = ClubChallenge::query()->find($challengeId);
            abort_unless($challenge, 404, 'Reto no encontrado.');
            abort_unless($this->canAccessChallenge($challenge, (int) $auth->id, (bool) $auth->is_superadmin), 403);
        }

        $presence = UserChatPresence::query()->updateOrCreate(
            ['user_id' => (int) $auth->id],
            [
                'challenge_id' => (bool) $data['is_active'] ? $challengeId : null,
                'is_active' => (bool) $data['is_active'],
                'last_heartbeat_at' => now(),
            ]
        );

        return response()->json([
            'message' => 'Presencia actualizada.',
            'presence' => [
                'challenge_id' => $presence->challenge_id,
                'is_active' => (bool) $presence->is_active,
                'last_heartbeat_at' => optional($presence->last_heartbeat_at)->toISOString(),
            ],
        ]);
    }

    private function canAccessChallenge(ClubChallenge $challenge, int $userId, bool $isSuper): bool
    {
        if ($isSuper) {
            return true;
        }

        return $this->sideOfUser($challenge, $userId) !== null;
    }

    private function sideOfUser(ClubChallenge $challenge, int $userId): ?string
    {
        if ($this->isMember((int) $challenge->challenger_club_id, $userId)) {
            return 'challenger';
        }
        if ($this->isMember((int) $challenge->challenged_club_id, $userId)) {
            return 'challenged';
        }

        return null;
    }

    private function isMember(int $clubId, int $userId): bool
    {
        return ClubUser::query()
            ->where('club_id', $clubId)
            ->where('user_id', $userId)
            ->exists();
    }

    private function windowToExpireAt(string $window): \Carbon\CarbonInterface
    {
        $base = now();
        return match ($window) {
            'next_week' => $base->copy()->addWeek(),
            'next_fortnight' => $base->copy()->addDays(15),
            'next_month' => $base->copy()->addMonth(),
            default => $base->copy()->addWeek(),
        };
    }

    private function expireChallengesIfNeeded(): void
    {
        $expiredIds = ClubChallenge::query()
            ->whereIn('status', ['pending', 'negotiating', 'configuring'])
            ->where('expires_at', '<', now())
            ->pluck('id')
            ->map(fn($i) => (int) $i)
            ->all();

        if (empty($expiredIds)) {
            return;
        }

        $rows = ClubChallenge::query()->whereIn('id', $expiredIds)->get();
        foreach ($rows as $row) {
            $this->expireChallengeIfNeeded($row);
        }
    }

    private function expireChallengeIfNeeded(ClubChallenge $challenge): void
    {
        if (!in_array($challenge->status, ['pending', 'negotiating', 'configuring'], true)) {
            return;
        }
        if (now()->lt($challenge->expires_at)) {
            return;
        }

        $challenge->update(['status' => 'expired']);

        $message = ClubChallengeMessage::query()->create([
            'challenge_id' => (int) $challenge->id,
            'sender_user_id' => (int) $challenge->created_by_user_id,
            'message_type' => 'system',
            'content' => 'El reto expiró por tiempo.',
            'metadata_json' => ['expired' => true],
        ]);

        $this->challengeNotificationService->notifyMembers(
            $challenge,
            0,
            [
                'type' => 'challenge_expired',
                'title' => 'Reto expirado',
                'body' => 'El reto expiró por falta de confirmación.',
                'data_json' => [
                    'challenge_id' => (int) $challenge->id,
                    'chat_message_id' => (int) $message->id,
                ],
            ],
            false
        );
    }

    private function serializeClubMembersPublic(int $clubId): array
    {
        $rows = ClubUser::query()
            ->where('club_id', $clubId)
            ->with('user:id,name,nick,sexo,fec_nac,avatar_url')
            ->orderByRaw("CASE WHEN rol = 'admin' THEN 0 ELSE 1 END")
            ->orderBy('id')
            ->get();

        $userIds = $rows->pluck('user_id')->map(fn($i) => (int) $i)->all();
        $counts = [];
        if (!empty($userIds) && Schema::hasTable('group_pichanga_participants')) {
            $counts = DB::table('group_pichanga_participants')
                ->selectRaw('user_id, COUNT(*) as total')
                ->whereIn('user_id', $userIds)
                ->where('status', 'confirmed')
                ->groupBy('user_id')
                ->pluck('total', 'user_id')
                ->map(fn($v) => (int) $v)
                ->all();
        }

        return $rows->map(function (ClubUser $member) use ($counts) {
            $user = $member->user;
            return [
                'user_id' => (int) $member->user_id,
                'rol' => (string) $member->rol,
                'joined_at' => optional($member->joined_at)->toISOString(),
                'user' => [
                    'id' => $user?->id,
                    'name' => $user?->name,
                    'nick' => $user?->nick,
                    'sexo' => $user?->sexo,
                    'fec_nac' => optional($user?->fec_nac)->toDateString(),
                    'avatar_url' => $user?->avatar_url,
                    'pichangas_confirmadas' => (int) ($counts[(int) $member->user_id] ?? 0),
                ],
            ];
        })->values()->all();
    }

    /**
     * @return array<string,mixed>
     */
    private function serializeChallenge(ClubChallenge $challenge, int $viewerUserId): array
    {
        $side = $this->sideOfUser($challenge, $viewerUserId);

        return [
            'id' => (int) $challenge->id,
            'challenger_club_id' => (int) $challenge->challenger_club_id,
            'challenged_club_id' => (int) $challenge->challenged_club_id,
            'created_by_user_id' => (int) $challenge->created_by_user_id,
            'team_size' => (int) $challenge->team_size,
            'challenge_window' => (string) $challenge->challenge_window,
            'status' => (string) $challenge->status,
            'requested_note' => $challenge->requested_note,
            'expires_at' => optional($challenge->expires_at)->toISOString(),
            'confirmed_at' => optional($challenge->confirmed_at)->toISOString(),
            'confirmed_pichanga_id' => $challenge->confirmed_pichanga_id ? (int) $challenge->confirmed_pichanga_id : null,
            'my_side' => $side,
            'my_is_coordinator' => $side === 'challenger'
                ? (int) $challenge->coordinator_challenger_user_id === $viewerUserId
                : ($side === 'challenged'
                    ? (int) $challenge->coordinator_challenged_user_id === $viewerUserId
                    : false),
            'challenger_club' => $challenge->challengerClub,
            'challenged_club' => $challenge->challengedClub,
            'coordinator_challenger' => $challenge->coordinatorChallenger,
            'coordinator_challenged' => $challenge->coordinatorChallenged,
            'confirmed_pichanga' => $challenge->confirmedPichanga,
        ];
    }

    /**
     * @return array<string,mixed>
     */
    private function serializeMessage(ClubChallengeMessage $message): array
    {
        return [
            'id' => (int) $message->id,
            'challenge_id' => (int) $message->challenge_id,
            'sender_user_id' => (int) $message->sender_user_id,
            'message_type' => (string) $message->message_type,
            'content' => (string) $message->content,
            'metadata_json' => $message->metadata_json,
            'created_at' => optional($message->created_at)->toISOString(),
            'sender' => $message->sender,
        ];
    }

    /**
     * @return array<string,mixed>
     */
    private function serializeConfiguration(ClubChallengeConfiguration $configuration): array
    {
        return [
            'id' => (int) $configuration->id,
            'challenge_id' => (int) $configuration->challenge_id,
            'proposed_by_user_id' => (int) $configuration->proposed_by_user_id,
            'field_option_id' => (int) $configuration->field_option_id,
            'time_option_id' => (int) $configuration->time_option_id,
            'status' => (string) $configuration->status,
            'accepted_by_challenger_at' => optional($configuration->accepted_by_challenger_at)->toISOString(),
            'accepted_by_challenged_at' => optional($configuration->accepted_by_challenged_at)->toISOString(),
            'rejected_reason' => $configuration->rejected_reason,
            'created_at' => optional($configuration->created_at)->toISOString(),
            'proposed_by' => $configuration->proposedBy,
            'field_option' => $configuration->fieldOption,
            'time_option' => $configuration->timeOption,
        ];
    }

    private function markChallengeNotificationsRead(int $userId, int $challengeId): void
    {
        $items = PushNotification::query()
            ->where('user_id', $userId)
            ->where('is_read', false)
            ->where(function ($q) {
                $q->where('type', 'challenge_chat_message')
                    ->orWhere('type', 'challenge_configuration_proposed')
                    ->orWhere('type', 'challenge_configuration_accepted')
                    ->orWhere('type', 'challenge_configuration_rejected')
                    ->orWhere('type', 'challenge_confirmed')
                    ->orWhere('type', 'challenge_cancelled')
                    ->orWhere('type', 'challenge_expired')
                    ->orWhere('type', 'challenge_rejected');
            })
            ->get(['id', 'data_json']);

        $toReadIds = $items
            ->filter(function (PushNotification $item) use ($challengeId) {
                $data = is_array($item->data_json) ? $item->data_json : [];
                return (int) ($data['challenge_id'] ?? 0) === $challengeId;
            })
            ->pluck('id')
            ->map(fn($i) => (int) $i)
            ->values()
            ->all();

        if (empty($toReadIds)) {
            return;
        }

        PushNotification::query()
            ->whereIn('id', $toReadIds)
            ->update([
                'is_read' => true,
                'read_at' => now(),
            ]);
    }

    private function filterPayloadByTableColumns(string $table, array $payload): array
    {
        return collect($payload)
            ->filter(fn($_, $key) => Schema::hasColumn($table, (string) $key))
            ->all();
    }
}
