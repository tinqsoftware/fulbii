<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class UserPerfil extends Model
{
    use HasFactory;

    protected $connection = 'mysql';
    protected $table = 'user_perfil';
    protected $guarded = ['id'];

    public function user()
    {
        return $this->belongsTo(User::class, 'id_user');
    }

    public function perfil()
    {
        return $this->belongsTo(Perfil::class, 'id_perfil');
    }
}
