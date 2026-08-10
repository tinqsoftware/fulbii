<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Club;
use App\Models\ClubGroupMessage;
use App\Models\ClubGroupMessageRead;
use App\Models\ClubUser;
use App\Models\UserBlock;
use App\Services\ClubNotificationService;
use Illuminate\Http\Request;

class ClubGroupChatController extends Controller
{
    public function __construct(private readonly ClubNotificationService $notifications)
    {
    }

    public function index(Request $request, Club $club)
    {
        $user = $request->user() ?? abort(401);
        $this->authorizeMember((int) $club->id, (int) $user->id, (bool) $user->is_superadmin);
        $limit = max(1, min(100, (int) $request->query('limit', 60)));
        $blockedIds = $this->blockedCounterpartIds((int) $user->id);

        $items = ClubGroupMessage::query()
            ->where('club_id', $club->id)
            ->when($blockedIds !== [], fn ($query) => $query->whereNotIn('user_id', $blockedIds))
            ->with('user:id,name,nick,avatar_url')
            ->latest('id')
            ->limit($limit)
            ->get()
            ->reverse()
            ->values();

        $lastRead = ClubGroupMessageRead::query()
            ->where('club_id', $club->id)
            ->where('user_id', $user->id)
            ->value('last_read_message_id');

        return response()->json([
            'items' => $items,
            'last_read_message_id' => $lastRead ? (int) $lastRead : null,
        ]);
    }

    public function send(Request $request, Club $club)
    {
        $user = $request->user() ?? abort(401);
        $this->authorizeMember((int) $club->id, (int) $user->id, (bool) $user->is_superadmin);
        $data = $request->validate(['body' => ['required', 'string', 'max:1500']]);

        $message = ClubGroupMessage::create([
            'club_id' => $club->id,
            'user_id' => $user->id,
            'type' => 'text',
            'body' => trim($data['body']),
        ]);

        $blockedIds = $this->blockedCounterpartIds((int) $user->id);
        $recipientIds = $this->notifications->memberIds($club);
        $recipientIds = array_values(array_diff($recipientIds, $blockedIds));
        $senderName = (string) ($user->nick ?: $user->name ?: 'Un jugador');
        $this->notifications->notifyUsers($club, $recipientIds, [
            'type' => 'club_chat_message',
            'category' => 'chat',
            'title' => $club->nombre,
            'body' => $senderName . ': ' . mb_strimwidth((string) $message->body, 0, 120, '…'),
            'target_type' => 'club_chat',
            'target_id' => (int) $club->id,
            'image_kind' => 'club',
            'data_json' => ['club_message_id' => (int) $message->id],
        ], (int) $user->id);

        return response()->json([
            'message' => 'Mensaje enviado.',
            'item' => $message->load('user:id,name,nick,avatar_url'),
        ], 201);
    }

    public function markRead(Request $request, Club $club)
    {
        $user = $request->user() ?? abort(401);
        $this->authorizeMember((int) $club->id, (int) $user->id, (bool) $user->is_superadmin);
        $data = $request->validate(['last_read_message_id' => ['nullable', 'integer', 'min:1']]);
        $messageId = (int) ($data['last_read_message_id'] ?? 0);
        if ($messageId > 0) {
            abort_unless(ClubGroupMessage::query()->where('club_id', $club->id)->whereKey($messageId)->exists(), 422, 'El mensaje no pertenece a este grupo.');
        }

        ClubGroupMessageRead::updateOrCreate(
            ['club_id' => $club->id, 'user_id' => $user->id],
            ['last_read_message_id' => $messageId ?: null]
        );

        return response()->json(['message' => 'Chat marcado como leído.']);
    }

    /** @return array<int> */
    private function blockedCounterpartIds(int $userId): array
    {
        return UserBlock::query()
            ->where('blocker_user_id', $userId)
            ->orWhere('blocked_user_id', $userId)
            ->get(['blocker_user_id', 'blocked_user_id'])
            ->map(fn (UserBlock $row) => (int) ($row->blocker_user_id === $userId ? $row->blocked_user_id : $row->blocker_user_id))
            ->all();
    }

    private function authorizeMember(int $clubId, int $userId, bool $isSuper): void
    {
        if ($isSuper) {
            return;
        }
        abort_unless(ClubUser::query()->where('club_id', $clubId)->where('user_id', $userId)->active()->exists(), 403, 'No perteneces a este grupo.');
    }
}
