<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Club;
use App\Models\ClubInvitation;
use App\Models\ClubUser;
use App\Models\User;
use App\Services\ClubNotificationService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class ClubInvitationApiController extends Controller
{
    public function __construct(private readonly ClubNotificationService $notifications)
    {
    }

    public function indexMine(Request $request)
    {
        $user = $request->user() ?? abort(401);
        $email = mb_strtolower((string) $user->email);

        $items = ClubInvitation::query()
            ->with('club:id,nombre,slug')
            ->where('status', 'pending')
            ->where(function ($q) use ($user, $email) {
                $q->where('invited_user_id', $user->id);
                if ($email !== '') {
                    $q->orWhereRaw('LOWER(invited_email) = ?', [$email]);
                }
            })
            ->latest('created_at')
            ->get()
            ->map(function (ClubInvitation $invitation) {
                return [
                    'id' => $invitation->id,
                    'club_id' => $invitation->club_id,
                    'club' => $invitation->club,
                    'invited_email' => $invitation->invited_email,
                    'status' => $invitation->status,
                    'created_at' => optional($invitation->created_at)->toISOString(),
                ];
            })->values();

        return response()->json(['items' => $items]);
    }

    public function store(Request $request, Club $club)
    {
        $auth = $request->user() ?? abort(401);
        abort_unless($this->isClubAdminOrSuper($club->id, $auth->id, (bool) $auth->is_superadmin), 403);

        $data = $request->validate([
            'nick' => ['nullable', 'string', 'min:3', 'max:20'],
            'email' => ['nullable', 'email', 'max:255'],
        ]);

        abort_if(empty($data['nick']) && empty($data['email']), 422, 'Debes enviar nick o email.');

        $target = null;
        if (!empty($data['nick'])) {
            $target = User::whereRaw('LOWER(nick) = ?', [mb_strtolower(trim((string) $data['nick']))])->first();
        }
        if (!$target && !empty($data['email'])) {
            $target = User::whereRaw('LOWER(email) = ?', [mb_strtolower(trim((string) $data['email']))])->first();
        }

        $invitedUserId = $target?->id;
        $invitedEmail = $target?->email ?? ($data['email'] ?? null);
        $invitedEmail = mb_strtolower(trim((string) $invitedEmail));
        abort_if($invitedEmail === '', 422, 'No se pudo resolver el email de invitación.');

        if ($invitedUserId) {
            $isMember = ClubUser::where('club_id', $club->id)
                ->where('user_id', $invitedUserId)
                ->active()
                ->exists();
            abort_if($isMember, 422, 'El usuario ya pertenece al grupo.');
        }

        $existsPending = ClubInvitation::query()
            ->where('club_id', $club->id)
            ->where('status', 'pending')
            ->where(function ($q) use ($invitedUserId, $invitedEmail) {
                if ($invitedUserId) {
                    $q->where('invited_user_id', $invitedUserId);
                } else {
                    $q->whereRaw('LOWER(invited_email) = ?', [$invitedEmail]);
                }
            })
            ->exists();
        abort_if($existsPending, 422, 'Ya existe una invitación pendiente para este usuario.');

        $invitation = ClubInvitation::create([
            'club_id' => $club->id,
            'invited_email' => $invitedEmail,
            'invited_user_id' => $invitedUserId,
            'invited_by_user_id' => $auth->id,
            'token' => (string) Str::uuid(),
            'status' => 'pending',
        ]);

        if ($invitedUserId) {
            $this->notifications->notifyUsers($club, [$invitedUserId], [
                'type' => 'club_invitation_created',
                'category' => 'invitations',
                'title' => 'Te invitaron a un grupo',
                'body' => "Te invitaron a unirte a {$club->nombre}.",
                'target_type' => 'club_invitation',
                'target_id' => (int) $invitation->id,
                'data_json' => ['invitation_id' => (int) $invitation->id],
            ], (int) $auth->id);
        }
        $this->notifications->audit($club, (int) $auth->id, 'club_invitation_created', $invitedUserId, ['invitation_id' => (int) $invitation->id]);

        return response()->json([
            'message' => 'Invitación enviada.',
            'invitation' => $invitation,
        ], 201);
    }

    public function respond(Request $request, ClubInvitation $invitation)
    {
        $auth = $request->user() ?? abort(401);
        $data = $request->validate([
            'action' => ['required', 'in:accept,reject'],
        ]);

        abort_unless($this->isInvitationForUser($invitation, $auth), 403, 'No puedes responder esta invitación.');
        abort_if($invitation->status !== 'pending', 422, 'La invitación ya fue procesada.');

        if ($data['action'] === 'reject') {
            $invitation->update(['status' => 'revoked']);
            $club = $invitation->club;
            if ($club) {
                $this->notifications->notifyUsers($club, [(int) $invitation->invited_by_user_id], [
                    'type' => 'club_invitation_rejected',
                    'category' => 'invitations',
                    'title' => 'Invitación rechazada',
                    'body' => "La invitación a {$club->nombre} fue rechazada.",
                    'target_type' => 'club',
                    'target_id' => (int) $club->id,
                ], (int) $auth->id);
                $this->notifications->audit($club, (int) $auth->id, 'club_invitation_rejected', (int) $invitation->invited_by_user_id, ['invitation_id' => (int) $invitation->id]);
            }
            return response()->json(['message' => 'Invitación rechazada.']);
        }

        DB::transaction(function () use ($invitation, $auth) {
            $invitation->status = 'accepted';
            $invitation->accepted_at = now();
            $invitation->invited_user_id = $auth->id;
            $invitation->save();

            ClubUser::updateOrCreate(
                ['club_id' => $invitation->club_id, 'user_id' => $auth->id],
                ['rol' => 'miembro', 'estado' => 1]
            );
        });

        $club = $invitation->club;
        if ($club) {
            $this->notifications->notifyUsers($club, [(int) $invitation->invited_by_user_id], [
                'type' => 'club_invitation_accepted',
                'category' => 'invitations',
                'title' => 'Invitación aceptada',
                'body' => "Un jugador aceptó la invitación a {$club->nombre}.",
                'target_type' => 'club',
                'target_id' => (int) $club->id,
            ], (int) $auth->id);
            $this->notifications->audit($club, (int) $auth->id, 'club_invitation_accepted', (int) $invitation->invited_by_user_id, ['invitation_id' => (int) $invitation->id]);
        }

        return response()->json(['message' => 'Invitación aceptada.']);
    }

    public function revoke(Request $request, ClubInvitation $invitation)
    {
        $auth = $request->user() ?? abort(401);
        abort_unless($this->isClubAdminOrSuper($invitation->club_id, $auth->id, (bool) $auth->is_superadmin), 403);
        abort_if($invitation->status !== 'pending', 422, 'Solo puedes revocar invitaciones pendientes.');

        $invitation->update(['status' => 'revoked']);

        return response()->json(['message' => 'Invitación revocada.']);
    }

    private function isInvitationForUser(ClubInvitation $invitation, User $user): bool
    {
        if ($invitation->invited_user_id && (int) $invitation->invited_user_id === (int) $user->id) {
            return true;
        }

        $email = mb_strtolower((string) $user->email);
        if ($email === '') {
            return false;
        }

        return mb_strtolower((string) $invitation->invited_email) === $email;
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
}
