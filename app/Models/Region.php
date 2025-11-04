<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

use Illuminate\Support\Facades\Crypt;

class Region extends Model
{
    use HasFactory;
    protected $connection = 'mysql';
    protected $table= 'region';
    protected $fillable = [
        'id',
    ];
}
