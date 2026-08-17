<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Cancha;
use App\Models\Polideportivo;
use App\Services\AdminAccessService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Schema;
use Illuminate\Validation\Rule;

class AdminFieldManagementController extends Controller
{
    public function __construct(private readonly AdminAccessService $adminAccess)
    {
    }

    public function updateField(Request $request, Polideportivo $field)
    {
        $this->adminAccess->ensureSuper($request->user());
        $data = $request->validate([
            'nombre' => ['required', 'string', 'max:250'],
            'direccion' => ['nullable', 'string', 'max:255'],
            'descripcion' => ['nullable', 'string', 'max:300'],
            'celular' => ['nullable', 'string', 'max:20'],
            'wsp' => ['nullable', 'boolean'],
            'precio_desde' => ['nullable', 'string', 'max:10'],
            'id_distrito' => ['nullable', 'integer', 'min:1'],
        ]);

        if (Schema::hasColumn('polideportivo', 'precio_desde_num')) {
            $data['precio_desde_num'] = is_numeric($data['precio_desde'] ?? null)
                ? (float) $data['precio_desde']
                : null;
        }
        $field->update($data);

        return response()->json(['message' => 'Polideportivo actualizado.', 'field_id' => (int) $field->id]);
    }

    public function updateCourt(Request $request, Cancha $cancha)
    {
        $this->adminAccess->ensureSuper($request->user());
        $data = $request->validate([
            'nombre' => ['required', 'string', 'max:250'],
            'equiposvs' => ['nullable', Rule::in(['5', '6', '7', '8', '9', '11'])],
            'tipo_superficie' => ['nullable', Rule::in(['losa', 'sintetico', 'natural'])],
            'anchom2' => ['nullable', 'numeric', 'min:1', 'max:200'],
            'largom2' => ['nullable', 'numeric', 'min:1', 'max:300'],
        ]);
        if (array_key_exists('equiposvs', $data) && Schema::hasColumn('cancha', 'formato_vs')) {
            $data['formato_vs'] = empty($data['equiposvs']) ? null : $data['equiposvs'] . 'v' . $data['equiposvs'];
        }
        $cancha->update($data);

        return response()->json(['message' => 'Cancha actualizada.', 'cancha_id' => (int) $cancha->id]);
    }
}
