<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Cancha;
use App\Models\ClubUser;
use App\Models\FieldGeometry;
use App\Models\GroupPichanga;
use App\Models\GroupPichangaParticipant;
use App\Models\Polideportivo;
use App\Models\WatchMatchEvent;
use App\Models\WatchMatchSession;
use App\Models\WatchPositionSample;
use Illuminate\Support\Collection;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Schema;
use Illuminate\Validation\Rule;

class WatchMatchSessionController extends Controller
{
    public function homeFeed(Request $request)
    {
        $user = $request->user() ?? abort(401);
        $days = min(7, max(1, (int) $request->query('days', 7)));
        $now = now();
        $todayStart = $now->copy()->startOfDay();
        $windowEnd = $todayStart->copy()->addDays($days)->endOfDay();
        $hasRivalColumn = Schema::hasColumn('group_pichangas', 'rival_club_id');
        $hasCreatedByColumn = Schema::hasColumn('group_pichangas', 'created_by_user_id');

        $clubIds = ClubUser::query()
            ->where('user_id', (int) $user->id)
            ->pluck('club_id')
            ->map(fn($id) => (int) $id)
            ->unique()
            ->values()
            ->all();

        $confirmedParticipantIds = GroupPichangaParticipant::query()
            ->join('group_pichangas as gp', 'gp.id', '=', 'group_pichanga_participants.pichanga_id')
            ->where('group_pichanga_participants.user_id', (int) $user->id)
            ->where('group_pichanga_participants.status', 'confirmed')
            ->whereIn('gp.status', ['published', 'confirmed'])
            ->where(function ($scope) use ($todayStart, $windowEnd, $now) {
                $scope
                    ->whereBetween('gp.starts_at', [$todayStart, $windowEnd])
                    ->orWhere(function ($running) use ($now) {
                        $running
                            ->where('gp.starts_at', '<=', $now)
                            ->whereRaw('DATE_ADD(gp.starts_at, INTERVAL gp.duration_minutes MINUTE) >= ?', [$now]);
                    });
            })
            ->pluck('gp.id')
            ->map(fn($id) => (int) $id)
            ->unique()
            ->values()
            ->all();

        $createdByIds = [];
        if ($hasCreatedByColumn) {
            $createdByIds = GroupPichanga::query()
                ->where('created_by_user_id', (int) $user->id)
                ->whereIn('status', ['published', 'confirmed'])
                ->where(function ($scope) use ($todayStart, $windowEnd, $now) {
                    $scope
                        ->whereBetween('starts_at', [$todayStart, $windowEnd])
                        ->orWhere(function ($running) use ($now) {
                            $running
                                ->where('starts_at', '<=', $now)
                                ->whereRaw('DATE_ADD(starts_at, INTERVAL duration_minutes MINUTE) >= ?', [$now]);
                        });
                })
                ->pluck('id')
                ->map(fn($id) => (int) $id)
                ->unique()
                ->values()
                ->all();
        }

        if (empty($clubIds) && empty($confirmedParticipantIds) && empty($createdByIds)) {
            return response()->json([
                'user' => [
                    'id' => (int) $user->id,
                    'nick' => $user->nick,
                    'name' => $user->name,
                ],
                'confirmed_matches' => [],
                'pending_matches' => [],
                'window' => [
                    'from' => $todayStart->toISOString(),
                    'to' => $windowEnd->toISOString(),
                ],
            ]);
        }

        $baseQuery = GroupPichanga::query()
            ->whereIn('status', ['published', 'confirmed'])
            ->where(function ($scope) use ($todayStart, $windowEnd, $now) {
                $scope
                    ->whereBetween('starts_at', [$todayStart, $windowEnd])
                    ->orWhere(function ($running) use ($now) {
                        $running
                            ->where('starts_at', '<=', $now)
                            ->whereRaw('DATE_ADD(starts_at, INTERVAL duration_minutes MINUTE) >= ?', [$now]);
                    });
            })
            ->where(function ($scope) use ($clubIds, $confirmedParticipantIds, $createdByIds, $hasRivalColumn) {
                $appliedAny = false;

                if (!empty($clubIds)) {
                    $scope->whereIn('club_id', $clubIds);
                    if ($hasRivalColumn) {
                        $scope->orWhereIn('rival_club_id', $clubIds);
                    }
                    $appliedAny = true;
                }
                if (!empty($confirmedParticipantIds)) {
                    if ($appliedAny) {
                        $scope->orWhereIn('id', $confirmedParticipantIds);
                    } else {
                        $scope->whereIn('id', $confirmedParticipantIds);
                        $appliedAny = true;
                    }
                }
                if (!empty($createdByIds)) {
                    if ($appliedAny) {
                        $scope->orWhereIn('id', $createdByIds);
                    } else {
                        $scope->whereIn('id', $createdByIds);
                        $appliedAny = true;
                    }
                }
                if (!$appliedAny) {
                    $scope->whereRaw('1 = 0');
                }
            })
            ->orderBy('starts_at');

        $pichangas = $baseQuery->limit(200)->get();
        if ($pichangas->isEmpty()) {
            return response()->json([
                'user' => [
                    'id' => (int) $user->id,
                    'nick' => $user->nick,
                    'name' => $user->name,
                ],
                'confirmed_matches' => [],
                'pending_matches' => [],
                'window' => [
                    'from' => $todayStart->toISOString(),
                    'to' => $windowEnd->toISOString(),
                ],
            ]);
        }

        $pichangaIds = $pichangas->pluck('id')->map(fn($id) => (int) $id)->all();
        $confirmedIds = GroupPichangaParticipant::query()
            ->where('user_id', (int) $user->id)
            ->whereIn('pichanga_id', $pichangaIds)
            ->where('status', 'confirmed')
            ->pluck('pichanga_id')
            ->map(fn($id) => (int) $id)
            ->unique()
            ->values()
            ->all();
        $confirmedSet = array_fill_keys($confirmedIds, true);

        $canchaIds = $pichangas
            ->pluck('cancha_id')
            ->filter(fn($id) => $id !== null)
            ->map(fn($id) => (int) $id)
            ->unique()
            ->values()
            ->all();
        $fieldIds = $pichangas
            ->pluck('field_id')
            ->filter(fn($id) => $id !== null)
            ->map(fn($id) => (int) $id)
            ->unique()
            ->values()
            ->all();

        $canchas = Cancha::query()
            ->whereIn('id', $canchaIds)
            ->get(['id', 'id_polideportivo', 'nombre'])
            ->keyBy(fn(Cancha $cancha) => (int) $cancha->id);

        $allPolideportivoIds = collect($fieldIds)
            ->merge(
                $canchas
                    ->pluck('id_polideportivo')
                    ->filter(fn($id) => $id !== null)
                    ->map(fn($id) => (int) $id)
            )
            ->unique()
            ->values()
            ->all();

        $polideportivos = Polideportivo::query()
            ->whereIn('id', $allPolideportivoIds)
            ->get(['id', 'nombre'])
            ->keyBy(fn(Polideportivo $field) => (int) $field->id);

        $toWatchItem = function (GroupPichanga $pichanga) use ($canchas, $polideportivos): array {
            $cancha = $pichanga->cancha_id ? $canchas->get((int) $pichanga->cancha_id) : null;
            $field = $pichanga->field_id ? $polideportivos->get((int) $pichanga->field_id) : null;
            if (!$field && $cancha?->id_polideportivo) {
                $field = $polideportivos->get((int) $cancha->id_polideportivo);
            }

            $teamCodes = $this->teamCodesForPichanga($pichanga);
            return [
                'id' => (int) $pichanga->id,
                'title' => (string) ($pichanga->title ?: 'Pichanga Fulbii'),
                'center_name' => (string) ($field?->nombre ?? 'Centro Deportivo'),
                'field_name' => (string) ($cancha?->nombre ?? 'Cancha'),
                'field_id' => (int) ($pichanga->field_id ?? 0),
                'cancha_id' => (int) ($pichanga->cancha_id ?? 0),
                'start_at' => optional($pichanga->starts_at)->toISOString(),
                'duration_minutes' => (int) ($pichanga->duration_minutes ?? 90),
                'status' => (string) ($pichanga->status ?? 'published'),
                'team_codes' => $teamCodes,
            ];
        };

        $confirmed = [];
        $pending = [];
        foreach ($pichangas as $pichanga) {
            $item = $toWatchItem($pichanga);
            $isMemberClub = in_array((int) $pichanga->club_id, $clubIds, true)
                || ($hasRivalColumn
                    && (int) ($pichanga->rival_club_id ?? 0) > 0
                    && in_array((int) $pichanga->rival_club_id, $clubIds, true));
            $isCreator = $hasCreatedByColumn
                && (int) ($pichanga->created_by_user_id ?? 0) === (int) $user->id;

            if (isset($confirmedSet[(int) $pichanga->id])) {
                $confirmed[] = $item;
            } elseif ($isMemberClub || $isCreator) {
                $pending[] = $item;
            }
        }

        return response()->json([
            'user' => [
                'id' => (int) $user->id,
                'nick' => $user->nick,
                'name' => $user->name,
            ],
            'confirmed_matches' => array_values($confirmed),
            'pending_matches' => array_values($pending),
            'window' => [
                'from' => $todayStart->toISOString(),
                'to' => $windowEnd->toISOString(),
            ],
        ]);
    }

