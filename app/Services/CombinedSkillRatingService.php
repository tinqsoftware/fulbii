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
     *   player_average:?float,
     *   goalkeeper_average:?float,
     *   stars:?float,
     *   primary_role:'jugador'|'arquero'|null
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
     * @return array{votos:int,fisico:?float,arquero:?float,delantero:?float,mediocampo:?float,defensa:?float,player_average:?float,goalkeeper_average:?float,stars:?float,primary_role:'jugador'|'arquero'|null}
     */
    public function deriveSummary(object|array $row): array
    {
        $value = fn (string $key) => is_array($row) ? ($row[$key] ?? null) : ($row->{$key} ?? null);
        $fieldValues = array_filter([
            $value('fisico'),
            $value('delantero'),
            $value('mediocampo'),
            $value('defensa'),
        ], fn ($score) => $score !== null);
        $playerAverage = empty($fieldValues) ? null : round(array_sum($fieldValues) / count($fieldValues), 2);
        $goalkeeperAverage = $value('arquero') === null ? null : round((float) $value('arquero'), 2);
        $stars = null;
        $primaryRole = null;
        if ($playerAverage !== null || $goalkeeperAverage !== null) {
            // En empate se prioriza al jugador de campo.
            if ($playerAverage !== null && ($goalkeeperAverage === null || $playerAverage >= $goalkeeperAverage)) {
                $stars = $playerAverage;
                $primaryRole = 'jugador';
            } else {
                $stars = $goalkeeperAverage;
                $primaryRole = 'arquero';
            }
        }

        return [
            'votos' => (int) $value('votos'),
            'fisico' => $value('fisico') !== null ? round((float) $value('fisico'), 2) : null,
            'arquero' => $goalkeeperAverage,
            'delantero' => $value('delantero') !== null ? round((float) $value('delantero'), 2) : null,
            'mediocampo' => $value('mediocampo') !== null ? round((float) $value('mediocampo'), 2) : null,
            'defensa' => $value('defensa') !== null ? round((float) $value('defensa'), 2) : null,
            'player_average' => $playerAverage,
            'goalkeeper_average' => $goalkeeperAverage,
            'stars' => $stars,
            'primary_role' => $primaryRole,
        ];
    }

    /**
     * @return array{votos:int,fisico:?float,arquero:?float,delantero:?float,mediocampo:?float,defensa:?float,player_average:?float,goalkeeper_average:?float,stars:?float,primary_role:'jugador'|'arquero'|null}
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
            'player_average' => null,
            'goalkeeper_average' => null,
            'stars' => null,
            'primary_role' => null,
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
            ->whereIn('user_calificado_id', $userIds)
            ->whereNull('deleted_at');

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
