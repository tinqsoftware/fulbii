<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class HorarioAtencion extends Model
{
    use HasFactory;

    protected $connection = 'mysql';
    protected $table = 'horario_atencion';
    protected $guarded = ['id'];

    public function polideportivo()
    {
        return $this->belongsTo(Polideportivo::class, 'id_polideportivo');
    }
}