    public function myActive(Request $request)
    {
        $this->assertTablesReady();
        $user = $request->user() ?? abort(401);
        $session = WatchMatchSession::query()
            ->where('user_id', (int) $user->id)
            ->whereIn('status', ['live', 'paused'])
            ->latest('id')
            ->first();

        return response()->json([
            'session' => $session,
        ]);
    }

    public function sessionsByPichangaMe(Request $request, GroupPichanga $pichanga)
    {
        $this->assertTablesReady();
        $user = $request->user() ?? abort(401);

        $sessions = WatchMatchSession::query()
            ->where('user_id', (int) $user->id)
            ->where('group_pichanga_id', (int) $pichanga->id)
            ->orderByDesc('id')
            ->limit(20)
            ->get()
            ->map(function (WatchMatchSession $session) {
                $goals = WatchMatchEvent::query()
                    ->where('session_id', (int) $session->id)
                    ->where('event_type', 'goal')
                    ->orderBy('event_at')
                    ->get(['id', 'event_at', 'minute', 'clock_time']);
                $assists = WatchMatchEvent::query()
                    ->where('session_id', (int) $session->id)
                    ->where('event_type', 'assist')
                    ->count();

                return [
                    'session' => $session,
                    'goals_count' => $goals->count(),
                    'assists_count' => (int) $assists,
                    'goals' => $goals,
                ];
            })
            ->values();

        return response()->json([
            'items' => $sessions,
        ]);
    }

