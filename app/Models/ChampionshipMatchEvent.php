<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ChampionshipMatchEvent extends Model
{
    protected $table = 'championship_match_events';
    protected $guarded = ['id'];
    protected $casts = ['minute' => 'integer', 'metadata_json' => 'array'];

    public function match()
    {
        return $this->belongsTo(ChampionshipMatch::class, 'championship_match_id');
    }

    public function player()
    {
        return $this->belongsTo(User::class, 'player_user_id');
    }

    public function secondaryPlayer()
    {
        return $this->belongsTo(User::class, 'secondary_player_user_id');
    }
}
