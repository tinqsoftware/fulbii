<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ChampionshipMatch extends Model
{
    protected $table = 'championship_matches';
    protected $guarded = ['id'];
    protected $casts = [
        'starts_at' => 'datetime',
        'ends_at' => 'datetime',
        'duration_minutes' => 'integer',
        'round_number' => 'integer',
        'fixture_order' => 'integer',
        'bracket_round' => 'integer',
        'bracket_position' => 'integer',
        'home_score' => 'integer',
        'away_score' => 'integer',
        'result_confirmed_at' => 'datetime',
    ];

    public function championship()
    {
        return $this->belongsTo(Championship::class, 'championship_id');
    }

    public function pichanga()
    {
        return $this->belongsTo(GroupPichanga::class, 'pichanga_id');
    }

    public function matchday()
    {
        return $this->belongsTo(ChampionshipMatchday::class, 'matchday_id');
    }

    public function homeTeam()
    {
        return $this->belongsTo(ChampionshipTeam::class, 'home_team_id');
    }

    public function awayTeam()
    {
        return $this->belongsTo(ChampionshipTeam::class, 'away_team_id');
    }

    public function squads()
    {
        return $this->hasMany(ChampionshipMatchSquad::class, 'championship_match_id');
    }

    public function events()
    {
        return $this->hasMany(ChampionshipMatchEvent::class, 'championship_match_id');
    }

    public function resultAudits()
    {
        return $this->hasMany(ChampionshipResultAudit::class, 'championship_match_id');
    }
}
