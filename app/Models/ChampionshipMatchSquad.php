<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ChampionshipMatchSquad extends Model
{
    protected $table = 'championship_match_squads';
    protected $guarded = ['id'];
    protected $casts = ['minutes_played' => 'integer'];

    public function match()
    {
        return $this->belongsTo(ChampionshipMatch::class, 'championship_match_id');
    }

    public function team()
    {
        return $this->belongsTo(ChampionshipTeam::class, 'championship_team_id');
    }

    public function user()
    {
        return $this->belongsTo(User::class, 'user_id');
    }
}
