<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class PushNotification extends Model
{
    protected $table = 'push_notifications';

    protected $guarded = ['id'];

    protected $casts = [
        'data_json' => 'array',
        'is_read' => 'boolean',
        'read_at' => 'datetime',
    ];

    public function scopeForDedupeKey($query, int $userId, string $dedupeKey)
    {
        return $query->where('user_id', $userId)->where('dedupe_key', $dedupeKey);
    }

    public function user()
    {
        return $this->belongsTo(User::class, 'user_id');
    }

    public function dispatchLogs()
    {
        return $this->hasMany(PushDispatchLog::class, 'push_notification_id');
    }
}
