<?php

namespace App\Services;

use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class CombinedSkillRatingService
{
    /**
     * @param Collection<int,int>|array<int,int> $userIds
     * @return Collection<int, object>
     */
    public function averagesByUserIds(Collection|array $userIds, ?int $clubId = null): Collection
    {
        $ids = $userIds instanceof Collection ? $userIds->values()->all() : array_values($userIds);
        if (empty($ids)) {
            return collect();
        }

        $queries = [];
        if (Schema::hasTable('calificaciones')) {
            $queries[] = $this->freeRatingsQuery($ids, $clubId);
        }
        if (Schema::hasTable('group_pichanga_ratings') && Schema::hasTable('group_pichangas')) {
            $queries[] = $this->pichangaRatingsQuery($ids, $clubId);
        }
        if ($queries === []) {
            return collect();
        }
        $union = array_shift($queries);
        foreach ($queries as $query) {
            $union->unionAll($query);
        }

        return DB::query()
            ->fromSub($union, 'skill_votes')
            ->selectRaw(
                'user_id,
                AVG(fisico) as fisico,
                AVG(arquero) as arquero,
                AVG(delantero) as delantero,
                AVG(mediocampo) as mediocampo,
                AVG(defensa) as defensa,
                COUNT(*) as votos'
            )
            ->groupBy('user_id')
            ->get()
            ->keyBy('user_id');
    }

    /**
     * @return array{
     *   votos:int,
     *   fisico:?float,
     *   arquero:?float,
     *   delantero:?float,
     *   mediocampo:?float,
     *   defensa:?float,
     *   field_average:?float,
     *   player_average:?float,
     *   goalkeeper_average:?float,
     *   stars:?float,
     *   primary_role:'jugador'|'arquero'|null,
     *   primary_position:'delantero'|'mediocampo'|'defensa'|'arquero'|null
     * }
     */
    public function summaryForUser(int $userId, ?int $clubId = null): array
    {
        $row = $this->averagesByUserIds([$userId], $clubId)->get($userId);
        if (!$row) {
            return $this->emptySummary();
        }

        return $this->deriveSummary($row);
    }

    /**
     * @return array{votos:int,fisico:?float,arquero:?float,delantero:?float,mediocampo:?float,defensa:?float,field_average:?float,player_average:?float,goalkeeper_average:?float,stars:?float,primary_role:'jugador'|'arquero'|null,primary_position:'delantero'|'mediocampo'|'defensa'|'arquero'|null}
     */
    public function deriveSummary(object|array $row): array
    {
        $value = fn (string $key) => is_array($row) ? ($row[$key] ?? null) : ($row->{$key} ?? null);
        $physical = $value('fisico') !== null ? (float) $value('fisico') : null;
        $fieldValues = array_filter([
            $value('delantero'),
            $value('mediocampo'),
            $value('defensa'),
        ], fn ($score) => $score !== null);
        $fieldAverage = empty($fieldValues) ? null : round(array_sum($fieldValues) / count($fieldValues), 2);
        $playerAverage = $physical === null || $fieldAverage === null
            ? null
            : round(($fieldAverage + $physical) / 2, 2);
        $goalkeeperAverage = $physical === null || $value('arquero') === null
            ? null
            : round(((float) $value('arquero') + $physical) / 2, 2);
        $stars = null;
        $primaryRole = null;
        $primaryPosition = null;
        if ($playerAverage !== null || $goalkeeperAverage !== null) {
            // En empate se prioriza al jugador de campo.
            if ($playerAverage !== null && ($goalkeeperAverage === null || $playerAverage >= $goalkeeperAverage)) {
                $stars = $playerAverage;
                $primaryRole = 'jugador';
                // Ties use the visible scoring order: forward, midfield, defense.
                $positions = [
                    'delantero' => $value('delantero'),
                    'mediocampo' => $value('mediocampo'),
                    'defensa' => $value('defensa'),
                ];
                $best = max(array_map(fn ($score) => $score === null ? -1 : (float) $score, $positions));
                foreach ($positions as $position => $score) {
                    if ($score !== null && (float) $score === $best) {
                        $primaryPosition = $position;
                        break;
                    }
                }
            } else {
                $stars = $goalkeeperAverage;
                $primaryRole = 'arquero';
                $primaryPosition = 'arquero';
            }
        }

        return [
            'votos' => (int) $value('votos'),
            'fisico' => $physical !== null ? round($physical, 2) : null,
            'arquero' => $value('arquero') !== null ? round((float) $value('arquero'), 2) : null,
            'delantero' => $value('delantero') !== null ? round((float) $value('delantero'), 2) : null,
            'mediocampo' => $value('mediocampo') !== null ? round((float) $value('mediocampo'), 2) : null,
            'defensa' => $value('defensa') !== null ? round((float) $value('defensa'), 2) : null,
            'field_average' => $fieldAverage,
            'player_average' => $playerAverage,
            'goalkeeper_average' => $goalkeeperAverage,
            'stars' => $stars,
            'primary_role' => $primaryRole,
            'primary_position' => $primaryPosition,
        ];
    }

    /** @param iterable<object|array> $votes */
    public function summaryForVotes(iterable $votes): array
    {
        $rows = collect($votes);
        if ($rows->isEmpty()) {
            return $this->emptySummary();
        }
        $average = ['votos' => $rows->count()];
        foreach (['fisico', 'arquero', 'delantero', 'mediocampo', 'defensa'] as $skill) {
            $scores = $rows->map(fn ($row) => is_array($row) ? ($row[$skill] ?? null) : ($row->{$skill} ?? null))
                ->filter(fn ($score) => $score !== null)
                ->map(fn ($score) => (float) $score);
            $average[$skill] = $scores->isEmpty() ? null : $scores->avg();
        }
        return $this->deriveSummary($average);
    }

    /**
     * @return array{votos:int,fisico:?float,arquero:?float,delantero:?float,mediocampo:?float,defensa:?float,field_average:?float,player_average:?float,goalkeeper_average:?float,stars:?float,primary_role:'jugador'|'arquero'|null,primary_position:'delantero'|'mediocampo'|'defensa'|'arquero'|null}
     */
    private function emptySummary(): array
    {
        return [
            'votos' => 0,
            'fisico' => null,
            'arquero' => null,
            'delantero' => null,
            'mediocampo' => null,
            'defensa' => null,
            'field_average' => null,
            'player_average' => null,
            'goalkeeper_average' => null,
            'stars' => null,
            'primary_role' => null,
            'primary_position' => null,
        ];
    }

    private function freeRatingsQuery(array $userIds, ?int $clubId = null)
    {
        $query = DB::table('calificaciones')
            ->selectRaw(
                'user_calificado_id as user_id,
                fisico,
                arquero,
                delantero,
                mediocampo,
                defensa'
            )
            ->whereIn('user_calificado_id', $userIds);

        if (Schema::hasColumn('calificaciones', 'deleted_at')) {
            $query->whereNull('deleted_at');
        }
        if (Schema::hasColumn('calificaciones', 'silenciada_por_admin_at')) {
            $query->whereNull('silenciada_por_admin_at');
        }

        if ($clubId !== null) {
            $query->where(function ($where) use ($clubId) {
                $where->where('club_id', $clubId)->orWhereNull('club_id');
            });
        }

        return $query;
    }

    private function pichangaRatingsQuery(array $userIds, ?int $clubId = null)
    {
        $query = DB::table('group_pichanga_ratings as gpr')
            ->join('group_pichangas as gp', 'gp.id', '=', 'gpr.pichanga_id')
            ->selectRaw(
                'gpr.rated_user_id as user_id,
                gpr.fisico as fisico,
                gpr.arquero as arquero,
                gpr.delantero as delantero,
                gpr.mediocampo as mediocampo,
                gpr.defensa as defensa'
            )
            ->whereIn('gpr.rated_user_id', $userIds);

        if ($clubId !== null) {
            $query->where('gp.club_id', $clubId);
        }

        return $query;
    }
}
