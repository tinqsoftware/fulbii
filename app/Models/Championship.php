<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Championship extends Model
{
    protected $table = 'championships';

    protected $guarded = ['id'];

    protected $casts = [
        'double_round_robin' => 'boolean',
        'field_id' => 'integer',
        'points_win' => 'integer',
        'points_draw' => 'integer',
        'points_loss' => 'integer',
        'max_teams' => 'integer',
        'players_per_team' => 'integer',
        'format' => 'string',
        'registration_starts_at' => 'datetime',
        'registration_ends_at' => 'datetime',
        'starts_at' => 'datetime',
        'ends_at' => 'datetime',
        'settings_json' => 'array',
    ];

    public function creator()
    {
        return $this->belongsTo(User::class, 'created_by_user_id');
    }

    public function club()
    {
        return $this->belongsTo(Club::class, 'club_id');
    }

    public function clubs()
    {
        return $this->belongsToMany(Club::class, 'championship_clubs', 'championship_id', 'club_id')
            ->withTimestamps();
    }

    public function admins()
    {
        return $this->hasMany(ChampionshipAdmin::class, 'championship_id');
    }

    public function teams()
    {
        return $this->hasMany(ChampionshipTeam::class, 'championship_id')->orderBy('sort_order');
    }

    public function matchdays()
    {
        return $this->hasMany(ChampionshipMatchday::class, 'championship_id')->orderBy('number');
    }

    public function matches()
    {
        return $this->hasMany(ChampionshipMatch::class, 'championship_id');
    }

    public function playerStats()
    {
        return $this->hasMany(ChampionshipPlayerStat::class, 'championship_id');
    }

    public function venue()
    {
        return $this->belongsTo(Polideportivo::class, 'field_id');
    }
}
