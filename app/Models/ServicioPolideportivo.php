<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

use Illuminate\Support\Facades\Crypt;

class ServicioPolideportivo extends Model
{
    use HasFactory;
    protected $connection = 'mysql';
    protected $table= 'servicio_polideportivo';
    protected $fillable = [
        'id',
    ];
}