    public function heatmapByPichangaMe(Request $request, GroupPichanga $pichanga)
    {
        $this->assertTablesReady();
        $user = $request->user() ?? abort(401);

        $session = WatchMatchSession::query()
            ->where('user_id', (int) $user->id)
            ->where('group_pichanga_id', (int) $pichanga->id)
            ->orderByDesc('id')
            ->first();
        abort_if(!$session, 404, 'No hay sesión watch para esta pichanga.');

        $samples = WatchPositionSample::query()
            ->where('session_id', (int) $session->id)
            ->orderBy('sampled_at')
            ->get();

        $raw = $samples->map(fn(WatchPositionSample $sample) => [
            'timestamp' => optional($sample->sampled_at)->toISOString(),
            'lat' => (float) $sample->lat,
            'lng' => (float) $sample->lng,
            'horizontal_accuracy' => $sample->horizontal_accuracy !== null ? (float) $sample->horizontal_accuracy : null,
            'speed' => $sample->speed !== null ? (float) $sample->speed : null,
            'quality_flag' => $sample->quality_flag,
        ])->values();

        $normalizedRaw = $this->normalizeLatLng($samples);
        $projection = $this->projectIfGeometryExists($session, $samples);

        return response()->json([
            'session' => $session,
            'raw_samples' => $raw,
            'raw_normalized_points' => $normalizedRaw,
            'projected_points' => $projection['points'],
            'projection_mode' => $projection['mode'],
            'geometry' => $projection['geometry'],
        ]);
    }

