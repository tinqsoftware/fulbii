<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class GroupPichanga extends Model
{
    protected $table = 'group_pichangas';

    protected $guarded = ['id'];

    protected $casts = [
        'starts_at' => 'datetime',
        'withdraw_until' => 'datetime',
        'last_renotify_at' => 'datetime',
        'auto_reminder_48h_sent_at' => 'datetime',
        'auto_reminder_24h_sent_at' => 'datetime',
        'is_open' => 'boolean',
        'allow_external_requests' => 'boolean',
        'auto_reminder_enabled' => 'boolean',
        'invited_link_enabled' => 'boolean',
        'notify_degree' => 'integer',
        'championship_id' => 'integer',
        'championship_match_id' => 'integer',
        'field_id' => 'integer',
        'cancha_id' => 'integer',
        'capacity' => 'integer',
        'team_count' => 'integer',
        'players_per_team' => 'integer',
        'duration_minutes' => 'integer',
        'renotify_sent_count' => 'integer',
        'rival_club_id' => 'integer',
        'challenge_id' => 'integer',
        'audience_age_min' => 'integer',
        'audience_age_max' => 'integer',
        'skill_fisico_min' => 'float',
        'skill_arquero_min' => 'float',
        'skill_delantero_min' => 'float',
        'skill_mediocampo_min' => 'float',
        'skill_defensa_min' => 'float',
    ];

    public function club()
    {
        return $this->belongsTo(Club::class, 'club_id');
    }

    public function rivalClub()
    {
        return $this->belongsTo(Club::class, 'rival_club_id');
    }

    public function creator()
    {
        return $this->belongsTo(User::class, 'created_by_user_id');
    }

    public function participants()
    {
        return $this->hasMany(GroupPichangaParticipant::class, 'pichanga_id');
    }

    public function waitlist()
    {
        return $this->hasMany(GroupPichangaWaitlistEntry::class, 'pichanga_id');
    }

    public function externalRequests()
    {
        return $this->hasMany(GroupPichangaExternalRequest::class, 'pichanga_id');
    }

    public function notificationBatches()
    {
        return $this->hasMany(GroupPichangaNotificationBatch::class, 'pichanga_id');
    }

    public function posts()
    {
        return $this->hasMany(GroupPichangaPost::class, 'pichanga_id');
    }

    public function ratings()
    {
        return $this->hasMany(GroupPichangaRating::class, 'pichanga_id');
    }

    public function challenge()
    {
        return $this->belongsTo(ClubChallenge::class, 'challenge_id');
    }

    public function championship()
    {
        return $this->belongsTo(Championship::class, 'championship_id');
    }

    public function championshipMatch()
    {
        return $this->belongsTo(ChampionshipMatch::class, 'championship_match_id');
    }
}
