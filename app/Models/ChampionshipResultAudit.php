<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ChampionshipResultAudit extends Model
{
    protected $table = 'championship_result_audits';
    protected $guarded = ['id'];
    protected $casts = [
        'before_json' => 'array',
        'after_json' => 'array',
    ];

    public function match()
    {
        return $this->belongsTo(ChampionshipMatch::class, 'championship_match_id');
    }

    public function actor()
    {
        return $this->belongsTo(User::class, 'actor_user_id');
    }
}
