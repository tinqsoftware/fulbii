<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ClubNotificationCategory extends Model
{
    public const CATEGORIES = ['pichangas', 'challenges', 'chat', 'requests', 'invitations', 'social'];

    protected $guarded = ['id'];

    protected $casts = ['is_enabled' => 'boolean'];
}
