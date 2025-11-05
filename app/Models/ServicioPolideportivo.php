<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class ServicioPolideportivo extends Model
{
    use HasFactory;

    protected $connection = 'mysql';
    protected $table = 'servicio_polideportivo';
    protected $guarded = ['id'];

    public function detalles()
    {
        return $this->hasMany(ServicioPolideportivoDetalle::class, 'id_servicio'); // si tuvieras columna id_servicio
    }
}
