<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class UserChatPresence extends Model
{
    protected $table = 'user_chat_presence';

    protected $guarded = ['id'];

    protected $casts = [
        'is_active' => 'boolean',
        'last_heartbeat_at' => 'datetime',
    ];

    public function user()
    {
        return $this->belongsTo(User::class, 'user_id');
    }

    public function challenge()
    {
        return $this->belongsTo(ClubChallenge::class, 'challenge_id');
    }
}

