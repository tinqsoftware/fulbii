<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ClubChallengeConfiguration extends Model
{
    protected $table = 'club_challenge_configurations';

    protected $guarded = ['id'];

    protected $casts = [
        'accepted_by_challenger_at' => 'datetime',
        'accepted_by_challenged_at' => 'datetime',
    ];

    public function challenge()
    {
        return $this->belongsTo(ClubChallenge::class, 'challenge_id');
    }

    public function proposedBy()
    {
        return $this->belongsTo(User::class, 'proposed_by_user_id');
    }

    public function fieldOption()
    {
        return $this->belongsTo(ClubChallengeFieldOption::class, 'field_option_id');
    }

    public function timeOption()
    {
        return $this->belongsTo(ClubChallengeTimeOption::class, 'time_option_id');
    }
}

