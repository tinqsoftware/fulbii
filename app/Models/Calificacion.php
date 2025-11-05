<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Calificacion extends Model
{
    protected $table = 'calificaciones';
    protected $guarded = ['id'];

    protected $casts = [
        'es_autocalificacion' => 'boolean',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
    ];

    public function club()        { return $this->belongsTo(Club::class, 'club_id'); }
    public function calificador() { return $this->belongsTo(User::class, 'user_calificador_id'); }
    public function calificado()  { return $this->belongsTo(User::class, 'user_calificado_id'); }

    /** Solo visibles públicamente (no ocultadas/silenciadas/borradas). */
    public function scopePublicas($q)
    {
        return $q->whereNull('ocultada_por_calificado_at')
                 ->whereNull('silenciada_por_admin_at')
                 ->whereNull('deleted_at');
    }

    /** Filtrar por club */
    public function scopeDelClub($q, $clubId)
    {
        return $q->where('club_id', $clubId);
    }
}