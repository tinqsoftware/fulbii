<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class WatchPositionSample extends Model
{
    protected $table = 'watch_position_samples';

    protected $guarded = ['id'];

    protected $casts = [
        'session_id' => 'integer',
        'sampled_at' => 'datetime',
        'lat' => 'float',
        'lng' => 'float',
        'horizontal_accuracy' => 'float',
        'speed' => 'float',
        'quality_flag' => 'string',
    ];
}
