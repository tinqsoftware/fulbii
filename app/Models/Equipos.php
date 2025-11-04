<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

use Illuminate\Support\Facades\Crypt;

class Equipos extends Model
{
    use HasFactory;
    protected $connection = 'mysql';
    protected $table= 'equipos';
    protected $fillable = [
        'id',
    ];
}
