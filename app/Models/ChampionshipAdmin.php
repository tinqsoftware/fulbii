<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ChampionshipAdmin extends Model
{
    protected $table = 'championship_admins';
    protected $guarded = ['id'];
    protected $casts = ['permissions_json' => 'array'];

    public function championship()
    {
        return $this->belongsTo(Championship::class, 'championship_id');
    }

    public function user()
    {
        return $this->belongsTo(User::class, 'user_id');
    }
}
