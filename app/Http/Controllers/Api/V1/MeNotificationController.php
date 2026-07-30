<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\PushNotification;
use Illuminate\Http\Request;

class MeNotificationController extends Controller
{
    public function index(Request $request)
    {
        $user = $request->user() ?? abort(401);
        $limit = max(1, min(100, (int) $request->query('limit', 30)));

        $items = PushNotification::query()
            ->where('user_id', $user->id)
            ->orderByDesc('id')
            ->limit($limit)
            ->get([
                'id',
                'club_id',
                'group_pichanga_id',
                'type',
                'title',
                'body',
                'data_json',
                'is_read',
                'read_at',
                'created_at',
            ]);

        return response()->json([
            'items' => $items,
            'unread_count' => PushNotification::where('user_id', $user->id)->where('is_read', false)->count(),
        ]);
    }

    public function markRead(Request $request, PushNotification $notification)
    {
        $user = $request->user() ?? abort(401);
        abort_unless((int) $notification->user_id === (int) $user->id, 403);

        $notification->update([
            'is_read' => true,
            'read_at' => now(),
        ]);

        return response()->json(['message' => 'Notificación marcada como leída.']);
    }

    public function markAllRead(Request $request)
    {
        $user = $request->user() ?? abort(401);
        PushNotification::where('user_id', $user->id)
            ->where('is_read', false)
            ->update([
                'is_read' => true,
                'read_at' => now(),
            ]);

        return response()->json(['message' => 'Todas las notificaciones marcadas como leídas.']);
    }
}
