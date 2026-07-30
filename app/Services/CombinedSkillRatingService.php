<?php

namespace App\Services;

use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;

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

        $union = $this->freeRatingsQuery($ids, $clubId)->unionAll(
            $this->pichangaRatingsQuery($ids, $clubId)
        );

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
     *   defensa:?float
     * }
     */
    public function summaryForUser(int $userId, ?int $clubId = null): array
    {
        $row = $this->averagesByUserIds([$userId], $clubId)->get($userId);
        if (!$row) {
            return [
                'votos' => 0,
                'fisico' => null,
                'arquero' => null,
                'delantero' => null,
                'mediocampo' => null,
                'defensa' => null,
            ];
        }

        return [
            'votos' => (int) ($row->votos ?? 0),
            'fisico' => $row->fisico !== null ? round((float) $row->fisico, 2) : null,
            'arquero' => $row->arquero !== null ? round((float) $row->arquero, 2) : null,
            'delantero' => $row->delantero !== null ? round((float) $row->delantero, 2) : null,
            'mediocampo' => $row->mediocampo !== null ? round((float) $row->mediocampo, 2) : null,
            'defensa' => $row->defensa !== null ? round((float) $row->defensa, 2) : null,
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

