<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ChampionshipTeamInvitation extends Model
{
    protected $table = 'championship_team_invitations';
    protected $guarded = ['id'];
    protected $casts = ['expires_at' => 'datetime', 'responded_at' => 'datetime'];

    public function championship()
    {
        return $this->belongsTo(Championship::class, 'championship_id');
    }

    public function team()
    {
        return $this->belongsTo(ChampionshipTeam::class, 'championship_team_id');
    }

    public function invitedUser()
    {
        return $this->belongsTo(User::class, 'invited_user_id');
    }

    public function inviter()
    {
        return $this->belongsTo(User::class, 'invited_by_user_id');
    }
}
