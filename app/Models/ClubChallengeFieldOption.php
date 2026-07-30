<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ClubChallengeFieldOption extends Model
{
    protected $table = 'club_challenge_field_options';

    protected $guarded = ['id'];

    protected $casts = [
        'latitude' => 'float',
        'longitude' => 'float',
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

