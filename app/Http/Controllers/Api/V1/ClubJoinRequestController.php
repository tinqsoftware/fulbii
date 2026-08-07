<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Club;
use App\Models\ClubJoinRequest;
use App\Models\ClubUser;
use App\Services\ProductEventService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Str;
use Illuminate\Validation\Rule;

class ClubJoinRequestController extends Controller
{
    public function __construct(private readonly ProductEventService $eventService)
    {
    }

    public function previewByCode(Request $request, string $joinCode)
    {
        $auth = $request->user() ?? abort(401);
        $club = $this->resolveClubByJoinCode($joinCode);

        abort_if(!$this->isClubActive($club), 404, 'El grupo no acepta solicitudes de ingreso.');

        abort_unless(
            (bool) ($club->is_visible ?? true) && (bool) ($club->link_join_enabled ?? true),
            404,
            'El grupo no acepta solicitudes de ingreso.'
        );

        $isMember = $this->isMember((int) $club->id, (int) $auth->id);
        $pending = $this->pendingRequest($club, (int) $auth->id);

        return response()->json([
            'club' => [
                'id' => $club->id,
                'nombre' => $club->nombre,
                'slug' => $club->slug,
                'descripcion' => $club->descripcion,
                'is_visible' => (bool) ($club->is_visible ?? true),
                'link_join_enabled' => (bool) ($club->link_join_enabled ?? true),
                'join_url' => $this->buildJoinUrl($club->join_code),
            ],
            'me' => [
                'is_member' => $isMember,
                'pending_request_id' => $pending?->id,
            ],
        ]);
    }

    public function requestByCode(Request $request, string $joinCode)
    {
        $auth = $request->user() ?? abort(401);
        $club = $this->resolveClubByJoinCode($joinCode);
        abort_if(!$this->isClubActive($club), 409, 'El grupo está desactivado.');
        abort_unless(
            (bool) ($club->is_visible ?? true) && (bool) ($club->link_join_enabled ?? true),
            404,
            'El grupo no acepta solicitudes de ingreso.'
        );

        $joinRequest = $this->createRequest($club, (int) $auth->id, 'link');

        return response()->json([
            'message' => 'Solicitud de ingreso enviada.',
            'request' => $joinRequest,
        ], 201);
    }

    public function requestByClub(Request $request, Club $club)
    {
        $auth = $request->user() ?? abort(401);
        $acceptsRequests = (bool) ($club->is_visible ?? true)
            && (bool) ($club->link_join_enabled ?? true);
        abort_unless($acceptsRequests, 404, 'El grupo no acepta solicitudes de ingreso.');

        $joinRequest = $this->createRequest($club, (int) $auth->id, 'search');

        return response()->json([
            'message' => 'Solicitud de ingreso enviada.',
            'request' => $joinRequest,
        ], 201);
    }

    public function listByClub(Request $request, Club $club)
    {
        $auth = $request->user() ?? abort(401);
        abort_unless($this->isClubAdminOrSuper((int) $club->id, (int) $auth->id, (bool) $auth->is_superadmin), 403);

        $status = trim((string) $request->query('status', 'pending'));
        $validStatuses = [
            ClubJoinRequest::STATUS_PENDING,
            ClubJoinRequest::STATUS_ACCEPTED,
            ClubJoinRequest::STATUS_REJECTED,
            ClubJoinRequest::STATUS_CANCELLED,
            ClubJoinRequest::STATUS_EXPIRED,
            'all',
        ];
        if (!in_array($status, $validStatuses, true)) {
            $status = 'pending';
        }

        $query = ClubJoinRequest::query()
            ->where('club_id', $club->id)
            ->where('status', '!=', ClubJoinRequest::STATUS_CANCELLED)
            ->with('requester:id,name,nick,email,sexo,fec_nac,avatar_url');

        if ($status !== 'all') {
            $query->where('status', $status);
        }

        $items = $query
            ->orderByRaw("CASE WHEN status = 'pending' THEN 0 ELSE 1 END")
            ->orderByDesc('requested_at')
            ->orderByDesc('id')
            ->limit(300)
            ->get()
            ->map(function (ClubJoinRequest $row) {
                return [
                    'id' => $row->id,
                    'club_id' => $row->club_id,
                    'requester_user_id' => $row->requester_user_id,
                    'requested_via' => $row->requested_via,
                    'status' => $row->status,
                    'note' => $row->note,
                    'requested_at' => optional($row->requested_at)->toISOString(),
                    'decided_at' => optional($row->decided_at)->toISOString(),
                    'requester' => $row->requester,
                ];
            })->values();

        return response()->json(['items' => $items]);
    }

