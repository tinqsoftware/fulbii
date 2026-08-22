<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ChampionshipMatchday extends Model
{
    protected $table = 'championship_matchdays';
    protected $guarded = ['id'];
    protected $casts = [
        'match_date' => 'date',
        'starts_at' => 'datetime',
        'ends_at' => 'datetime',
        'number' => 'integer',
    ];

    public function championship()
    {
        return $this->belongsTo(Championship::class, 'championship_id');
    }

    public function matches()
    {
        return $this->hasMany(ChampionshipMatch::class, 'matchday_id')->orderBy('fixture_order');
    }
}
