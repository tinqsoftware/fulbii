<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Region extends Model
{
    use HasFactory;

    protected $connection = 'mysql';
    protected $table = 'region';
    protected $guarded = ['id'];

    public function pais()
    {
        return $this->belongsTo(Pais::class, 'id_pais');
    }

    public function provincias()
    {
        return $this->hasMany(Provincia::class, 'id_region');
    }
}
