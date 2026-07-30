<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class GroupPichangaComment extends Model
{
    protected $table = 'group_pichanga_comments';

    protected $guarded = ['id'];

    public function post()
    {
        return $this->belongsTo(GroupPichangaPost::class, 'post_id');
    }

    public function pichanga()
    {
        return $this->belongsTo(GroupPichanga::class, 'pichanga_id');
    }

    public function user()
    {
        return $this->belongsTo(User::class, 'user_id');
    }
}
