<?php

namespace App\Services;

use App\Models\ClubUser;
use App\Models\GroupPichanga;
use Carbon\Carbon;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;

class GroupPichangaAudienceService
{
    public function __construct(private readonly CombinedSkillRatingService $combinedSkillRatings)
    {
    }

    /**
     * @return array{
     *   target_degree:int,
     *   filters:array<string,mixed>,
     *   by_degree:array<int,array{pool:int,eligible:int,user_ids:array<int>}>,
     *   target_user_ids:array<int>
     * }
     */
    public function resolveAudience(
        GroupPichanga $pichanga,
        ?array $overrides = null,
        bool $applyFiltersToMembers = false
    ): array {
        $filters = $this->mergeFilters($pichanga, $overrides ?? []);
        $targetDegree = (int) ($overrides['target_degree'] ?? $pichanga->notify_degree ?? 1);
        $targetDegree = max(1, min(3, $targetDegree));

        $clubIdsByDegree = $this->clubIdsByDegree((int) $pichanga->club_id, $targetDegree);

        $seenUserIds = collect();
        $byDegree = [];
        $allEligible = collect();

        for ($degree = 1; $degree <= $targetDegree; $degree++) {
            $clubIds = $clubIdsByDegree[$degree] ?? [];
            $poolUserIds = $this->usersInClubs($clubIds)->diff($seenUserIds)->values();
            $seenUserIds = $seenUserIds->merge($poolUserIds)->unique()->values();

            $filtered = $poolUserIds;
            $shouldFilter = $degree > 1 || $applyFiltersToMembers;
            if ($shouldFilter) {
                $filtered = $this->applyProfileFilters(
                    $poolUserIds,
                    $filters,
                    $pichanga->starts_at ?? now(),
                    (int) $pichanga->club_id
                );
            }

            $allEligible = $allEligible->merge($filtered)->unique()->values();

            $byDegree[$degree] = [
                'pool' => $poolUserIds->count(),
                'eligible' => $filtered->count(),
                'user_ids' => $filtered->all(),
            ];
        }

        return [
            'target_degree' => $targetDegree,
            'filters' => $filters,
            'by_degree' => $byDegree,
            'target_user_ids' => $allEligible->all(),
        ];
    }

    /**
     * @return array{eligible:bool,degree:int|null}
     */
    public function externalEligibility(GroupPichanga $pichanga, int $userId): array
    {
        $audience = $this->resolveAudience($pichanga);
        foreach ($audience['by_degree'] as $degree => $info) {
            if ((int) $degree <= 1) {
                continue;
            }
            if (in_array($userId, $info['user_ids'], true)) {
                return ['eligible' => true, 'degree' => (int) $degree];
            }
        }

        return ['eligible' => false, 'degree' => null];
    }

    /**
     * @return Collection<int, int>
     */
    private function usersInClubs(array $clubIds): Collection
    {
        if (empty($clubIds)) {
            return collect();
        }

        return ClubUser::query()
            ->whereIn('club_id', $clubIds)
            ->pluck('user_id')
            ->map(fn($id) => (int) $id)
            ->unique()
            ->values();
    }

    /**
     * Returns club IDs grouped by audience degree:
     * degree 1 => same club
     * degree 2 => neighboring clubs (share at least one member)
     * degree 3 => neighbors of degree-2 clubs
     *
     * @return array<int, array<int>>
     */
    private function clubIdsByDegree(int $originClubId, int $maxDegree): array
    {
        $map = [1 => [$originClubId]];
        if ($maxDegree === 1) {
            return $map;
        }

        $pairs = ClubUser::query()
            ->select('user_id', 'club_id')
            ->get();

        $clubsByUser = [];
        foreach ($pairs as $row) {
            $clubsByUser[(int) $row->user_id][] = (int) $row->club_id;
        }

        $adj = [];
        foreach ($clubsByUser as $clubIds) {
            $unique = array_values(array_unique($clubIds));
            $count = count($unique);
            for ($i = 0; $i < $count; $i++) {
                $a = $unique[$i];
                $adj[$a] = $adj[$a] ?? [];
                for ($j = 0; $j < $count; $j++) {
                    if ($i === $j) {
                        continue;
                    }
                    $b = $unique[$j];
                    $adj[$a][$b] = true;
                }
            }
        }

        $visited = [$originClubId => 0];
        $queue = [[$originClubId, 0]];
        while (!empty($queue)) {
            [$club, $depth] = array_shift($queue);
            if ($depth >= ($maxDegree - 1)) {
                continue;
            }
            $neighbors = array_keys($adj[$club] ?? []);
            foreach ($neighbors as $neighbor) {
                if (!array_key_exists($neighbor, $visited)) {
                    $visited[$neighbor] = $depth + 1;
                    $queue[] = [$neighbor, $depth + 1];
                }
            }
        }

        for ($degree = 2; $degree <= $maxDegree; $degree++) {
            $distance = $degree - 1;
            $map[$degree] = array_values(array_map(
                fn($clubId) => (int) $clubId,
                array_keys(array_filter($visited, fn($d) => $d === $distance))
            ));
        }

        return $map;
    }

