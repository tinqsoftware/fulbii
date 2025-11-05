<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ClubInvitation extends Model
{
    protected $table = 'club_invitations';
    protected $guarded = ['id'];

    public function club()       { return $this->belongsTo(Club::class, 'club_id'); }
    public function invitedUser(){ return $this->belongsTo(User::class, 'invited_user_id'); }
    public function invitedBy()  { return $this->belongsTo(User::class, 'invited_by_user_id'); }
}