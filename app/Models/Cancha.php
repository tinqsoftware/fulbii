<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Cancha extends Model
{
    use HasFactory;

    protected $connection = 'mysql';
    protected $table = 'cancha';
    protected $guarded = ['id'];

    public function polideportivo()
    {
        return $this->belongsTo(Polideportivo::class, 'id_polideportivo');
    }

    public function eventos()
    {
        return $this->hasMany(Evento::class, 'id_cancha');
    }
}
