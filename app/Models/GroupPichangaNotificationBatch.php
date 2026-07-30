<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class GroupPichangaNotificationBatch extends Model
{
    protected $table = 'group_pichanga_notification_batches';

    protected $guarded = ['id'];

    protected $casts = [
        'filters_json' => 'array',
    ];

    public function pichanga()
    {
        return $this->belongsTo(GroupPichanga::class, 'pichanga_id');
    }

    public function triggeredBy()
    {
        return $this->belongsTo(User::class, 'triggered_by_user_id');
    }
}
