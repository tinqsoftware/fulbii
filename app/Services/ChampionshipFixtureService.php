<?php

namespace App\Services;

use App\Models\Championship;
use App\Models\ChampionshipMatch;
use App\Models\ChampionshipMatchday;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

class ChampionshipFixtureService
{
    /**
     * Generate a round-robin fixture. Dates and venues are deliberately left
     * empty so the organizer can assign a real court to every match later.
     */
    public function generate(Championship $championship): int
    {
        $teams = $championship->teams()
            ->whereIn('status', ['draft', 'active'])
            ->orderBy('sort_order')
            ->orderBy('id')
            ->get();

        if ($teams->count() < 2) {
            throw ValidationException::withMessages([
                'teams' => 'Se necesitan al menos dos equipos para generar el fixture.',
            ]);
        }

        if (ChampionshipMatch::query()->where('championship_id', $championship->id)->exists()) {
            throw ValidationException::withMessages([
                'fixture' => 'El fixture ya fue generado. Edítalo manualmente o elimínalo antes de regenerar.',
            ]);
        }

        $teamIds = $teams->pluck('id')->map(fn ($id) => (int) $id)->values()->all();

        if ($championship->format === 'knockout') {
            return $this->generateKnockout($championship, $teamIds);
        }

        if (!in_array($championship->format, ['league', 'hybrid'], true)) {
            throw ValidationException::withMessages([
                'format' => 'Selecciona un formato de liga o llaves.',
            ]);
        }

        $rounds = $this->buildRoundRobinPairs($teamIds, (bool) $championship->double_round_robin);

        return DB::transaction(function () use ($championship, $rounds) {
            $created = 0;
            $matchdayNumber = 1;

            foreach ($rounds as $roundIndex => $pairs) {
                $matchday = ChampionshipMatchday::create([
                    'championship_id' => $championship->id,
                    'number' => $matchdayNumber,
                    'name' => 'Fecha ' . $matchdayNumber,
                    'status' => 'draft',
                ]);

                $fixtureOrder = 1;
                foreach ($pairs as [$home, $away]) {
                    ChampionshipMatch::create([
                        'championship_id' => $championship->id,
                        'matchday_id' => $matchday->id,
                        'home_team_id' => $home,
                        'away_team_id' => $away,
                        'round_number' => $roundIndex + 1,
                        'fixture_order' => $fixtureOrder++,
                        'phase' => 'league',
                        'duration_minutes' => 60,
                        'status' => 'scheduled',
                    ]);
                    $created++;
                }
                $matchdayNumber++;
            }

            return $created;
        });
    }

    /**
     * Propagate an official knockout winner into the next bracket slot.
     * The row lock keeps two concurrent result submissions from overwriting
     * the same slot. Draws intentionally remain unresolved until the
     * organizer records the tie-breaker/penalties result.
     */
    public function advanceWinner(ChampionshipMatch $match): void
    {
        if (($match->phase ?? 'league') !== 'knockout'
            || $match->home_score === null
            || $match->away_score === null
            || $match->home_score === $match->away_score
            || !$match->bracket_round
            || !$match->bracket_position) {
            return;
        }

        $winnerId = (int) ($match->home_score > $match->away_score
            ? $match->home_team_id
            : $match->away_team_id);
        if ($winnerId <= 0) {
            return;
        }

        DB::transaction(function () use ($match, $winnerId): void {
            $next = ChampionshipMatch::query()
                ->where('championship_id', $match->championship_id)
                ->where('phase', 'knockout')
                ->where('bracket_round', (int) $match->bracket_round + 1)
                ->where('bracket_position', (int) ceil((int) $match->bracket_position / 2))
                ->lockForUpdate()
                ->first();
            if (!$next) {
                return;
            }

            $slot = ((int) $match->bracket_position % 2) === 1 ? 'home_team_id' : 'away_team_id';
            $next->update([$slot => $winnerId]);
        });
    }

