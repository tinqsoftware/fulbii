<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Cancha;
use App\Models\FieldGeometry;
use App\Models\Polideportivo;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Schema;

class FieldGeometryController extends Controller
{
    public function upsert(Request $request, Polideportivo $field)
    {
        abort_unless(Schema::hasTable('field_geometries'), 501, 'field_geometries table is not available.');

        $user = $request->user() ?? abort(401);
        abort_unless((bool) $user->is_superadmin, 403);

        $data = $request->validate([
            'cancha_id' => ['nullable', 'integer', 'min:1'],
            'width_meters' => ['required', 'numeric', 'min:1', 'max:200'],
            'length_meters' => ['required', 'numeric', 'min:1', 'max:300'],
            'rotation_degrees' => ['nullable', 'numeric', 'min:-360', 'max:360'],
            'corners' => ['nullable', 'array', 'max:4'],
            'corners.*.lat' => ['required_with:corners', 'numeric', 'between:-90,90'],
            'corners.*.lng' => ['required_with:corners', 'numeric', 'between:-180,180'],
        ]);

        $canchaId = null;
        if (!empty($data['cancha_id'])) {
            $cancha = Cancha::query()
                ->where('id', (int) $data['cancha_id'])
                ->where('id_polideportivo', (int) $field->id)
                ->first();
            abort_if(!$cancha, 422, 'La cancha no pertenece al centro deportivo.');
            $canchaId = (int) $cancha->id;
        } else {
            $canchaId = (int) (Cancha::query()
                ->where('id_polideportivo', (int) $field->id)
                ->orderBy('id')
                ->value('id') ?? 0);
            abort_if($canchaId <= 0, 422, 'El centro deportivo no tiene canchas registradas.');
        }

        $geometry = FieldGeometry::updateOrCreate(
            ['cancha_id' => $canchaId],
            [
                'field_id' => (int) $field->id,
                'width_meters' => (float) $data['width_meters'],
                'length_meters' => (float) $data['length_meters'],
                'rotation_degrees' => (float) ($data['rotation_degrees'] ?? 0),
                'corners_json' => $data['corners'] ?? null,
            ]
        );

        return response()->json([
            'message' => 'Geometría actualizada.',
            'geometry' => $geometry,
        ]);
    }
}
