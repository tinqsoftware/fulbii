<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class OptionalSanctumAuthentication
{
    public function handle(Request $request, Closure $next): Response
    {
        $user = $request->user() ?: auth('sanctum')->user();

        if ($user) {
            $request->setUserResolver(fn () => $user);
        }

        return $next($request);
    }
}
