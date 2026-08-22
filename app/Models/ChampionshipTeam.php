<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ChampionshipTeam extends Model
{
    protected $table = 'championship_teams';
    protected $guarded = ['id'];

    public function championship()
    {
        return $this->belongsTo(Championship::class, 'championship_id');
    }

    public function captain()
    {
        return $this->belongsTo(User::class, 'captain_user_id');
    }

    public function members()
    {
        return $this->hasMany(ChampionshipTeamMember::class, 'championship_team_id');
    }

    public function invitations()
    {
        return $this->hasMany(ChampionshipTeamInvitation::class, 'championship_team_id');
    }

    public function homeMatches()
    {
        return $this->hasMany(ChampionshipMatch::class, 'home_team_id');
    }

    public function awayMatches()
    {
        return $this->hasMany(ChampionshipMatch::class, 'away_team_id');
    }
}
