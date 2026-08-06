<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Polideportivo;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Schema;

class FieldApiController extends Controller
{
    public function nearby(Request $request)
    {
        $data = $request->validate([
            'lat' => ['required', 'numeric', 'between:-90,90'],
            'lng' => ['required', 'numeric', 'between:-180,180'],
            'radius_m' => ['nullable', 'integer', 'min:50', 'max:2000'],
            'limit' => ['nullable', 'integer', 'min:1', 'max:10'],
        ]);
        $radius = (int) ($data['radius_m'] ?? 250);
        $limit = (int) ($data['limit'] ?? 5);
        $lat = (float) $data['lat'];
        $lng = (float) $data['lng'];
        $distance = '(6371000 * acos(least(1, cos(radians(?)) * cos(radians(CAST(x AS DECIMAL(10,6)))) * cos(radians(CAST(y AS DECIMAL(10,6))) - radians(?)) + sin(radians(?)) * sin(radians(CAST(x AS DECIMAL(10,6)))))))';
        $items = Polideportivo::query()
            ->select(['id', 'nombre', 'direccion', 'x', 'y', 'url_foto'])
            ->selectRaw("{$distance} as distance_m", [$lat, $lng, $lat])
            ->whereNotNull('x')->whereNotNull('y')
            ->having('distance_m', '<=', $radius)
            ->orderBy('distance_m')->limit($limit)->get()
            ->map(fn (Polideportivo $field) => [
                'id' => $field->id, 'nombre' => $field->nombre, 'direccion' => $field->direccion,
                'x' => (float) $field->x, 'y' => (float) $field->y, 'url_foto' => $field->url_foto,
                'distance_m' => (int) round($field->distance_m),
            ])->values();
        return response()->json(['items' => $items]);
    }

    public function index(Request $request)
    {
        $q = trim((string) $request->query('q', ''));
        $limit = max(1, min(500, (int) $request->query('limit', 200)));
        $priceMin = $this->parseDecimalQuery($request->query('price_min'));
        $priceMax = $this->parseDecimalQuery($request->query('price_max'));
        $surfaceTypes = $this->parseCsv($request->query('surface_types'));
        $vsFormats = $this->parseCsv($request->query('vs_formats'));

        $hasPrecioDesdeNum = Schema::hasColumn('polideportivo', 'precio_desde_num');
        $hasTipoSuperficie = Schema::hasColumn('cancha', 'tipo_superficie');
        $hasFormatoVs = Schema::hasColumn('cancha', 'formato_vs');
        $hasEquiposVs = Schema::hasColumn('cancha', 'equiposvs');

        $query = Polideportivo::query()
            ->select([
                'id',
                'nombre',
                'direccion',
                'x',
                'y',
                'descripcion',
                'precio_desde',
                'url_foto',
                'celular',
                'wsp',
                'id_distrito',
            ])
            ->withCount('canchas');

        if ($hasPrecioDesdeNum) {
            $query->addSelect('precio_desde_num');
        }

        if ($hasTipoSuperficie || $hasFormatoVs || $hasEquiposVs) {
            $query->with([
                'canchas' => function ($canchasQuery) use ($hasTipoSuperficie, $hasFormatoVs, $hasEquiposVs) {
                    $columns = ['id', 'id_polideportivo'];
                    if ($hasTipoSuperficie) {
                        $columns[] = 'tipo_superficie';
                    }
                    if ($hasFormatoVs) {
                        $columns[] = 'formato_vs';
                    }
                    if ($hasEquiposVs) {
                        $columns[] = 'equiposvs';
                    }
                    $canchasQuery->select($columns);
                },
            ]);
        }

        if ($q !== '') {
            $query->where(function ($where) use ($q) {
                $where->where('nombre', 'like', "%{$q}%")
                    ->orWhere('direccion', 'like', "%{$q}%")
                    ->orWhere('descripcion', 'like', "%{$q}%");
            });
        }

        if ($priceMin !== null) {
            if ($hasPrecioDesdeNum) {
                $query->whereNotNull('precio_desde_num')
                    ->where('precio_desde_num', '>=', $priceMin);
            } else {
                $query->whereRaw(
                    "CAST(REPLACE(REPLACE(REPLACE(REPLACE(COALESCE(precio_desde, ''), 'S/', ''), 's/', ''), ' ', ''), ',', '.') AS DECIMAL(10,2)) >= ?",
                    [$priceMin]
                );
            }
        }

        if ($priceMax !== null) {
            if ($hasPrecioDesdeNum) {
                $query->whereNotNull('precio_desde_num')
                    ->where('precio_desde_num', '<=', $priceMax);
            } else {
                $query->whereRaw(
                    "CAST(REPLACE(REPLACE(REPLACE(REPLACE(COALESCE(precio_desde, ''), 'S/', ''), 's/', ''), ' ', ''), ',', '.') AS DECIMAL(10,2)) <= ?",
                    [$priceMax]
                );
            }
        }

        if (
            (!empty($surfaceTypes) && $hasTipoSuperficie)
            || (!empty($vsFormats) && ($hasFormatoVs || $hasEquiposVs))
        ) {
            $capacities = collect($vsFormats)
                ->map(function (string $format): ?string {
                    $normalized = $this->normalizeFormat($format);
                    if ($normalized === null || !preg_match('/^(\d+)v\\1$/', $normalized, $matches)) {
                        return null;
                    }

                    return $matches[1];
                })
                ->filter()
                ->values()
                ->all();

            $normalizedFormats = collect($vsFormats)
                ->map(fn (string $format) => $this->normalizeFormat($format))
                ->filter()
                ->unique()
                ->values()
                ->all();

            // Surface and format filters must match the same court. Separate
            // whereHas clauses would incorrectly match two different courts
            // belonging to the same sports centre.
            $query->whereHas('canchas', function ($where) use (
                $surfaceTypes,
                $normalizedFormats,
                $capacities,
                $hasTipoSuperficie,
                $hasFormatoVs,
                $hasEquiposVs,
            ) {
                if (!empty($surfaceTypes) && $hasTipoSuperficie) {
                    $surfaceValues = collect($surfaceTypes)
                        ->flatMap(fn (string $surface) => $this->surfaceAliases($surface))
                        ->unique()
                        ->values()
                        ->all();
                    $where->whereIn('tipo_superficie', $surfaceValues);
                }

                if (!empty($normalizedFormats) && ($hasFormatoVs || $hasEquiposVs)) {
                    $where->where(function ($formats) use ($normalizedFormats, $capacities, $hasFormatoVs, $hasEquiposVs) {
                        if ($hasFormatoVs) {
                            $formats->whereIn('formato_vs', $normalizedFormats);
                        }
                        if ($hasEquiposVs && !empty($capacities)) {
                            $method = $hasFormatoVs ? 'orWhereIn' : 'whereIn';
                            $formats->{$method}('equiposvs', $capacities);
                        }
                    });
                }
            });
        }

        $items = $query
            ->orderBy('nombre')
            ->limit($limit)
            ->get()
            ->map(fn(Polideportivo $field) => $this->serializeField($field, $hasPrecioDesdeNum, $hasTipoSuperficie, $hasFormatoVs, $hasEquiposVs))
            ->values();

        $surfaceTypesAvailable = $items->pluck('surface_types')
            ->flatten()
            ->filter()
            ->unique()
            ->sort()
            ->values()
            ->all();
        $vsFormatsAvailable = $items->pluck('vs_formats')
            ->flatten()
            ->filter()
            ->unique()
            ->sort()
            ->values()
            ->all();
        $prices = $items->pluck('precio_desde_num')
            ->filter(fn($value) => $value !== null)
            ->values();

        return response()->json([
            'items' => $items,
            'meta' => [
                'surface_types_available' => $surfaceTypesAvailable,
                'vs_formats_available' => $vsFormatsAvailable,
                'precio_desde_num_min' => $prices->isEmpty() ? null : (float) $prices->min(),
                'precio_desde_num_max' => $prices->isEmpty() ? null : (float) $prices->max(),
            ],
        ]);
    }

