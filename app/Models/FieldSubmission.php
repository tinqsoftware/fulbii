<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class FieldSubmission extends Model
{
    protected $table = 'field_submissions';

    protected $guarded = ['id'];

    protected $casts = [
        'wsp' => 'boolean',
        'reviewed_at' => 'datetime',
        'metadata_json' => 'array',
        'existing_polideportivo_id' => 'integer',
        'approved_polideportivo_id' => 'integer',
        'approved_cancha_id' => 'integer',
    ];

    public function user()
    {
        return $this->belongsTo(User::class, 'user_id');
    }

    public function photos()
    {
        return $this->hasMany(FieldSubmissionPhoto::class, 'field_submission_id');
    }

    public function existingPolideportivo()
    {
        return $this->belongsTo(Polideportivo::class, 'existing_polideportivo_id');
    }

    public function approvedPolideportivo()
    {
        return $this->belongsTo(Polideportivo::class, 'approved_polideportivo_id');
    }

    public function approvedCancha()
    {
        return $this->belongsTo(Cancha::class, 'approved_cancha_id');
    }
}
