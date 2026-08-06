<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\Schema;

class ClubUser extends Model
{
    protected $table = 'club_user';
    protected $guarded = ['id'];

    public function club() { return $this->belongsTo(Club::class, 'club_id'); }
    public function user() { return $this->belongsTo(User::class, 'user_id'); }

    /**
     * A current group membership is represented by estado = 1. Keeping this
     * scope tolerant of older schemas makes read-only compatibility paths safe.
     */
    public function scopeActive(Builder $query): Builder
    {
        if (!Schema::hasColumn($this->getTable(), 'estado')) {
            return $query;
        }

        return $query->where($this->getTable() . '.estado', 1);
    }
}
