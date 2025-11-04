<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

use Illuminate\Support\Facades\Crypt;

class HistorialCalificacion extends Model
{
    use HasFactory;
    protected $connection = 'mysql';
    protected $table= 'historial_calificacion';
    protected $fillable = [
        'id',
    ];
}
