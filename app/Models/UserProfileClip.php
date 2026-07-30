<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class UserProfileClip extends Model
{
    protected $table = 'user_profile_clips';

    protected $guarded = ['id'];

    protected $casts = [
        'user_id' => 'integer',
        'duration_ms' => 'integer',
        'width' => 'integer',
        'height' => 'integer',
        'has_audio' => 'boolean',
        'file_size_bytes' => 'integer',
        'sort_order' => 'integer',
    ];

    public function user()
    {
        return $this->belongsTo(User::class, 'user_id');
    }
}
