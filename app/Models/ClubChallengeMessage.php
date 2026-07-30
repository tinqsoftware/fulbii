<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ClubChallengeMessage extends Model
{
    protected $table = 'club_challenge_messages';

    protected $guarded = ['id'];

    protected $casts = [
        'metadata_json' => 'array',
    ];

    public function challenge()
    {
        return $this->belongsTo(ClubChallenge::class, 'challenge_id');
    }

    public function sender()
    {
        return $this->belongsTo(User::class, 'sender_user_id');
    }
}

