<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class GroupPichangaPost extends Model
{
    protected $table = 'group_pichanga_posts';

    protected $guarded = ['id'];

    public function pichanga()
    {
        return $this->belongsTo(GroupPichanga::class, 'pichanga_id');
    }

    public function user()
    {
        return $this->belongsTo(User::class, 'user_id');
    }

    public function comments()
    {
        return $this->hasMany(GroupPichangaComment::class, 'post_id');
    }
}
