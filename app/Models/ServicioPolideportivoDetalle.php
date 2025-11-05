<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class ServicioPolideportivoDetalle extends Model
{
    use HasFactory;

    protected $connection = 'mysql';
    protected $table = 'servicio_polideportivo_detalle';
    protected $guarded = ['id'];

    public function polideportivo()
    {
        return $this->belongsTo(Polideportivo::class, 'id_polideportivo');
    }
}
