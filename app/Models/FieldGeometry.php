<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class FieldGeometry extends Model
{
    protected $table = 'field_geometries';

    protected $guarded = ['id'];

    protected $casts = [
        'cancha_id' => 'integer',
        'field_id' => 'integer',
        'width_meters' => 'float',
        'length_meters' => 'float',
        'rotation_degrees' => 'float',
        'corners_json' => 'array',
    ];
}