    public function show(Request $request, Polideportivo $field)
    {
        $hasPrecioDesdeNum = Schema::hasColumn('polideportivo', 'precio_desde_num');
        $hasTipoSuperficie = Schema::hasColumn('cancha', 'tipo_superficie');
        $hasFormatoVs = Schema::hasColumn('cancha', 'formato_vs');
        $hasEquiposVs = Schema::hasColumn('cancha', 'equiposvs');
        $hasCanchaAncho = Schema::hasColumn('cancha', 'anchom2');
        $hasCanchaLargo = Schema::hasColumn('cancha', 'largom2');

        $field->loadCount('canchas');
        $field->load([
            'canchas' => function ($canchasQuery) use ($hasTipoSuperficie, $hasFormatoVs, $hasEquiposVs, $hasCanchaAncho, $hasCanchaLargo) {
                    $columns = ['id', 'id_polideportivo', 'nombre', 'url_foto'];
                    if ($hasTipoSuperficie) {
                        $columns[] = 'tipo_superficie';
                    }
                    if ($hasFormatoVs) {
                        $columns[] = 'formato_vs';
                    }
                    if ($hasEquiposVs) {
                        $columns[] = 'equiposvs';
                    }
                    if ($hasCanchaAncho) {
                        $columns[] = 'anchom2';
                    }
                    if ($hasCanchaLargo) {
                        $columns[] = 'largom2';
                    }
                    $canchasQuery->select($columns);
            },
        ]);

        return response()->json([
            'field' => $this->serializeField(
                $field,
                $hasPrecioDesdeNum,
                $hasTipoSuperficie,
                $hasFormatoVs,
                $hasEquiposVs,
                $hasCanchaAncho,
                $hasCanchaLargo,
                includeCanchas: true,
            ),
        ]);
    }

