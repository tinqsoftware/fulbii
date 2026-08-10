<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Models\UserBlock;
use Illuminate\Http\Request;

class UserBlockController extends Controller
{
    public function index(Request $request)
    {
        $user = $request->user() ?? abort(401);
        $items = UserBlock::query()
            ->where('blocker_user_id', $user->id)
            ->with('blocked:id,name,nick,avatar_url')
            ->latest('id')->get();
        return response()->json(['items' => $items]);
    }

    public function store(Request $request, User $user)
    {
        $auth = $request->user() ?? abort(401);
        abort_if((int) $auth->id === (int) $user->id, 422, 'No puedes bloquearte a ti mismo.');
        UserBlock::firstOrCreate(['blocker_user_id' => $auth->id, 'blocked_user_id' => $user->id]);
        return response()->json(['message' => 'Usuario bloqueado.'], 201);
    }

    public function destroy(Request $request, User $user)
    {
        $auth = $request->user() ?? abort(401);
        UserBlock::query()->where('blocker_user_id', $auth->id)->where('blocked_user_id', $user->id)->delete();
        return response()->json(['message' => 'Usuario desbloqueado.']);
    }
}
