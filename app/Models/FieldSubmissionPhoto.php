<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class FieldSubmissionPhoto extends Model
{
    protected $table = 'field_submission_photos';

    protected $guarded = ['id'];

    public function submission()
    {
        return $this->belongsTo(FieldSubmission::class, 'field_submission_id');
    }
}
