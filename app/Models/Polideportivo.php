<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

use Illuminate\Support\Facades\Crypt;

class Polideportivo extends Model
{
    use HasFactory;
    protected $connection = 'mysql';
    protected $table= 'polideportivo';
    protected $fillable = [
        'id',
    ];
}
