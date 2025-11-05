<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Distritos extends Model
{
    use HasFactory;

    protected $connection = 'mysql';
    protected $table = 'distritos';
    protected $guarded = ['id'];

    public function provincia()
    {
        return $this->belongsTo(Provincia::class, 'id_provincia');
    }

    public function polideportivos()
    {
        return $this->hasMany(Polideportivo::class, 'id_distrito');
    }
}
