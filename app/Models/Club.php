<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class Club extends Model
{
    use HasFactory;

    protected $table = 'clubs';
    protected $guarded = ['id'];

    public function miembros()
    {
        return $this->belongsToMany(User::class, 'club_user', 'club_id', 'user_id')
            ->withPivot(['rol','estado'])
            ->withTimestamps();
    }

    public function admins()
    {
        return $this->miembros()->wherePivot('rol','admin');
    }

    public function calificaciones()
    {
        return $this->hasMany(Calificacion::class, 'club_id');
    }
}