    public function store(Request $request)
    {
        $this->assertTablesReady();
        $user = $request->user() ?? abort(401);

        $data = $request->validate([
            'external_session_id' => ['nullable', 'string', 'max:64'],
            'group_pichanga_id' => ['nullable', 'integer'],
            'field_id' => ['nullable', 'integer'],
            'cancha_id' => ['nullable', 'integer'],
            'field_geometry_id' => ['nullable', 'integer'],
            'start_time' => ['required', 'date'],
            'status' => ['nullable', Rule::in(['idle', 'live', 'paused', 'finished', 'auto_finished'])],
            'my_goal_side' => ['nullable', Rule::in(['north', 'south', 'east', 'west', 'unknown'])],
            'device' => ['nullable', Rule::in(['watchos', 'wearos'])],
            'source' => ['nullable', Rule::in(['live', 'simulated'])],
            'distance_meters_raw' => ['nullable', 'numeric', 'min:0', 'max:200000'],
            'distance_meters_filtered' => ['nullable', 'numeric', 'min:0', 'max:200000'],
            'device_payload' => ['nullable', 'array'],
        ]);

        foreach (['group_pichanga_id', 'field_id', 'cancha_id', 'field_geometry_id'] as $idKey) {
            if (isset($data[$idKey]) && (!is_numeric($data[$idKey]) || (int) $data[$idKey] <= 0)) {
                $data[$idKey] = null;
            }
        }

        $source = (string) ($data['source'] ?? 'live');
        if ($source !== 'simulated' && empty($data['group_pichanga_id'])) {
            abort(422, 'group_pichanga_id es obligatorio para sesiones watch reales.');
        }

        if (!empty($data['cancha_id']) && empty($data['field_id'])) {
            $data['field_id'] = (int) (Cancha::query()
                ->where('id', (int) $data['cancha_id'])
                ->value('id_polideportivo') ?? 0);
            abort_if($data['field_id'] <= 0, 422, 'cancha_id inválido.');
        }

        if (!empty($data['group_pichanga_id'])) {
            $pichanga = GroupPichanga::query()->find((int) $data['group_pichanga_id']);
            abort_if(!$pichanga, 422, 'group_pichanga_id inválido.');
        }

        $externalSessionId = trim((string) ($data['external_session_id'] ?? ''));
        if ($externalSessionId !== '') {
            $existingSession = WatchMatchSession::query()
                ->where('user_id', (int) $user->id)
                ->where('external_session_id', $externalSessionId)
                ->latest('id')
                ->first();
            if ($existingSession) {
                return response()->json(['session' => $existingSession]);
            }
        }

        $session = WatchMatchSession::create([
            'user_id' => (int) $user->id,
            'external_session_id' => $externalSessionId !== '' ? $externalSessionId : null,
            'group_pichanga_id' => $data['group_pichanga_id'] ?? null,
            'field_id' => $data['field_id'] ?? null,
            'cancha_id' => $data['cancha_id'] ?? null,
            'field_geometry_id' => $data['field_geometry_id'] ?? null,
            'start_time' => $data['start_time'],
            'status' => $data['status'] ?? 'live',
            'my_goal_side' => $data['my_goal_side'] ?? 'unknown',
            'device' => $data['device'] ?? 'watchos',
            'source' => $data['source'] ?? 'live',
            'distance_meters_raw' => $data['distance_meters_raw'] ?? null,
            'distance_meters_filtered' => $data['distance_meters_filtered'] ?? null,
            'distance_meters' => $data['distance_meters_filtered'] ?? $data['distance_meters_raw'] ?? null,
            'device_payload_json' => $data['device_payload'] ?? null,
        ]);

        return response()->json(['session' => $session], 201);
    }

    public function batchSamples(Request $request, WatchMatchSession $session)
    {
        $this->assertTablesReady();
        $user = $request->user() ?? abort(401);
        abort_unless((int) $session->user_id === (int) $user->id || (bool) $user->is_superadmin, 403);

        $data = $request->validate([
            'samples' => ['required', 'array', 'min:1', 'max:2000'],
            'samples.*.timestamp' => ['required', 'date'],
            'samples.*.lat' => ['required', 'numeric', 'between:-90,90'],
            'samples.*.lng' => ['required', 'numeric', 'between:-180,180'],
            'samples.*.horizontalAccuracy' => ['nullable', 'numeric', 'min:0', 'max:500'],
            'samples.*.speed' => ['nullable', 'numeric', 'min:0', 'max:30'],
            'samples.*.quality_flag' => ['nullable', Rule::in(['good', 'weak', 'rejected'])],
        ]);

        $rows = [];
        foreach ($data['samples'] as $sample) {
            $rows[] = [
                'session_id' => (int) $session->id,
                'sampled_at' => $sample['timestamp'],
                'lat' => (float) $sample['lat'],
                'lng' => (float) $sample['lng'],
                'horizontal_accuracy' => array_key_exists('horizontalAccuracy', $sample) ? (float) $sample['horizontalAccuracy'] : null,
                'speed' => array_key_exists('speed', $sample) ? (float) $sample['speed'] : null,
                'quality_flag' => array_key_exists('quality_flag', $sample) ? ($sample['quality_flag'] ?: null) : null,
                'created_at' => now(),
                'updated_at' => now(),
            ];
        }

        WatchPositionSample::insert($rows);

        return response()->json([
            'inserted' => count($rows),
        ]);
    }

