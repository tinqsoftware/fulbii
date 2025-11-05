<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class EventoUsuarios extends Model
{
    use HasFactory;

    protected $connection = 'mysql';
    protected $table = 'evento_usuarios';
    protected $guarded = ['id'];

    public function evento()
    {
        return $this->belongsTo(Evento::class, 'id_evento');
    }

    public function user()
    {
        return $this->belongsTo(User::class, 'id_user_asistente');
    }
}
