<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class WatchMatchEvent extends Model
{
    protected $table = 'watch_match_events';

    protected $guarded = ['id'];

    protected $casts = [
        'session_id' => 'integer',
        'event_at' => 'datetime',
        'minute' => 'integer',
        'metadata_json' => 'array',
    ];
}
