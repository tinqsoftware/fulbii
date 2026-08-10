<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class UserBlock extends Model
{
    protected $guarded = ['id'];

    public function blocked()
    {
        return $this->belongsTo(User::class, 'blocked_user_id');
    }
}
