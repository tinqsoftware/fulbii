<?php

namespace Tests\Unit\Services;

use App\Services\CombinedSkillRatingService;
use Tests\TestCase;

class CombinedSkillRatingServiceTest extends TestCase
{
    public function test_goalkeeper_score_is_primary_when_it_is_higher_than_field_average(): void
    {
        $summary = app(CombinedSkillRatingService::class)->deriveSummary([
            'votos' => 1,
            'fisico' => 3.1,
            'arquero' => 3.2,
            'delantero' => 3.0,
            'mediocampo' => 2.9,
            'defensa' => 3.0,
        ]);

        $this->assertSame(3.0, $summary['player_average']);
        $this->assertSame(3.2, $summary['goalkeeper_average']);
        $this->assertSame(3.2, $summary['stars']);
        $this->assertSame('arquero', $summary['primary_role']);
    }

    public function test_field_average_is_primary_when_it_is_higher(): void
    {
        $summary = app(CombinedSkillRatingService::class)->deriveSummary([
            'votos' => 1,
            'fisico' => 3.1,
            'arquero' => 2.2,
            'delantero' => 3.0,
            'mediocampo' => 2.9,
            'defensa' => 3.0,
        ]);

        $this->assertSame(3.0, $summary['player_average']);
        $this->assertSame(2.2, $summary['goalkeeper_average']);
        $this->assertSame(3.0, $summary['stars']);
        $this->assertSame('jugador', $summary['primary_role']);
    }

    public function test_field_average_wins_ties_with_goalkeeper_score(): void
    {
        $summary = app(CombinedSkillRatingService::class)->deriveSummary([
            'votos' => 1,
            'fisico' => 3.0,
            'arquero' => 3.0,
            'delantero' => 3.0,
            'mediocampo' => 3.0,
            'defensa' => 3.0,
        ]);

        $this->assertSame(3.0, $summary['stars']);
        $this->assertSame('jugador', $summary['primary_role']);
    }

    public function test_partial_field_categories_are_averaged_from_the_available_scores(): void
    {
        $summary = app(CombinedSkillRatingService::class)->deriveSummary([
            'votos' => 1,
            'fisico' => 4.0,
            'arquero' => null,
            'delantero' => 3.0,
            'mediocampo' => null,
            'defensa' => null,
        ]);

        $this->assertSame(3.5, $summary['player_average']);
        $this->assertSame(3.5, $summary['stars']);
        $this->assertSame('jugador', $summary['primary_role']);
    }
}
