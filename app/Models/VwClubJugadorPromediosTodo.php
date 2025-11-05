<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class VwClubJugadorPromediosTodo extends Model
{
    protected $table = 'vw_club_jugador_promedios_todo';
    public $timestamps = false;
    protected $primaryKey = null;
    public $incrementing = false;
    protected $guarded = [];

    public function user() { return $this->belongsTo(User::class, 'user_id'); }
    public function club() { return $this->belongsTo(Club::class, 'club_id'); }
}