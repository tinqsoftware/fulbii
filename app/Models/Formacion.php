<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Formacion extends Model
{
    use HasFactory;

    protected $connection = 'mysql';
    protected $table = 'formacion';
    protected $guarded = ['id'];

    public function posiciones()
    {
        return $this->hasMany(Posicion::class, 'id_formacion');
    }

    public function equipos()
    {
        return $this->hasMany(Equipos::class, 'id_formacion');
    }
}
