<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Report extends Model
{
    protected $table = 'reports';

    protected $fillable = [
        'reporter_user_id',
        'target_type',
        'target_id',
        'content_type',
        'content_id',
        'reason_code',
        'description',
        'status',
        'resolved_by_user_id',
        'resolved_at',
        'resolution_note',
    ];

    protected $casts = [
        'resolved_at' => 'datetime',
    ];

    public function reporter()
    {
        return $this->belongsTo(User::class, 'reporter_user_id');
    }
}