    public function batchEvents(Request $request, WatchMatchSession $session)
    {
        $this->assertTablesReady();
        $user = $request->user() ?? abort(401);
        abort_unless((int) $session->user_id === (int) $user->id || (bool) $user->is_superadmin, 403);

        $data = $request->validate([
            'events' => ['required', 'array', 'min:1', 'max:200'],
            'events.*.type' => ['required', Rule::in(['goal', 'assist', 'pause', 'resume', 'side_change'])],
            'events.*.timestamp' => ['required', 'date'],
            'events.*.minute' => ['nullable', 'integer', 'min:1', 'max:300'],
            'events.*.clockTime' => ['nullable', 'string', 'max:20'],
            'events.*.metadata' => ['nullable', 'array'],
        ]);

        $rows = [];
        foreach ($data['events'] as $event) {
            $minute = array_key_exists('minute', $event)
                ? (int) $event['minute']
                : max(1, now()->diffInMinutes($session->start_time ?? now()) + 1);
            $rows[] = [
                'session_id' => (int) $session->id,
                'event_type' => (string) $event['type'],
                'event_at' => $event['timestamp'],
                'minute' => $minute,
                'clock_time' => $event['clockTime'] ?? null,
                'metadata_json' => $event['metadata'] ?? null,
                'created_at' => now(),
                'updated_at' => now(),
            ];
        }

        WatchMatchEvent::insert($rows);

        return response()->json([
            'inserted' => count($rows),
        ]);
    }

    public function finish(Request $request, WatchMatchSession $session)
    {
        $this->assertTablesReady();
        $user = $request->user() ?? abort(401);
        abort_unless((int) $session->user_id === (int) $user->id || (bool) $user->is_superadmin, 403);

        $data = $request->validate([
            'end_time' => ['required', 'date'],
            'status' => ['nullable', Rule::in(['finished', 'auto_finished'])],
            'distance_meters' => ['nullable', 'numeric', 'min:0', 'max:200000'],
            'distance_meters_raw' => ['nullable', 'numeric', 'min:0', 'max:200000'],
            'distance_meters_filtered' => ['nullable', 'numeric', 'min:0', 'max:200000'],
        ]);

        $distanceFiltered = array_key_exists('distance_meters_filtered', $data)
            ? (float) $data['distance_meters_filtered']
            : (array_key_exists('distance_meters', $data)
                ? (float) $data['distance_meters']
                : $session->distance_meters_filtered);
        $distanceRaw = array_key_exists('distance_meters_raw', $data)
            ? (float) $data['distance_meters_raw']
            : $session->distance_meters_raw;

        $session->update([
            'end_time' => $data['end_time'],
            'status' => $data['status'] ?? 'finished',
            'distance_meters' => $distanceFiltered,
            'distance_meters_raw' => $distanceRaw,
            'distance_meters_filtered' => $distanceFiltered,
        ]);

        return response()->json([
            'message' => 'Partido finalizado.',
            'session' => $session->fresh(),
        ]);
    }

    private function assertTablesReady(): void
    {
        abort_unless(
            Schema::hasTable('watch_match_sessions')
                && Schema::hasTable('watch_position_samples')
                && Schema::hasTable('watch_match_events'),
            501,
            'Watch tables are not available.'
        );
    }

