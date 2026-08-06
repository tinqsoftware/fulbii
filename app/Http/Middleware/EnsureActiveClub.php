<?php

namespace App\Http\Middleware;

use App\Models\Club;
use App\Models\ClubChallenge;
use App\Models\ClubInvitation;
use App\Models\GroupPichanga;
use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Schema;

class EnsureActiveClub
{
    public function handle(Request $request, Closure $next, string $routeParameter)
    {
        if (!Schema::hasColumn('clubs', 'estado')) {
            return $next($request);
        }

        $clubIds = $this->clubIdsFor($request->route($routeParameter));
        if ($clubIds === []) {
            return $next($request);
        }

        $activeCount = Club::query()
            ->whereIn('id', $clubIds)
            ->where('estado', 1)
            ->count();

        if ($activeCount !== count($clubIds)) {
            return response()->json([
                'message' => 'El grupo está desactivado.',
                'code' => 'club_inactive',
            ], 409);
        }

        return $next($request);
    }

    /** @return array<int, int> */
    private function clubIdsFor(mixed $source): array
    {
        if ($source instanceof Club) {
            return [(int) $source->id];
        }

        if ($source instanceof GroupPichanga) {
            $clubIds = [(int) $source->club_id];
            if ((int) ($source->rival_club_id ?? 0) > 0) {
                $clubIds[] = (int) $source->rival_club_id;
            }

            return array_values(array_unique($clubIds));
        }

        if ($source instanceof ClubInvitation) {
            return [(int) $source->club_id];
        }

        if ($source instanceof ClubChallenge) {
            return array_values(array_unique([
                (int) $source->challenger_club_id,
                (int) $source->challenged_club_id,
            ]));
        }

        return [];
    }
}
