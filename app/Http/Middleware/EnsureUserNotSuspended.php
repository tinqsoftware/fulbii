<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class EnsureUserNotSuspended
{
    public function handle(Request $request, Closure $next): Response
    {
        $user = $request->user();
        if ($user && method_exists($user, 'isSuspended') && $user->isSuspended()) {
            return response()->json([
                'message' => 'Tu cuenta está suspendida temporalmente.',
                'suspended_until' => optional($user->suspended_until)->toISOString(),
                'reason' => $user->suspension_reason,
            ], 423);
        }

        return $next($request);
    }
}
