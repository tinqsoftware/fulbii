<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class HistorialCalificacion extends Model
{
    use HasFactory;

    protected $connection = 'mysql';
    protected $table = 'historial_calificacion';
    protected $guarded = ['id'];

    public function jugador()
    {
        return $this->belongsTo(User::class, 'id_user_jugador');
    }

    public function creador()
    {
        return $this->belongsTo(User::class, 'id_user_create');
    }

    public function pichanga()
    {
        return $this->belongsTo(Pichanga::class, 'id_pichanga');
    }
}
