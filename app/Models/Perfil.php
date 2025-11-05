<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Perfil extends Model
{
    use HasFactory;

    protected $connection = 'mysql';
    protected $table = 'perfil';
    protected $guarded = ['id'];

    public function usuarios()
    {
        return $this->belongsToMany(User::class, 'user_perfil', 'id_perfil', 'id_user')->withTimestamps();
    }

    public function userPerfiles()
    {
        return $this->hasMany(UserPerfil::class, 'id_perfil');
    }
}