    /**
     * Creates a complete single-elimination bracket. We intentionally require
     * a power-of-two number of teams for the first release so every bye is
     * explicit and no team is silently advanced by an organizer mistake.
     * Later rounds are created with empty slots and are filled atomically when
     * the previous match receives its official result.
     */
    private function generateKnockout(Championship $championship, array $teamIds): int
    {
        $teamCount = count($teamIds);
        if ($teamCount < 2 || ($teamCount & ($teamCount - 1)) !== 0) {
            throw ValidationException::withMessages([
                'teams' => 'El formato por llaves requiere 2, 4, 8, 16 o 32 equipos.',
            ]);
        }

        $roundCount = (int) log($teamCount, 2);
        return DB::transaction(function () use ($championship, $teamIds, $roundCount): int {
            $created = 0;
            $dayNumber = 1;
            $roundNames = $this->knockoutRoundNames($teamCount);

            for ($round = 1; $round <= $roundCount; $round++) {
                $matchday = ChampionshipMatchday::create([
                    'championship_id' => $championship->id,
                    'number' => $dayNumber++,
                    'name' => $roundNames[$round] ?? 'Llave ' . $round,
                    'status' => 'draft',
                ]);
                $matchesInRound = intdiv($teamCount, 2 ** $round);

                $slots = $this->buildKnockoutSlots($teamIds)[$round - 1] ?? [];
                for ($position = 1; $position <= $matchesInRound; $position++) {
                    $home = $slots[$position - 1][0] ?? null;
                    $away = $slots[$position - 1][1] ?? null;
                    ChampionshipMatch::create([
                        'championship_id' => $championship->id,
                        'matchday_id' => $matchday->id,
                        'home_team_id' => $home,
                        'away_team_id' => $away,
                        'round_number' => $round,
                        'fixture_order' => $position,
                        'phase' => 'knockout',
                        'bracket_round' => $round,
                        'bracket_position' => $position,
                        'duration_minutes' => 60,
                        'status' => 'scheduled',
                    ]);
                    $created++;
                }
            }

            return $created;
        });
    }

    /**
     * Framework-free bracket slots. Each round is a list of [home, away]
     * team IDs; later rounds use null placeholders until a winner advances.
     *
     * @return array<int, array<int, array{0:int|null,1:int|null}>>
     */
    public function buildKnockoutSlots(array $teamIds): array
    {
        $teamIds = array_values(array_filter(array_unique(array_map('intval', $teamIds)), static fn (int $id): bool => $id > 0));
        $count = count($teamIds);
        if ($count < 2 || ($count & ($count - 1)) !== 0) {
            return [];
        }
        $roundCount = (int) log($count, 2);
        $rounds = [];
        for ($round = 1; $round <= $roundCount; $round++) {
            $matches = intdiv($count, 2 ** $round);
            $slots = [];
            for ($position = 0; $position < $matches; $position++) {
                $slots[] = $round === 1
                    ? [$teamIds[$position * 2] ?? null, $teamIds[$position * 2 + 1] ?? null]
                    : [null, null];
            }
            $rounds[] = $slots;
        }
        return $rounds;
    }

    /** @return array<int, string> */
    private function knockoutRoundNames(int $teamCount): array
    {
        $names = [
            2 => 'Final',
            4 => 'Semifinales',
            8 => 'Cuartos de final',
            16 => 'Octavos de final',
            32 => 'Dieciseisavos de final',
        ];
        $result = [];
        $roundCount = (int) log($teamCount, 2);
        for ($round = 1; $round <= $roundCount; $round++) {
            $remainingTeams = intdiv($teamCount, 2 ** ($round - 1));
            $result[$round] = $names[$remainingTeams] ?? 'Llave de ' . $remainingTeams;
        }
        return $result;
    }

    /**
     * Build deterministic round-robin pairs using the circle method. The
     * returned structure is intentionally framework-free so it can be tested
     * without a database and reused by future web fixture editors.
     *
     * @return array<int, array<int, array{0:int,1:int}>>
     */
    public function buildRoundRobinPairs(array $teamIds, bool $doubleRoundRobin = false): array
    {
        $teamIds = array_values(array_filter(
            array_unique(array_map('intval', $teamIds)),
            static fn (int $id): bool => $id > 0
        ));
        if (count($teamIds) < 2) {
            return [];
        }

        $slots = $teamIds;
        if (count($slots) % 2 !== 0) {
            $slots[] = null;
        }

        $roundCount = count($slots) - 1;
        $singleLeg = [];
        $rotation = $slots;

        for ($round = 0; $round < $roundCount; $round++) {
            $pairs = [];
            $half = intdiv(count($rotation), 2);
            for ($index = 0; $index < $half; $index++) {
                $left = $rotation[$index];
                $right = $rotation[count($rotation) - 1 - $index];
                if ($left === null || $right === null) {
                    continue;
                }

                $home = $left;
                $away = $right;
                if (($round + $index) % 2 === 1) {
                    [$home, $away] = [$away, $home];
                }
                $pairs[] = [$home, $away];
            }
            $singleLeg[] = $pairs;

            $fixed = $rotation[0];
            $rotating = array_slice($rotation, 1);
            $last = array_pop($rotating);
            array_unshift($rotating, $last);
            $rotation = array_merge([$fixed], $rotating);
        }

        if (!$doubleRoundRobin) {
            return $singleLeg;
        }

        return array_merge(
            $singleLeg,
            array_map(
                static fn (array $pairs): array => array_map(
                    static fn (array $pair): array => [$pair[1], $pair[0]],
                    $pairs
                ),
                $singleLeg
            )
        );
    }
}
