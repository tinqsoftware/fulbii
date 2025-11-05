<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Polideportivo extends Model
{
    use HasFactory;

    protected $connection = 'mysql';
    protected $table = 'polideportivo';
    protected $guarded = ['id'];

    public function distrito()
    {
        return $this->belongsTo(Distritos::class, 'id_distrito');
    }

    public function canchas()
    {
        return $this->hasMany(Cancha::class, 'id_polideportivo');
    }

    public function horarios()
    {
        return $this->hasMany(HorarioAtencion::class, 'id_polideportivo');
    }

    public function serviciosDetalle()
    {
        return $this->hasMany(ServicioPolideportivoDetalle::class, 'id_polideportivo');
    }
}
