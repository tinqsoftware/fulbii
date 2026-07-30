<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class Club extends Model
{
    use HasFactory;

    protected $table = 'clubs';
    protected $guarded = ['id'];
    protected $casts = [
        'is_visible' => 'boolean',
        'link_join_enabled' => 'boolean',
        'auto_reminder_enabled' => 'boolean',
        'auto_reminder_48h_enabled' => 'boolean',
        'auto_reminder_24h_enabled' => 'boolean',
        'renotify_cooldown_minutes' => 'integer',
        'renotify_max_per_pichanga' => 'integer',
        'audience_max_degree' => 'integer',
    ];

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

    public function notificationPrefs()
    {
        return $this->hasMany(UserGroupNotificationPref::class, 'club_id');
    }

    public function groupPichangas()
    {
        return $this->hasMany(GroupPichanga::class, 'club_id');
    }

    public function outgoingChallenges()
    {
        return $this->hasMany(ClubChallenge::class, 'challenger_club_id');
    }

    public function incomingChallenges()
    {
        return $this->hasMany(ClubChallenge::class, 'challenged_club_id');
    }
}