    /**
     * @return array<string,mixed>
     */
    private function serializeField(
        Polideportivo $field,
        bool $hasPrecioDesdeNum,
        bool $hasTipoSuperficie,
        bool $hasFormatoVs,
        bool $hasEquiposVs,
        bool $hasCanchaAncho = false,
        bool $hasCanchaLargo = false,
        bool $includeCanchas = false,
    ): array
    {
        $surfaceTypes = [];
        $vsFormats = [];
        if ($field->relationLoaded('canchas')) {
            foreach ($field->canchas as $cancha) {
                if ($hasTipoSuperficie) {
                    $value = trim((string) ($cancha->tipo_superficie ?? ''));
                    if ($value !== '') {
                        $surfaceTypes[] = $value;
                    }
                }
                $format = $hasFormatoVs
                    ? $this->normalizeFormat((string) ($cancha->formato_vs ?? ''))
                    : null;
                if ($format === null && $hasEquiposVs) {
                    $format = $this->normalizeFormat((string) ($cancha->equiposvs ?? ''));
                }
                if ($format !== null) {
                    $vsFormats[] = $format;
                }
            }
        }

        $payload = [
            'id' => $field->id,
            'nombre' => $field->nombre,
            'direccion' => $field->direccion,
            'x' => $field->x !== null ? (float) $field->x : null,
            'y' => $field->y !== null ? (float) $field->y : null,
            'descripcion' => $field->descripcion,
            'precio_desde' => $field->precio_desde,
            'precio_desde_num' => $hasPrecioDesdeNum && $field->precio_desde_num !== null ? (float) $field->precio_desde_num : null,
            'url_foto' => $field->url_foto,
            'celular' => $field->celular,
            'wsp' => (bool) ($field->wsp ?? false),
            'id_distrito' => $field->id_distrito,
            'canchas_count' => (int) ($field->canchas_count ?? 0),
            'surface_types' => array_values(array_unique($surfaceTypes)),
            'vs_formats' => array_values(array_unique($vsFormats)),
        ];

        if ($includeCanchas) {
            $payload['canchas'] = $field->canchas
                ->map(function ($cancha) use ($hasTipoSuperficie, $hasFormatoVs, $hasEquiposVs, $hasCanchaAncho, $hasCanchaLargo) {
                    $format = $hasFormatoVs
                        ? $this->normalizeFormat((string) ($cancha->formato_vs ?? ''))
                        : null;
                    if ($format === null && $hasEquiposVs) {
                        $format = $this->normalizeFormat((string) ($cancha->equiposvs ?? ''));
                    }

                    return [
                        'id' => $cancha->id,
                        'nombre' => $cancha->nombre,
                        'url_foto' => $cancha->url_foto,
                        'tipo_superficie' => $hasTipoSuperficie ? $cancha->tipo_superficie : null,
                        'vs_format' => $format,
                        'anchom2' => $hasCanchaAncho && $cancha->anchom2 !== null ? (float) $cancha->anchom2 : null,
                        'largom2' => $hasCanchaLargo && $cancha->largom2 !== null ? (float) $cancha->largom2 : null,
                    ];
                })
                ->values()
                ->all();
        }

        return $payload;
    }

    private function normalizeFormat(string $value): ?string
    {
        $normalized = strtolower(trim($value));
        $normalized = preg_replace('/\s+/', '', $normalized) ?? '';
        if ($normalized === '') {
            return null;
        }

        if (preg_match('/^(\d+)$/', $normalized, $matches)) {
            return $matches[1] . 'v' . $matches[1];
        }

        if (preg_match('/^(\d+)(?:v|vs)(\d+)$/', $normalized, $matches)) {
            return $matches[1] . 'v' . $matches[2];
        }

        return null;
    }

    /**
     * Return the stored aliases for a user-facing surface value.
     *
     * Older demo data may contain "artificial" while the app exposes the
     * canonical label "sintetico". Matching both keeps filtering consistent
     * without requiring a destructive data migration.
     *
     * @return array<int,string>
     */
    private function surfaceAliases(string $value): array
    {
        $normalized = strtolower(trim($value));
        $normalized = str_replace(['á', 'é', 'í', 'ó', 'ú'], ['a', 'e', 'i', 'o', 'u'], $normalized);

        return match ($normalized) {
            'sintetico', 'artificial', 'grass sintetico', 'grass artificial' => [
                'sintetico',
                'artificial',
                'grass sintetico',
                'sintético',
                'grass artificial',
                'Grass sintético',
            ],
            'natural', 'grass natural' => ['natural', 'grass natural'],
            'losa' => ['losa'],
            default => [$value],
        };
    }

    private function parseDecimalQuery(mixed $value): ?float
    {
        if ($value === null) {
            return null;
        }
        $normalized = trim((string) $value);
        if ($normalized === '') {
            return null;
        }
        $number = (float) str_replace(',', '.', $normalized);
        return $number >= 0 ? $number : null;
    }

    /**
     * @return array<int,string>
     */
    private function parseCsv(mixed $value): array
    {
        $raw = trim((string) ($value ?? ''));
        if ($raw === '') {
            return [];
        }

        return array_values(array_filter(array_unique(array_map(
            fn(string $entry) => trim($entry),
            explode(',', $raw)
        ))));
    }
}
