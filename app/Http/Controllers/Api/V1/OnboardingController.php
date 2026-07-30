<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Schema;

class OnboardingController extends Controller
{
    public function store(Request $request)
    {
        $user = $request->user() ?? abort(401);

        $data = $request->validate([
            'nick' => ['required', 'string', 'min:3', 'max:20', 'regex:/^[A-Za-z0-9_-]+$/'],
            'sexo' => ['required', 'in:M,F'],
        ]);

        $normalizedNick = $this->normalizeNick($data['nick']);
        $alreadyTaken = User::query()
            ->whereRaw('LOWER(nick) = ?', [mb_strtolower($normalizedNick)])
            ->where('id', '!=', $user->id)
            ->exists();

        if ($alreadyTaken) {
            return response()->json([
                'message' => 'El nick ya está en uso.',
                'errors' => ['nick' => ['El nick ya está en uso.']],
            ], 422);
        }

        if (Schema::hasColumn('users', 'nick')) {
            $user->nick = $normalizedNick;
        }
        if (Schema::hasColumn('users', 'sexo')) {
            $user->sexo = $data['sexo'];
        }

        $user->save();

        return response()->json([
            'message' => 'Onboarding completo.',
            'user' => $user->fresh(),
        ]);
    }

    private function normalizeNick(string $nick): string
    {
        $value = ltrim(trim($nick), '@');
        $value = preg_replace('/\s+/', '', $value);
        return mb_strtolower($value);
    }
}
