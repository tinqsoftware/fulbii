<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ChampionshipTeamMember extends Model
{
    protected $table = 'championship_team_members';
    protected $guarded = ['id'];
    protected $casts = ['joined_at' => 'datetime', 'removed_at' => 'datetime'];

    public function team()
    {
        return $this->belongsTo(ChampionshipTeam::class, 'championship_team_id');
    }

    public function user()
    {
        return $this->belongsTo(User::class, 'user_id');
    }

    public function inviter()
    {
        return $this->belongsTo(User::class, 'invited_by_user_id');
    }
}
