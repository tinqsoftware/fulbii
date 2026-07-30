<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class PushDispatchLog extends Model
{
    protected $table = 'push_dispatch_logs';

    protected $guarded = ['id'];

    protected $casts = [
        'sent_at' => 'datetime',
    ];

    public function notification()
    {
        return $this->belongsTo(PushNotification::class, 'push_notification_id');
    }

    public function device()
    {
        return $this->belongsTo(UserDevice::class, 'user_device_id');
    }
}
