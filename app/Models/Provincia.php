<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Provincia extends Model
{
    use HasFactory;

    protected $connection = 'mysql';
    protected $table = 'provincia';
    protected $guarded = ['id'];

    public function region()
    {
        return $this->belongsTo(Region::class, 'id_region');
    }

    public function distritos()
    {
        return $this->hasMany(Distritos::class, 'id_provincia');
    }
}
