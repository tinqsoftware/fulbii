<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class GroupPichangaParticipant extends Model
{
    protected $table = 'group_pichanga_participants';

    protected $guarded = ['id'];

    protected $casts = [
        'confirmed_at' => 'datetime',
        'withdrawn_at' => 'datetime',
        'team_slot' => 'integer',
        'formation_order' => 'integer',
    ];

    public function pichanga()
    {
        return $this->belongsTo(GroupPichanga::class, 'pichanga_id');
    }

    public function user()
    {
        return $this->belongsTo(User::class, 'user_id');
    }
}
