<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Equipos extends Model
{
    use HasFactory;

    protected $connection = 'mysql';
    protected $table = 'equipos';
    protected $guarded = ['id'];

    public function formacion()
    {
        return $this->belongsTo(Formacion::class, 'id_formacion');
    }

    public function pichangas()
    {
        return $this->hasMany(Pichanga::class, 'id_equipo');
    }
}
