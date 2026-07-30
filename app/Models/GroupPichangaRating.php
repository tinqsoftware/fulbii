<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class GroupPichangaRating extends Model
{
    protected $table = 'group_pichanga_ratings';

    protected $guarded = ['id'];

    protected $casts = [
        'fisico' => 'float',
        'arquero' => 'float',
        'delantero' => 'float',
        'mediocampo' => 'float',
        'defensa' => 'float',
    ];

    public function pichanga()
    {
        return $this->belongsTo(GroupPichanga::class, 'pichanga_id');
    }

    public function rater()
    {
        return $this->belongsTo(User::class, 'rater_user_id');
    }

    public function rated()
    {
        return $this->belongsTo(User::class, 'rated_user_id');
    }
}
