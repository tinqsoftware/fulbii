<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class GroupPichangaWaitlistEntry extends Model
{
    protected $table = 'group_pichanga_waitlist';

    protected $guarded = ['id'];

    protected $casts = [
        'promoted_at' => 'datetime',
        'withdrawn_at' => 'datetime',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function pichanga()
    {
        return $this->belongsTo(GroupPichanga::class, 'pichanga_id');
    }
}