    /**
     * @return array<int,string>
     */
    private function teamCodesForPichanga(GroupPichanga $pichanga): array
    {
        $teamCount = (int) ($pichanga->team_count ?? 0);
        if ($teamCount <= 0) {
            $format = (string) ($pichanga->match_format ?? 'versus');
            $teamCount = match ($format) {
                'triangular' => 3,
                'cuadrangular' => 4,
                default => 2,
            };
        }

        $letters = ['A', 'B', 'C', 'D'];
        return array_slice($letters, 0, max(1, min(4, $teamCount)));
    }

    /**
     * @return array<int, array<string, float>>
     */
    private function normalizeLatLng(Collection $samples): array
    {
        if ($samples->isEmpty()) {
            return [];
        }

        $minLat = (float) $samples->min('lat');
        $maxLat = (float) $samples->max('lat');
        $minLng = (float) $samples->min('lng');
        $maxLng = (float) $samples->max('lng');
        $latRange = max(0.0000001, $maxLat - $minLat);
        $lngRange = max(0.0000001, $maxLng - $minLng);

        return $samples->map(function (WatchPositionSample $sample) use ($minLat, $minLng, $latRange, $lngRange) {
            return [
                'x' => max(0, min(1, ((float) $sample->lng - $minLng) / $lngRange)),
                'y' => max(0, min(1, ((float) $sample->lat - $minLat) / $latRange)),
            ];
        })->values()->all();
    }

    /**
     * @return array{mode:string,points:array<int,array{x:float,y:float}>,geometry:array<string,mixed>|null}
     */
    private function projectIfGeometryExists(WatchMatchSession $session, Collection $samples): array
    {
        if ($samples->isEmpty()) {
            return ['mode' => 'none', 'points' => [], 'geometry' => null];
        }

        $geometry = null;
        if ($session->field_geometry_id) {
            $geometry = FieldGeometry::query()->find((int) $session->field_geometry_id);
        }
        if (!$geometry && $session->cancha_id) {
            $geometry = FieldGeometry::query()->where('cancha_id', (int) $session->cancha_id)->first();
        }
        if (!$geometry) {
            return [
                'mode' => 'raw',
                'points' => $this->normalizeLatLng($samples),
                'geometry' => null,
            ];
        }

        $field = null;
        if ($session->field_id) {
            $field = Polideportivo::query()->find((int) $session->field_id);
        }
        if (!$field && $geometry->field_id) {
            $field = Polideportivo::query()->find((int) $geometry->field_id);
        }
        if (!$field) {
            return [
                'mode' => 'raw',
                'points' => $this->normalizeLatLng($samples),
                'geometry' => [
                    'id' => (int) $geometry->id,
                    'width_meters' => (float) $geometry->width_meters,
                    'length_meters' => (float) $geometry->length_meters,
                    'rotation_degrees' => (float) $geometry->rotation_degrees,
                ],
            ];
        }

        $width = max(1.0, (float) $geometry->width_meters);
        $length = max(1.0, (float) $geometry->length_meters);
        $rotation = ((float) $geometry->rotation_degrees) * M_PI / 180;
        $cosA = cos(-$rotation);
        $sinA = sin(-$rotation);
        $centerLat = (float) $field->x;
        $centerLng = (float) $field->y;

        $points = $samples->map(function (WatchPositionSample $sample) use ($centerLat, $centerLng, $cosA, $sinA, $width, $length) {
            $dxMeters = (($sample->lng - $centerLng) * 111320.0) * cos($centerLat * M_PI / 180);
            $dyMeters = (($sample->lat - $centerLat) * 110540.0);
            $rx = $dxMeters * $cosA - $dyMeters * $sinA;
            $ry = $dxMeters * $sinA + $dyMeters * $cosA;

            $x = max(0, min(1, ($rx + ($width / 2)) / $width));
            $y = max(0, min(1, ($ry + ($length / 2)) / $length));

            return ['x' => $x, 'y' => $y];
        })->values()->all();

        return [
            'mode' => 'projected',
            'points' => $points,
            'geometry' => [
                'id' => (int) $geometry->id,
                'field_id' => (int) ($geometry->field_id ?? 0),
                'cancha_id' => (int) ($geometry->cancha_id ?? 0),
                'width_meters' => $width,
                'length_meters' => $length,
                'rotation_degrees' => (float) $geometry->rotation_degrees,
            ],
        ];
    }
}
