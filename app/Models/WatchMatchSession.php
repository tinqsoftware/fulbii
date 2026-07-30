<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class WatchMatchSession extends Model
{
    protected $table = 'watch_match_sessions';

    protected $guarded = ['id'];

    protected $casts = [
        'user_id' => 'integer',
        'group_pichanga_id' => 'integer',
        'field_id' => 'integer',
        'cancha_id' => 'integer',
        'field_geometry_id' => 'integer',
        'start_time' => 'datetime',
        'end_time' => 'datetime',
        'device' => 'string',
        'source' => 'string',
        'distance_meters' => 'float',
        'distance_meters_raw' => 'float',
        'distance_meters_filtered' => 'float',
        'device_payload_json' => 'array',
    ];
}
