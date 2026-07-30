<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Strike extends Model
{
    protected $table = 'strikes';

    protected $guarded = ['id'];

    protected $casts = [
        'expires_at' => 'datetime',
        'revoked_at' => 'datetime',
    ];

    public function user()
    {
        return $this->belongsTo(User::class, 'user_id');
    }

    public function report()
    {
        return $this->belongsTo(Report::class, 'report_id');
    }
}