    /**
     * @param Collection<int, int> $userIds
     * @param array<string,mixed> $filters
     * @return Collection<int, int>
     */
    private function applyProfileFilters(
        Collection $userIds,
        array $filters,
        Carbon $referenceDate,
        int $clubId
    ): Collection
    {
        if ($userIds->isEmpty()) {
            return collect();
        }

        $needsAge = !empty($filters['audience_age_min']) || !empty($filters['audience_age_max']);
        $needsSex = !empty($filters['audience_sex']);
        $needsSkills = collect([
            'skill_fisico_min',
            'skill_arquero_min',
            'skill_delantero_min',
            'skill_mediocampo_min',
            'skill_defensa_min',
        ])->contains(fn($k) => !empty($filters[$k]));

        if (!$needsAge && !$needsSex && !$needsSkills) {
            return $userIds;
        }

        $users = DB::table('users')
            ->select('id', 'sexo', 'fec_nac')
            ->whereIn('id', $userIds->all())
            ->get()
            ->keyBy('id');

        $skillsByUser = collect();
        if ($needsSkills) {
            $skillsByUser = $this->combinedSkillRatings->averagesByUserIds($userIds, $clubId);
        }

        return $userIds->filter(function (int $userId) use ($users, $skillsByUser, $filters, $referenceDate, $needsAge, $needsSex, $needsSkills): bool {
            $user = $users->get($userId);
            if (!$user) {
                return false;
            }

            if ($needsSex && !empty($filters['audience_sex'])) {
                if (($user->sexo ?? null) !== $filters['audience_sex']) {
                    return false;
                }
            }

            if ($needsAge) {
                if (empty($user->fec_nac)) {
                    return false;
                }
                $birth = Carbon::parse((string) $user->fec_nac);
                $age = $birth->diffInYears($referenceDate);
                if (!empty($filters['audience_age_min']) && $age < (int) $filters['audience_age_min']) {
                    return false;
                }
                if (!empty($filters['audience_age_max']) && $age > (int) $filters['audience_age_max']) {
                    return false;
                }
            }

            if ($needsSkills) {
                $row = $skillsByUser->get($userId);
                if (!$row) {
                    return false;
                }
                $map = [
                    'skill_fisico_min' => 'fisico',
                    'skill_arquero_min' => 'arquero',
                    'skill_delantero_min' => 'delantero',
                    'skill_mediocampo_min' => 'mediocampo',
                    'skill_defensa_min' => 'defensa',
                ];
                foreach ($map as $filterKey => $skillKey) {
                    $min = $filters[$filterKey] ?? null;
                    if ($min === null || $min === '') {
                        continue;
                    }
                    $value = (float) ($row->{$skillKey} ?? 0);
                    if ($value < (float) $min) {
                        return false;
                    }
                }
            }

            return true;
        })->values();
    }

    /**
     * @return array<string,mixed>
     */
    private function mergeFilters(GroupPichanga $pichanga, array $overrides): array
    {
        $base = [
            'audience_sex' => $pichanga->audience_sex,
            'audience_age_min' => $pichanga->audience_age_min,
            'audience_age_max' => $pichanga->audience_age_max,
            'skill_fisico_min' => $pichanga->skill_fisico_min,
            'skill_arquero_min' => $pichanga->skill_arquero_min,
            'skill_delantero_min' => $pichanga->skill_delantero_min,
            'skill_mediocampo_min' => $pichanga->skill_mediocampo_min,
            'skill_defensa_min' => $pichanga->skill_defensa_min,
        ];

        foreach (array_keys($base) as $key) {
            if (array_key_exists($key, $overrides)) {
                $base[$key] = $overrides[$key];
            }
        }

        return $base;
    }
}
