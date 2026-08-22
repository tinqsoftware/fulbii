<?php

namespace App\Services;

use App\Models\Championship;
use App\Models\ChampionshipMatch;
use App\Models\ChampionshipPlayerStat;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;

/**
 * Rebuilds tournament player totals from the authoritative match squads and
 * event log. Rebuilding keeps corrections and audited result edits idempotent.
 */
class ChampionshipStatisticsService
{
    public function rebuild(Championship $championship): void
    {
        $matches = ChampionshipMatch::query()
            ->where('championship_id', $championship->id)
            ->where('status', 'finished')
            ->with(['squads', 'events'])
            ->get();

        $totals = $this->aggregate($matches);

        DB::transaction(function () use ($championship, $totals): void {
            $userIds = array_keys($totals);
            $query = ChampionshipPlayerStat::query()->where('championship_id', $championship->id);
            if ($userIds) {
                $query->whereNotIn('user_id', $userIds);
            }
            $query->delete();

            foreach ($totals as $userId => $values) {
                ChampionshipPlayerStat::updateOrCreate(
                    [
                        'championship_id' => (int) $championship->id,
                        'user_id' => (int) $userId,
                    ],
                    $values
                );
            }
        });
    }

    /**
     * @param Collection<int, ChampionshipMatch> $matches
     * @return array<int, array<string, int|null>>
     */
    public function aggregate(Collection $matches): array
    {
        $totals = [];

        foreach ($matches as $match) {
            foreach ($match->squads as $squad) {
                if (in_array($squad->status, ['withdrawn'], true)) {
                    continue;
                }
                $userId = (int) $squad->user_id;
                if ($userId <= 0) {
                    continue;
                }
                $row = $totals[$userId] ?? $this->emptyRow();
                $row['current_team_id'] = (int) $squad->championship_team_id;
                $row['matches_played']++;
                $row['minutes_played'] += (int) $squad->minutes_played;
                $totals[$userId] = $row;
            }

            foreach ($match->events as $event) {
                $playerId = (int) ($event->player_user_id ?? 0);
                $secondaryId = (int) ($event->secondary_player_user_id ?? 0);
                if ($event->event_type === 'goal' && $playerId > 0) {
                    $row = $totals[$playerId] ?? $this->emptyRow();
                    $row['goals']++;
                    $totals[$playerId] = $row;
                }
                if ($event->event_type === 'assist' && $playerId > 0) {
                    $row = $totals[$playerId] ?? $this->emptyRow();
                    $row['assists']++;
                    $totals[$playerId] = $row;
                }
                if (in_array($event->event_type, ['yellow_card', 'red_card'], true) && $playerId > 0) {
                    $row = $totals[$playerId] ?? $this->emptyRow();
                    $row[$event->event_type === 'yellow_card' ? 'yellow_cards' : 'red_cards']++;
                    $totals[$playerId] = $row;
                }
                // A goal may optionally carry the assisting player in the
                // secondary field, which keeps the API ergonomic for live logs.
                if ($event->event_type === 'goal' && $secondaryId > 0) {
                    $row = $totals[$secondaryId] ?? $this->emptyRow();
                    $row['assists']++;
                    $totals[$secondaryId] = $row;
                }
            }
        }

        return $totals;
    }

    /** @return array<string, int|null> */
    private function emptyRow(): array
    {
        return [
            'current_team_id' => null,
            'matches_played' => 0,
            'minutes_played' => 0,
            'goals' => 0,
            'assists' => 0,
            'goals_conceded' => 0,
            'clean_sheets' => 0,
            'yellow_cards' => 0,
            'red_cards' => 0,
        ];
    }
}
