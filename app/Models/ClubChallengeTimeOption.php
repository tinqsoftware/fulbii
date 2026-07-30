<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ClubChallengeTimeOption extends Model
{
    protected $table = 'club_challenge_time_options';

    protected $guarded = ['id'];

    protected $casts = [
        'starts_at' => 'datetime',
        'duration_minutes' => 'integer',
    ];

    public function challenge()
    {
        return $this->belongsTo(ClubChallenge::class, 'challenge_id');
    }

    public function proposedBy()
    {
        return $this->belongsTo(User::class, 'proposed_by_user_id');
    }
}

