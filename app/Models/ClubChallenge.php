<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ClubChallenge extends Model
{
    protected $table = 'club_challenges';

    protected $guarded = ['id'];

    protected $casts = [
        'team_size' => 'integer',
        'expires_at' => 'datetime',
        'confirmed_at' => 'datetime',
    ];

    public function challengerClub()
    {
        return $this->belongsTo(Club::class, 'challenger_club_id');
    }

    public function challengedClub()
    {
        return $this->belongsTo(Club::class, 'challenged_club_id');
    }

    public function creator()
    {
        return $this->belongsTo(User::class, 'created_by_user_id');
    }

    public function coordinatorChallenger()
    {
        return $this->belongsTo(User::class, 'coordinator_challenger_user_id');
    }

    public function coordinatorChallenged()
    {
        return $this->belongsTo(User::class, 'coordinator_challenged_user_id');
    }

    public function confirmedPichanga()
    {
        return $this->belongsTo(GroupPichanga::class, 'confirmed_pichanga_id');
    }

    public function messages()
    {
        return $this->hasMany(ClubChallengeMessage::class, 'challenge_id');
    }

    public function fieldOptions()
    {
        return $this->hasMany(ClubChallengeFieldOption::class, 'challenge_id');
    }

    public function timeOptions()
    {
        return $this->hasMany(ClubChallengeTimeOption::class, 'challenge_id');
    }

    public function configurations()
    {
        return $this->hasMany(ClubChallengeConfiguration::class, 'challenge_id');
    }
}

