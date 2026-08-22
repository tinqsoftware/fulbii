<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ChampionshipPlayerStat extends Model
{
    protected $table = 'championship_player_stats';
    protected $guarded = ['id'];
    protected $casts = [
        'matches_played' => 'integer',
        'minutes_played' => 'integer',
        'goals' => 'integer',
        'assists' => 'integer',
        'goals_conceded' => 'integer',
        'clean_sheets' => 'integer',
        'yellow_cards' => 'integer',
        'red_cards' => 'integer',
    ];

    public function championship()
    {
        return $this->belongsTo(Championship::class, 'championship_id');
    }

    public function user()
    {
        return $this->belongsTo(User::class, 'user_id');
    }

    public function currentTeam()
    {
        return $this->belongsTo(ChampionshipTeam::class, 'current_team_id');
    }
}
