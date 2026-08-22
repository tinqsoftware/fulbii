<?php

namespace Tests\Unit\Services;

use App\Services\ChampionshipFixtureService;
use PHPUnit\Framework\TestCase;

class ChampionshipFixtureServiceTest extends TestCase
{
    public function test_single_round_robin_pairs_each_team_once(): void
    {
        $rounds = (new ChampionshipFixtureService())->buildRoundRobinPairs([1, 2, 3, 4]);

        $this->assertCount(3, $rounds);
        $pairs = array_merge(...$rounds);
        $this->assertCount(6, $pairs);

        $pairKeys = array_map(
            fn (array $pair) => implode('-', [min($pair), max($pair)]),
            $pairs
        );

        $this->assertCount(6, array_unique($pairKeys));
    }

    public function test_odd_team_count_skips_the_bye_and_double_round_reverses_home_away(): void
    {
        $service = new ChampionshipFixtureService();
        $single = $service->buildRoundRobinPairs([10, 20, 30, 40, 50]);
        $double = $service->buildRoundRobinPairs([10, 20, 30, 40, 50], true);

        $this->assertCount(5, $single);
        $singlePairs = array_merge(...$single);
        $doublePairs = array_merge(...$double);
        $this->assertCount(10, $singlePairs);
        $this->assertCount(20, $doublePairs);

        $firstLeg = array_map(fn (array $pair) => implode('-', $pair), $singlePairs);
        $secondLeg = array_map(fn (array $pair) => implode('-', $pair), array_merge(...array_slice($double, 5)));
        $reversedFirstLeg = array_map(
            fn (string $pair) => implode('-', array_reverse(explode('-', $pair))),
            $firstLeg
        );
        sort($reversedFirstLeg);
        sort($secondLeg);
        $this->assertSame(
            $reversedFirstLeg,
            $secondLeg
        );
    }

    public function test_invalid_or_duplicate_team_ids_are_removed(): void
    {
        $rounds = (new ChampionshipFixtureService())->buildRoundRobinPairs([3, 3, 0, 4]);

        $this->assertCount(1, $rounds);
        $this->assertCount(1, array_merge(...$rounds));
    }

    public function test_knockout_slots_create_power_of_two_rounds_and_empty_future_slots(): void
    {
        $rounds = (new ChampionshipFixtureService())->buildKnockoutSlots([1, 2, 3, 4]);

        $this->assertCount(2, $rounds);
        $this->assertSame([[1, 2], [3, 4]], $rounds[0]);
        $this->assertSame([[null, null]], $rounds[1]);
    }

    public function test_knockout_slots_reject_non_power_of_two_team_counts(): void
    {
        $this->assertSame([], (new ChampionshipFixtureService())->buildKnockoutSlots([1, 2, 3]));
    }
}
