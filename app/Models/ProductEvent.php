<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ProductEvent extends Model
{
    protected $table = 'product_events';

    protected $guarded = ['id'];

    protected $casts = [
        'metadata_json' => 'array',
        'happened_at' => 'datetime',
    ];
}

