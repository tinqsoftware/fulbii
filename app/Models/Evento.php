<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Evento extends Model
{
    use HasFactory;

    protected $connection = 'mysql';
    protected $table = 'evento';
    protected $guarded = ['id'];

    public function cancha()
    {
        return $this->belongsTo(Cancha::class, 'id_cancha');
    }

    public function asistentes()
    {
        return $this->hasMany(EventoUsuarios::class, 'id_evento');
    }

    public function pichangas()
    {
        return $this->hasMany(Pichanga::class, 'id_evento');
    }
}
