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
        'name',
        'email',
        'password',
        'nick',
        'sexo',
        'fec_nac',
        'altura_cm',
        'avatar_url',
        'auth_provider',
        'provider_uid',
        'suspended_until',
        'suspension_reason',
    ];

    protected $hidden = [
        'password','remember_token',
    ];

    protected $casts = [
        'email_verified_at' => 'datetime',
        'password' => 'hashed',
        'fec_nac' => 'date',
        'altura_cm' => 'integer',
        'suspended_until' => 'datetime',
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

    public function groupNotificationPrefs()
    {
        return $this->hasMany(UserGroupNotificationPref::class, 'user_id');
    }

    public function isPushMutedInClub(int $clubId): bool
    {
        $pref = $this->groupNotificationPrefs()
            ->where('club_id', $clubId)
            ->first();

        return $pref ? $pref->isMuted() : false;
    }

    public function createdGroupPichangas()
    {
        return $this->hasMany(GroupPichanga::class, 'created_by_user_id');
    }

    public function devices()
    {
        return $this->hasMany(UserDevice::class, 'user_id');
    }

    public function pushNotifications()
    {
        return $this->hasMany(PushNotification::class, 'user_id');
    }

    public function reports()
    {
        return $this->hasMany(Report::class, 'reporter_user_id');
    }

    public function strikes()
    {
        return $this->hasMany(Strike::class, 'user_id');
    }

    public function favoriteFields()
    {
        return $this->hasMany(UserFavoriteField::class, 'user_id');
    }

    public function pichangaPosts()
    {
        return $this->hasMany(GroupPichangaPost::class, 'user_id');
    }

    public function pichangaRatingsGiven()
    {
        return $this->hasMany(GroupPichangaRating::class, 'rater_user_id');
    }

    public function pichangaRatingsReceived()
    {
        return $this->hasMany(GroupPichangaRating::class, 'rated_user_id');
    }

    public function createdChallenges()
    {
        return $this->hasMany(ClubChallenge::class, 'created_by_user_id');
    }

    public function challengeMessages()
    {
        return $this->hasMany(ClubChallengeMessage::class, 'sender_user_id');
    }

    public function chatPresence()
    {
        return $this->hasOne(UserChatPresence::class, 'user_id');
    }

    public function profileClips()
    {
        return $this->hasMany(UserProfileClip::class, 'user_id');
    }

    public function isSuspended(): bool
    {
        return $this->suspended_until && $this->suspended_until->isFuture();
    }

    public function hasProfile(string $profileName): bool
    {
        if ($this->relationLoaded('perfiles')) {
            return $this->perfiles->contains(
                fn ($perfil) => strcasecmp((string) $perfil->nombre, $profileName) === 0
            );
        }

        return $this->perfiles()
            ->whereRaw('LOWER(nombre) = ?', [mb_strtolower($profileName)])
            ->exists();
    }

    /** Helpers */
    public function getIsSuperadminAttribute(): bool
    {
        return $this->hasProfile('superadmin');
    }

    public function getIsStaffAdminAttribute(): bool
    {
        return $this->hasProfile('staff_admin');
    }

    public function canAccessBackoffice(): bool
    {
        return $this->is_superadmin || $this->is_staff_admin;
    }

    public function canPerformCriticalAdminActions(): bool
    {
        return $this->is_superadmin;
    }

    protected $appends = ['is_superadmin', 'is_staff_admin'];
}
