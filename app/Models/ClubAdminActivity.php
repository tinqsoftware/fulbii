<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ClubAdminActivity extends Model
{
    protected $guarded = ['id'];
    protected $casts = ['meta_json' => 'array'];

    public function actor()
    {
        return $this->belongsTo(User::class, 'actor_user_id');
    }

    public function target()
    {
        return $this->belongsTo(User::class, 'target_user_id');
    }
}
