<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    use HasApiTokens, HasFactory, Notifiable;

    protected $fillable = [
        'name','email','password', 'nick',
    ];

    protected $hidden = [
        'password','remember_token',
    ];

    protected $casts = [
        'email_verified_at' => 'datetime',
        'password' => 'hashed',
    ];

    /** ---------------------------
     *  Relaciones
     *  --------------------------*/
    public function perfiles()
    {
        return $this->belongsToMany(Perfil::class, 'user_perfil', 'id_user', 'id_perfil')->withTimestamps();
    }

    public function clubs()
    {
        return $this->belongsToMany(Club::class, 'club_user', 'user_id', 'club_id')
            ->withPivot(['rol','estado'])
            ->withTimestamps();
    }

    public function clubsAdmin()
    {
        return $this->clubs()->wherePivot('rol','admin');
    }

    public function calificacionesDadas()
    {
        return $this->hasMany(Calificacion::class, 'user_calificador_id');
    }

    public function calificacionesRecibidas()
    {
        return $this->hasMany(Calificacion::class, 'user_calificado_id');
    }

    public function goles()
    {
        return $this->hasMany(Goles::class, 'id_user_gol');
    }

    public function pichangasAsistente()
    {
        return $this->hasMany(Pichanga::class, 'id_user_asistente');
    }

    /** Helpers */
    public function getIsSuperadminAttribute(): bool
    {
        // Si no está cargado, hará 1 query; si ya está, usa colección en memoria
        return $this->perfiles()->where('nombre','superadmin')->exists();
    }

    protected $appends = ['is_superadmin'];
}
