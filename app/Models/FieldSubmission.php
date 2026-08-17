<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class FieldSubmission extends Model
{
    protected $table = 'field_submissions';

    protected $fillable = [
        'user_id',
        'status',
        'submission_type',
        'nombre',
        'direccion',
        'x',
        'y',
        'celular',
        'wsp',
        'id_distrito',
        'descripcion',
        'precio_desde',
        'source_type',
        'metadata_json',
        'existing_polideportivo_id',
        'cancha_nombre',
        'cancha_equiposvs',
        'cancha_tipo_superficie',
        'cancha_anchom2',
        'cancha_largom2',
        'reviewed_by_user_id',
        'reviewed_at',
        'approved_polideportivo_id',
        'approved_cancha_id',
        'resolution_note',
    ];

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

    public function reviewer()
    {
        return $this->belongsTo(User::class, 'reviewed_by_user_id');
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
