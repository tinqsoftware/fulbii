<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Goles extends Model
{
    use HasFactory;

    protected $connection = 'mysql';
    protected $table = 'goles';
    protected $guarded = ['id'];

    public function pichanga()
    {
        return $this->belongsTo(Pichanga::class, 'id_pichanga');
    }

    public function autor()
    {
        return $this->belongsTo(User::class, 'id_user_gol');
    }
}
