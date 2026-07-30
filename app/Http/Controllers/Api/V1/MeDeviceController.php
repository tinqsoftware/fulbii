<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\UserDevice;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class MeDeviceController extends Controller
{
    public function index(Request $request)
    {
        $user = $request->user() ?? abort(401);

        $items = UserDevice::where('user_id', $user->id)
            ->orderByDesc('last_seen_at')
            ->orderByDesc('id')
            ->get([
                'id', 'platform', 'device_name', 'app_version', 'is_active', 'last_seen_at', 'created_at',
            ]);

        return response()->json(['items' => $items]);
    }

    public function register(Request $request)
    {
        $user = $request->user() ?? abort(401);
        $data = $request->validate([
            'platform' => ['required', Rule::in(['ios', 'android', 'web'])],
            'device_token' => ['required', 'string', 'max:255'],
            'device_name' => ['nullable', 'string', 'max:100'],
            'app_version' => ['nullable', 'string', 'max:40'],
        ]);

        $device = UserDevice::updateOrCreate(
            [
                'platform' => $data['platform'],
                'device_token' => $data['device_token'],
            ],
            [
                'user_id' => $user->id,
                'device_name' => $data['device_name'] ?? null,
                'app_version' => $data['app_version'] ?? null,
                'is_active' => true,
                'last_seen_at' => now(),
            ]
        );

        return response()->json([
            'message' => 'Dispositivo registrado.',
            'device' => $device,
        ]);
    }

    public function deactivate(Request $request, UserDevice $device)
    {
        $user = $request->user() ?? abort(401);
        abort_unless((int) $device->user_id === (int) $user->id, 403);

        $device->update([
            'is_active' => false,
            'last_seen_at' => now(),
        ]);

        return response()->json(['message' => 'Dispositivo desactivado.']);
    }
}
