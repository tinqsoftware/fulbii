<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\GroupPichanga;
use App\Models\FieldSubmission;
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
        $viewport = $request->validate([
            'south' => ['nullable', 'numeric', 'between:-90,90', 'required_with:west,north,east'],
            'west' => ['nullable', 'numeric', 'between:-180,180', 'required_with:south,north,east'],
            'north' => ['nullable', 'numeric', 'between:-90,90', 'required_with:south,west,east'],
            'east' => ['nullable', 'numeric', 'between:-180,180', 'required_with:south,west,north'],
        ]);
        $hasViewport = collect(['south', 'west', 'north', 'east'])
            ->every(fn (string $key) => array_key_exists($key, $viewport) && $viewport[$key] !== null);
        abort_if(
            $hasViewport && ($viewport['south'] > $viewport['north'] || $viewport['west'] > $viewport['east']),
            422,
            'Los límites del mapa no son válidos.'
        );
        $q = trim((string) $request->query('q', ''));
        $rawLimit = $request->query('limit');
        $limit = null;
        if ($rawLimit !== null && (string)$rawLimit !== '0' && strtolower((string)$rawLimit) !== 'all') {
            $limit = max(1, min(5000, (int) $rawLimit));
        }

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

        if ($hasViewport) {
            // x/y are legacy text columns. Cast only when the optional
            // viewport contract is used, preserving current clients and data.
            $query->whereNotNull('x')
                ->whereNotNull('y')
                ->whereRaw('CAST(x AS DECIMAL(10,6)) BETWEEN ? AND ?', [
                    $viewport['south'],
                    $viewport['north'],
                ])
                ->whereRaw('CAST(y AS DECIMAL(10,6)) BETWEEN ? AND ?', [
                    $viewport['west'],
                    $viewport['east'],
                ]);
        }

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
        $hasPhotoGalleries = Schema::hasTable('polideportivo_photos') && Schema::hasTable('cancha_photos');
        $relations = [
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
        ];
        if ($hasPhotoGalleries) {
            $relations['photos'] = fn ($query) => $query;
            $relations['canchas.photos'] = fn ($query) => $query;
        }
        $field->load($relations);

        $payload = $this->serializeField(
            $field,
            $hasPrecioDesdeNum,
            $hasTipoSuperficie,
            $hasFormatoVs,
            $hasEquiposVs,
            $hasCanchaAncho,
            $hasCanchaLargo,
            includeCanchas: true,
        );
        $payload['open_pichangas'] = $this->openPichangasForField($field);
        $payload = $this->withContributorAttribution($payload, $field);
        if (Schema::hasTable('perfil')
            && Schema::hasTable('user_perfil')
            && $request->user()?->canPerformCriticalAdminActions()) {
            $payload['admin_audit'] = $this->adminAudit($field, $payload);
        }

        return response()->json(['field' => $payload]);
    }

    /** @param array<string,mixed> $payload @return array<string,mixed> */
    private function withContributorAttribution(array $payload, Polideportivo $field): array
    {
        if (!Schema::hasTable('field_submissions')
            || !Schema::hasTable('users')
            || !Schema::hasColumn('field_submissions', 'approved_polideportivo_id')
            || !Schema::hasColumn('field_submissions', 'approved_cancha_id')
            || !Schema::hasColumn('field_submissions', 'submission_type')) {
            return $payload;
        }

        $fieldContribution = FieldSubmission::query()
            ->where('approved_polideportivo_id', $field->id)
            ->where('status', 'approved')
            ->where('submission_type', 'new_polideportivo')
            ->with('user:id,nick,name,avatar_url')
            ->latest('reviewed_at')
            ->first();
        if ($fieldContribution?->user) {
            $payload['contributor'] = $this->serializeContributor($fieldContribution);
        }

        $courtContributions = FieldSubmission::query()
            ->whereIn('approved_cancha_id', collect($payload['canchas'] ?? [])->pluck('id')->filter()->all())
            ->where('status', 'approved')
            ->with('user:id,nick,name,avatar_url')
            ->get()
            ->keyBy('approved_cancha_id');
        $payload['canchas'] = collect($payload['canchas'] ?? [])->map(function (array $court) use ($courtContributions) {
            $submission = $courtContributions->get((int) ($court['id'] ?? 0));
            if ($submission?->user) {
                $court['contributor'] = $this->serializeContributor($submission);
            }
            return $court;
        })->values()->all();

        return $payload;
    }

    /** @return array{id:int,nick:string,avatar_url:?string} */
    private function serializeContributor(FieldSubmission $submission): array
    {
        return [
            'id' => (int) $submission->user_id,
            'nick' => (string) ($submission->user?->nick ?: $submission->user?->name ?: 'Jugador'),
            'avatar_url' => $submission->user?->avatar_url,
        ];
    }

    /** @param array<string,mixed> $payload @return array{field:?array<string,mixed>,courts:array<int,array<string,mixed>>} */
    private function adminAudit(Polideportivo $field, array $payload): array
    {
        $base = FieldSubmission::query()
            ->where('status', 'approved')
            ->with(['user:id,nick,name', 'reviewer:id,nick,name']);
        $fieldSubmission = (clone $base)
            ->where('approved_polideportivo_id', $field->id)
            ->latest('reviewed_at')
            ->first();
        $courtSubmissions = (clone $base)
            ->whereIn('approved_cancha_id', collect($payload['canchas'] ?? [])->pluck('id')->filter()->all())
            ->get()
            ->keyBy('approved_cancha_id');
        $serialize = static fn (?FieldSubmission $submission) => $submission ? [
            'submission_id' => (int) $submission->id,
            'submitted_at' => optional($submission->created_at)->toISOString(),
            'approved_at' => optional($submission->reviewed_at)->toISOString(),
            'submitted_by' => (string) ($submission->user?->nick ?: $submission->user?->name ?: 'Usuario'),
            'reviewed_by_user_id' => $submission->reviewed_by_user_id ? (int) $submission->reviewed_by_user_id : null,
            'reviewed_by' => (string) ($submission->reviewer?->nick ?: $submission->reviewer?->name ?: 'Administrador'),
        ] : null;

        return [
            'field' => $serialize($fieldSubmission),
            'courts' => collect($payload['canchas'] ?? [])->mapWithKeys(
                fn (array $court) => [(string) $court['id'] => $serialize($courtSubmissions->get((int) $court['id']))]
            )->all(),
        ];
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
            'photos' => $field->relationLoaded('photos')
                ? $field->photos->map(fn ($photo) => $photo->photo_url)->values()->all()
                : [],
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
                        'photos' => $cancha->relationLoaded('photos')
                            ? $cancha->photos->map(fn ($photo) => $photo->photo_url)->values()->all()
                            : [],
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
     * Lists only future, open pichangas that still have a place available.
     * Historical and closed matches stay out of venue discovery.
     *
     * @return array<int,array<string,mixed>>
     */
    private function openPichangasForField(Polideportivo $field): array
    {
        if (
            !Schema::hasTable('group_pichangas')
            || !Schema::hasTable('group_pichanga_participants')
            || !Schema::hasColumns('group_pichangas', ['status', 'starts_at', 'capacity', 'is_open'])
            || !Schema::hasColumns('group_pichanga_participants', ['pichanga_id', 'status'])
        ) {
            return [];
        }

        $courtIds = $field->canchas->pluck('id')
            ->map(fn ($id) => (int) $id)
            ->filter()
            ->values()
            ->all();
        $hasFieldId = Schema::hasColumn('group_pichangas', 'field_id');
        $hasCourtId = Schema::hasColumn('group_pichangas', 'cancha_id');

        if (!$hasFieldId && (!$hasCourtId || empty($courtIds))) {
            return [];
        }

        return GroupPichanga::query()
            ->whereIn('status', ['published', 'confirmed'])
            ->where('is_open', true)
            ->where('starts_at', '>', now())
            ->where(function ($query) use ($field, $courtIds, $hasFieldId, $hasCourtId) {
                if ($hasFieldId) {
                    $query->where('field_id', (int) $field->id);
                }
                if ($hasCourtId && !empty($courtIds)) {
                    $hasFieldId
                        ? $query->orWhereIn('cancha_id', $courtIds)
                        : $query->whereIn('cancha_id', $courtIds);
                }
            })
            ->withCount([
                'participants as confirmed_count' => fn ($query) => $query->where('status', 'confirmed'),
            ])
            ->orderBy('starts_at')
            // Fetch a little extra before discarding full matches.
            ->limit(24)
            ->get()
            ->filter(fn (GroupPichanga $pichanga) => (int) $pichanga->confirmed_count < (int) $pichanga->capacity)
            ->take(8)
            ->map(function (GroupPichanga $pichanga) use ($field) {
                $court = $field->canchas->firstWhere('id', (int) $pichanga->cancha_id);
                $confirmed = (int) $pichanga->confirmed_count;

                return [
                    'id' => (int) $pichanga->id,
                    'title' => (string) ($pichanga->title ?: 'Pichanga abierta'),
                    'starts_at' => optional($pichanga->starts_at)->toISOString(),
                    'duration_minutes' => (int) ($pichanga->duration_minutes ?? 0),
                    'capacity' => (int) $pichanga->capacity,
                    'confirmed_count' => $confirmed,
                    'spots_left' => max(0, (int) $pichanga->capacity - $confirmed),
                    'court_name' => $court?->nombre,
                    'match_format' => $pichanga->match_format,
                    'players_per_team' => $pichanga->players_per_team,
                ];
            })
            ->values()
            ->all();
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
