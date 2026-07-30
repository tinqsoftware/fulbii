<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class GroupPichangaExternalRequest extends Model
{
    protected $table = 'group_pichanga_external_requests';

    protected $guarded = ['id'];

    protected $casts = [
        'requested_at' => 'datetime',
        'decided_at' => 'datetime',
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
