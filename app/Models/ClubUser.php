<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ClubUser extends Model
{
    protected $table = 'club_user';
    protected $guarded = ['id'];

    public function club() { return $this->belongsTo(Club::class, 'club_id'); }
    public function user() { return $this->belongsTo(User::class, 'user_id'); }
}