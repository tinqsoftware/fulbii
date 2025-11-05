<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Pais extends Model
{
    use HasFactory;

    protected $connection = 'mysql';
    protected $table = 'pais';
    protected $guarded = ['id'];

    public function regiones()
    {
        return $this->hasMany(Region::class, 'id_pais');
    }
}
