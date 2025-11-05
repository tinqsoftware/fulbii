<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Pichanga extends Model
{
    use HasFactory;

    protected $connection = 'mysql';
    protected $table = 'pichanga';
    protected $guarded = ['id'];

    public function evento()
    {
        return $this->belongsTo(Evento::class, 'id_evento');
    }

    public function equipo()
    {
        return $this->belongsTo(Equipos::class, 'id_equipo');
    }

    public function posicion()
    {
        return $this->belongsTo(Posicion::class, 'id_posicion');
    }

    public function asistente()
    {
        return $this->belongsTo(User::class, 'id_user_asistente');
    }

    public function goles()
    {
        return $this->hasMany(Goles::class, 'id_pichanga');
    }
}