    public function decide(Request $request, Club $club, ClubJoinRequest $joinRequest)
    {
        $auth = $request->user() ?? abort(401);
        abort_unless((int) $joinRequest->club_id === (int) $club->id, 404);
        abort_unless($this->isClubAdminOrSuper((int) $club->id, (int) $auth->id, (bool) $auth->is_superadmin), 403);

        $data = $request->validate([
            'action' => ['required', Rule::in(['accept', 'reject'])],
            'note' => ['nullable', 'string', 'max:255'],
        ]);

        abort_if($joinRequest->status !== ClubJoinRequest::STATUS_PENDING, 422, 'La solicitud ya fue procesada.');

        if ($data['action'] === 'reject') {
            $joinRequest->update([
                'status' => ClubJoinRequest::STATUS_REJECTED,
                'decided_at' => now(),
                'decided_by_user_id' => $auth->id,
                'note' => $data['note'] ?? null,
            ]);

            $this->eventService->track(
                'club_join_request_rejected',
                (int) $auth->id,
                (int) $club->id,
                null,
                ['request_id' => (int) $joinRequest->id, 'requester_user_id' => (int) $joinRequest->requester_user_id]
            );

            return response()->json(['message' => 'Solicitud rechazada.']);
        }

        ClubUser::updateOrCreate(
            [
                'club_id' => $club->id,
                'user_id' => $joinRequest->requester_user_id,
            ],
            [
                'rol' => 'miembro',
                'estado' => 1,
            ]
        );

        $joinRequest->update([
            'status' => ClubJoinRequest::STATUS_ACCEPTED,
            'decided_at' => now(),
            'decided_by_user_id' => $auth->id,
            'note' => $data['note'] ?? null,
        ]);

        $this->eventService->track(
            'club_join_request_accepted',
            (int) $auth->id,
            (int) $club->id,
            null,
            ['request_id' => (int) $joinRequest->id, 'requester_user_id' => (int) $joinRequest->requester_user_id]
        );

        return response()->json(['message' => 'Solicitud aceptada.']);
    }

    public function cancel(Request $request, Club $club, ClubJoinRequest $joinRequest)
    {
        $auth = $request->user() ?? abort(401);
        abort_unless((int) $joinRequest->club_id === (int) $club->id, 404);
        abort_unless((int) $joinRequest->requester_user_id === (int) $auth->id, 403);
        abort_if($joinRequest->status !== ClubJoinRequest::STATUS_PENDING, 422, 'Solo puedes cancelar solicitudes pendientes.');

        $joinRequest->update([
            'status' => ClubJoinRequest::STATUS_CANCELLED,
            'decided_at' => now(),
            'decided_by_user_id' => $auth->id,
        ]);

        $this->eventService->track(
            'club_join_request_cancelled',
            (int) $auth->id,
            (int) $club->id,
            null,
            ['request_id' => (int) $joinRequest->id]
        );

        return response()->json(['message' => 'Solicitud cancelada.']);
    }

    public function rotateJoinCode(Request $request, Club $club)
    {
        $auth = $request->user() ?? abort(401);
        abort_unless($this->isClubAdminOrSuper((int) $club->id, (int) $auth->id, (bool) $auth->is_superadmin), 403);

        $newCode = $this->generateUniqueJoinCode();
        $club->update(['join_code' => $newCode]);

        return response()->json([
            'message' => 'Join link rotado.',
            'join_code' => $newCode,
            'join_url' => $this->buildJoinUrl($newCode),
        ]);
    }

    private function resolveClubByJoinCode(string $joinCode): Club
    {
        abort_unless(Schema::hasColumn('clubs', 'join_code'), 404, 'Esta versión aún no tiene links de ingreso habilitados.');

        $clean = strtoupper(trim($joinCode));
        abort_if($clean === '', 404);

        $club = Club::query()
            ->whereRaw('UPPER(join_code) = ?', [$clean])
            ->first();

        abort_unless($club, 404, 'Join link inválido.');

        return $club;
    }

    private function createRequest(Club $club, int $userId, string $via): ClubJoinRequest
    {
        abort_if($this->isMember((int) $club->id, $userId), 422, 'Ya eres miembro de este grupo.');

        $existingPending = ClubJoinRequest::query()
            ->where('club_id', $club->id)
            ->where('requester_user_id', $userId)
            ->where('status', ClubJoinRequest::STATUS_PENDING)
            ->first();

        abort_if($existingPending, 422, 'Ya tienes una solicitud pendiente.');

        $request = ClubJoinRequest::create([
            'club_id' => $club->id,
            'requester_user_id' => $userId,
            'requested_via' => $via,
            'status' => ClubJoinRequest::STATUS_PENDING,
            'requested_at' => now(),
        ]);

        $this->eventService->track(
            'club_join_request_created',
            $userId,
            (int) $club->id,
            null,
            ['request_id' => (int) $request->id, 'requested_via' => $via]
        );

        return $request;
    }

    private function pendingRequest(Club $club, int $userId): ?ClubJoinRequest
    {
        return ClubJoinRequest::query()
            ->where('club_id', $club->id)
            ->where('requester_user_id', $userId)
            ->where('status', ClubJoinRequest::STATUS_PENDING)
            ->first();
    }

    private function isMember(int $clubId, int $userId): bool
    {
        return ClubUser::query()
            ->where('club_id', $clubId)
            ->where('user_id', $userId)
            ->active()
            ->exists();
    }

    private function isClubAdminOrSuper(int $clubId, int $userId, bool $isSuper): bool
    {
        if ($isSuper) {
            return true;
        }

        return ClubUser::query()
            ->where('club_id', $clubId)
            ->where('user_id', $userId)
            ->active()
            ->where('rol', 'admin')
            ->exists();
    }

    private function isClubActive(Club $club): bool
    {
        return !Schema::hasColumn('clubs', 'estado') || (int) $club->estado === 1;
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
