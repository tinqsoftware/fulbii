<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Cancha;
use App\Models\Club;
use App\Models\ClubUser;
use App\Models\GroupPichanga;
use App\Models\GroupPichangaExternalRequest;
use App\Models\GroupPichangaNotificationBatch;
use App\Models\GroupPichangaParticipant;
use App\Models\GroupPichangaWaitlistEntry;
use App\Models\Polideportivo;
use App\Models\User;
use App\Models\WatchMatchSession;
use App\Models\WatchMatchEvent;
use App\Services\ClubPushMuteService;
use App\Services\ClubNotificationService;
use App\Services\CombinedSkillRatingService;
use App\Services\GroupPichangaAudienceService;
use App\Services\PichangaTeamAssignmentService;
use App\Services\ProductEventService;
use App\Services\PushNotificationService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Illuminate\Validation\Rule;

class GroupPichangaController extends Controller
{
    public function __construct(
        private readonly GroupPichangaAudienceService $audienceService,
        private readonly ClubPushMuteService $muteService,
        private readonly PushNotificationService $pushNotificationService,
        private readonly ClubNotificationService $clubNotifications,
        private readonly ProductEventService $eventService,
        private readonly CombinedSkillRatingService $combinedSkillRatings,
        private readonly PichangaTeamAssignmentService $teamAssignments
    ) {
    }

    public function indexByClub(Request $request, Club $club)
    {
        $auth = $request->user();
        $isMember = $auth ? $this->isMember($club->id, $auth->id) : false;
        $isSuper = $auth && Schema::hasTable('perfil') && Schema::hasTable('user_perfil')
            && (bool) $auth->is_superadmin;
        $isPublicViewer = !$isMember && !$isSuper;
        $clubIsActive = !Schema::hasColumn('clubs', 'estado') || (int) $club->estado === 1;
        $clubIsVisible = !Schema::hasColumn('clubs', 'is_visible') || (bool) $club->is_visible;

        abort_unless(!$isPublicViewer || ($clubIsActive && $clubIsVisible), 403);

        $tab = (string) $request->query('tab', 'pending');
        abort_unless(in_array($tab, ['pending', 'past'], true), 422, 'La pestaña no es válida.');
        $perPage = max(1, min(24, (int) $request->query('per_page', 6)));
        $query = GroupPichanga::query()
            ->where(function ($q) use ($club) {
                $q->where('club_id', $club->id);
                if (Schema::hasColumn('group_pichangas', 'rival_club_id')) {
                    $q->orWhere('rival_club_id', $club->id);
                }
            });
        if ($isPublicViewer) {
            abort_unless($tab === 'pending', 403);
            $query->where('is_open', true)
                ->where('starts_at', '>=', now())
                ->whereIn('status', ['published', 'confirmed']);
        } elseif ($tab === 'pending') {
            $endExpression = DB::connection()->getDriverName() === 'sqlite'
                ? "datetime(starts_at, '+' || duration_minutes || ' minutes')"
                : 'DATE_ADD(starts_at, INTERVAL duration_minutes MINUTE)';
            $query->whereIn('status', ['published', 'confirmed'])
                ->whereRaw("{$endExpression} >= ?", [now()]);
        } else {
            $endExpression = DB::connection()->getDriverName() === 'sqlite'
                ? "datetime(starts_at, '+' || duration_minutes || ' minutes')"
                : 'DATE_ADD(starts_at, INTERVAL duration_minutes MINUTE)';
            $query->where(function ($scope) use ($endExpression) {
                $scope->whereIn('status', ['cancelled', 'completed'])
                    ->orWhereRaw("{$endExpression} < ?", [now()]);
            });
        }

        $paginator = $query
            ->orderBy($tab === 'past' ? 'starts_at' : 'starts_at', $tab === 'past' ? 'desc' : 'asc')
            ->paginate($perPage);
        $pichangas = $paginator->getCollection();
        $venues = $this->venuesForPichangas($pichangas);
        $participantStatuses = $this->participantStatusesFor($pichangas, $auth?->id);
        $items = $pichangas->map(fn(GroupPichanga $p) => $this->serializePichanga(
            $p,
            array_merge(
                $venues[(int) $p->id] ?? [],
                ['me_participant_status' => $participantStatuses[(int) $p->id] ?? null],
                $this->detailPresentation($p, null, $isMember, null),
            ),
        ));

        return response()->json([
            'items' => $items,
            'meta' => [
                'tab' => $tab,
                'page' => $paginator->currentPage(),
                'per_page' => $paginator->perPage(),
                'total' => $paginator->total(),
                'last_page' => $paginator->lastPage(),
            ],
        ]);
    }

    /** One navigable month of a single club's agenda. */
    public function calendarByClub(Request $request, Club $club)
    {
        $auth = $request->user();
        $isMember = $auth ? $this->isMember($club->id, (int) $auth->id) : false;
        $isSuper = $auth && Schema::hasTable('perfil') && Schema::hasTable('user_perfil')
            && (bool) $auth->is_superadmin;
        $isPublicViewer = !$isMember && !$isSuper;
        $clubIsActive = !Schema::hasColumn('clubs', 'estado') || (int) $club->estado === 1;
        $clubIsVisible = !Schema::hasColumn('clubs', 'is_visible') || (bool) $club->is_visible;
        abort_unless(!$isPublicViewer || ($clubIsActive && $clubIsVisible), 403);

        $month = trim((string) $request->query('month', now()->format('Y-m')));
        abort_unless((bool) preg_match('/^\\d{4}-(0[1-9]|1[0-2])$/', $month), 422, 'El mes debe tener el formato YYYY-MM.');
        $start = now()->createFromFormat('Y-m', $month)->startOfMonth();
        $end = $start->copy()->endOfMonth();
        $query = GroupPichanga::query()
            ->where(function ($q) use ($club) {
                $q->where('club_id', $club->id);
                if (Schema::hasColumn('group_pichangas', 'rival_club_id')) {
                    $q->orWhere('rival_club_id', $club->id);
                }
            })
            ->whereBetween('starts_at', [$start, $end]);
        if ($isPublicViewer) {
            $query->where('is_open', true)->where('starts_at', '>=', now())->whereIn('status', ['published', 'confirmed']);
        }
        $pichangas = $query->orderBy('starts_at')->limit(400)->get();
        $venues = $this->venuesForPichangas($pichangas);
        $participantStatuses = $this->participantStatusesFor($pichangas, $auth?->id);
        return response()->json([
            'items' => $pichangas->map(fn (GroupPichanga $p) => $this->serializePichanga(
                $p,
                array_merge(
                    $venues[(int) $p->id] ?? [],
                    ['me_participant_status' => $participantStatuses[(int) $p->id] ?? null],
                    $this->detailPresentation($p, null, $isMember, null),
                ),
            ))->values(),
            'meta' => ['month' => $month],
        ]);
    }

    public function available(Request $request)
    {
        $auth = $request->user() ?? abort(401);
        $now = now();
        $monthlyPlayedCount = $this->monthlyPlayedCount((int) $auth->id, $now);
        $days = (int) $request->query('days', 0);
        $days = $days > 0 ? max(1, min(14, $days)) : 0;

        $userClubIds = ClubUser::query()
            ->where('user_id', $auth->id)
            ->active()
            ->pluck('club_id')
            ->map(fn($i) => (int) $i)
            ->all();
        $baseQuery = GroupPichanga::query()
            ->whereIn('status', ['published', 'confirmed'])
            ->where('starts_at', '>=', $now);
        if ($days > 0) {
            $baseQuery->where('starts_at', '<=', $now->copy()->addDays($days - 1)->endOfDay());
        }

        $base = $baseQuery->orderBy('starts_at')->limit(300)->get();
        if ($base->isEmpty()) {
            return response()->json([
                'items' => [],
                'meta' => [
                    'monthly_played_count' => $monthlyPlayedCount,
                ],
            ]);
        }

        $pichangaIds = $base->pluck('id')->map(fn($id) => (int) $id)->all();

        $confirmedCountByPichanga = GroupPichangaParticipant::query()
            ->selectRaw('pichanga_id, COUNT(*) AS total')
            ->whereIn('pichanga_id', $pichangaIds)
            ->where('status', 'confirmed')
            ->groupBy('pichanga_id')
            ->pluck('total', 'pichanga_id')
            ->map(fn($count) => (int) $count);

        $participantStatusByPichanga = GroupPichangaParticipant::query()
            ->whereIn('pichanga_id', $pichangaIds)
            ->where('user_id', $auth->id)
            ->pluck('status', 'pichanga_id')
            ->map(fn($status) => $status !== null ? (string) $status : null);

        $externalRequestStatusByPichanga = GroupPichangaExternalRequest::query()
            ->whereIn('pichanga_id', $pichangaIds)
            ->where('user_id', $auth->id)
            ->pluck('status', 'pichanga_id')
            ->map(fn($status) => $status !== null ? (string) $status : null);

        $items = [];
        foreach ($base as $pichanga) {
            $pichangaId = (int) $pichanga->id;
            $isMember = $this->isMemberOfPichanga($pichanga, $userClubIds);
            $participantStatus = $participantStatusByPichanga->get($pichangaId);
            $externalRequestStatus = $externalRequestStatusByPichanga->get($pichangaId);

            $extra = [
                '_confirmed_count' => $confirmedCountByPichanga->get($pichangaId, 0),
                'me_is_member' => $isMember,
                'me_participant_status' => $participantStatus,
                'me_external_request_status' => $externalRequestStatus,
            ];

            if ($isMember) {
                $extra['me_pending_kind'] = $participantStatus === 'confirmed' ? null : 'pending_group';
                $items[] = $this->serializePichanga($pichanga, $extra);
                continue;
            }

            if (!$pichanga->is_open && !$pichanga->allow_external_requests) {
                continue;
            }

            $eligibility = $this->audienceService->externalEligibility($pichanga, (int) $auth->id);
            if (!$eligibility['eligible']) {
                continue;
            }

            $items[] = $this->serializePichanga($pichanga, array_merge($extra, [
                'eligible_external_degree' => $eligibility['degree'],
                'me_pending_kind' => $participantStatus === 'confirmed' ? null : 'pending_open',
            ]));
        }

        return response()->json([
            'items' => $items,
            'meta' => [
                'monthly_played_count' => $monthlyPlayedCount,
            ],
        ]);
    }

    /** Public/open pichangas plus the authenticated user's own relevant matches. */
    public function map(Request $request)
    {
        $auth = $request->user();
        $data = $request->validate([
            'range' => ['nullable', Rule::in(['today', 'today_tomorrow', 'custom'])],
            'from' => ['nullable', 'date_format:Y-m-d'],
            'to' => ['nullable', 'date_format:Y-m-d', 'after_or_equal:from'],
        ]);
        $range = $data['range'] ?? 'today';
        $from = $range === 'custom' ? now()->createFromFormat('Y-m-d', $data['from'] ?? now()->format('Y-m-d'))->startOfDay() : now()->startOfDay();
        $to = $range === 'custom' ? now()->createFromFormat('Y-m-d', $data['to'] ?? $from->format('Y-m-d'))->endOfDay() : $from->copy()->addDays($range === 'today_tomorrow' ? 1 : 0)->endOfDay();
        $mineClubIds = []; $minePichangaIds = [];
        if ($auth) {
            $mineClubIds = ClubUser::query()->where('user_id', $auth->id)->active()->pluck('club_id')->map(fn ($id) => (int) $id)->all();
            $minePichangaIds = GroupPichangaParticipant::query()->where('user_id', $auth->id)->pluck('pichanga_id')->map(fn ($id) => (int) $id)->all();
            if (Schema::hasColumn('group_pichangas', 'created_by_user_id')) $minePichangaIds = array_values(array_unique(array_merge($minePichangaIds, GroupPichanga::query()->where('created_by_user_id', $auth->id)->pluck('id')->map(fn ($id) => (int) $id)->all())));
        }
        $query = GroupPichanga::query()
            ->whereIn('status', ['published', 'confirmed'])
            ->where('is_open', true)
            ->whereBetween('starts_at', [$from, $to]);
        $query->where(function ($q) use ($mineClubIds, $minePichangaIds) {
            $q->where(function ($public) {
                $public->where('is_open', true)->whereHas('club', function ($club) {
                    if (Schema::hasColumn('clubs', 'estado')) $club->where('estado', 1);
                    if (Schema::hasColumn('clubs', 'is_visible')) $club->where('is_visible', true);
                });
            });
            if ($mineClubIds) $q->orWhereIn('club_id', $mineClubIds);
            if ($minePichangaIds) $q->orWhereIn('id', $minePichangaIds);
        });
        $pichangas = $query->orderBy('starts_at')->limit(800)->get();
        $pichangaIds = $pichangas->pluck('id')->map(fn($id) => (int) $id)->all();
        $confirmedByPichanga = GroupPichangaParticipant::query()
            ->selectRaw('pichanga_id, COUNT(*) AS total')
            ->whereIn('pichanga_id', $pichangaIds)
            ->where('status', 'confirmed')
            ->groupBy('pichanga_id')
            ->pluck('total', 'pichanga_id')
            ->map(fn($count) => (int) $count);
        $participantStatusByPichanga = $auth
            ? GroupPichangaParticipant::query()
                ->whereIn('pichanga_id', $pichangaIds)
                ->where('user_id', $auth->id)
                ->pluck('status', 'pichanga_id')
                ->map(fn($status) => $status !== null ? (string) $status : null)
            : collect();
        $pichangas = $pichangas
            ->filter(fn(GroupPichanga $pichanga) =>
                $confirmedByPichanga->get((int) $pichanga->id, 0) < (int) $pichanga->capacity
            )
            ->values();
        $venues = $this->venuesForPichangas($pichangas);
        $fieldIds = collect($venues)->pluck('venue_field_id')->filter()->unique();
        $fields = $fieldIds->isEmpty() ? collect() : Polideportivo::query()->whereIn('id', $fieldIds)->get()->keyBy('id');
        $groups = [];
        foreach ($pichangas as $p) {
            $venue = $venues[$p->id] ?? []; $field = $fields->get($venue['venue_field_id'] ?? 0); if (!$field || !$field->x || !$field->y) continue;
            $isMyGroup = $this->isMemberOfPichanga($p, $mineClubIds);
            $mine = in_array((int) $p->id, $minePichangaIds, true) || $isMyGroup;
            $confirmed = $confirmedByPichanga->get((int) $p->id, 0);
            $key = (int) $field->id;
            $groups[$key] ??= ['field_id' => $key, 'latitude' => (float) $field->x, 'longitude' => (float) $field->y, 'field_name' => $field->nombre, 'public_count' => 0, 'mine_count' => 0, 'items' => []];
            $groups[$key][$mine ? 'mine_count' : 'public_count']++;
            $groups[$key]['items'][] = [
                'id' => (int) $p->id,
                'title' => $p->title,
                'starts_at' => $p->starts_at?->toISOString(),
                'court_name' => $venue['court_name'] ?? null,
                'field_name' => $venue['field_name'] ?? $field->nombre,
                'capacity' => (int) $p->capacity,
                'confirmed_count' => $confirmed,
                'spots_left' => max(0, (int) $p->capacity - $confirmed),
                'is_mine' => $mine,
                'is_my_group' => $isMyGroup,
                'me_participant_status' => $participantStatusByPichanga->get((int) $p->id),
            ];
        }
        return response()->json(['items' => array_values($groups), 'meta' => ['range' => $range, 'from' => $from->toDateString(), 'to' => $to->toDateString()]]);
    }

    public function myBoard(Request $request)
    {
        $auth = $request->user() ?? abort(401);
        $now = now();
        $days = max(1, min(14, (int) $request->query('days', 7)));
        $terminatedLimit = max(20, min(500, (int) $request->query('terminated_limit', 200)));
        $page = max(1, (int) $request->query('page', 1));

        $todayStart = $now->copy()->startOfDay();
        $windowEnd = $todayStart->copy()->addDays($days)->endOfDay();
        $hasRivalColumn = Schema::hasColumn('group_pichangas', 'rival_club_id');
        $hasCreatedByColumn = Schema::hasColumn('group_pichangas', 'created_by_user_id');
        $watchTableReady = Schema::hasTable('watch_match_sessions');

        $clubIds = ClubUser::query()
            ->where('user_id', (int) $auth->id)
            ->active()
            ->pluck('club_id')
            ->map(fn($id) => (int) $id)
            ->unique()
            ->values()
            ->all();

        $participantRows = GroupPichangaParticipant::query()
            ->where('user_id', (int) $auth->id)
            ->get(['pichanga_id', 'status']);
        $participantStatusByPichanga = $participantRows
            ->mapWithKeys(fn(GroupPichangaParticipant $row) => [(int) $row->pichanga_id => (string) $row->status])
            ->all();
        $participantPichangaIds = array_keys($participantStatusByPichanga);

        $createdByIds = [];
        if ($hasCreatedByColumn) {
            $createdByIds = GroupPichanga::query()
                ->where('created_by_user_id', (int) $auth->id)
                ->pluck('id')
                ->map(fn($id) => (int) $id)
                ->unique()
                ->values()
                ->all();
        }

        if (empty($clubIds) && empty($participantPichangaIds) && empty($createdByIds)) {
            return response()->json([
                'confirmed_items' => [],
                'pending_items' => [],
                'terminated_items' => [],
                'meta' => [
                    'days' => $days,
                    'window_from' => $todayStart->toISOString(),
                    'window_to' => $windowEnd->toISOString(),
                    'terminated_limit' => $terminatedLimit,
                    'page' => $page,
                ],
            ]);
        }

        $query = GroupPichanga::query()
            ->whereIn('status', ['published', 'confirmed'])
            ->where(function ($scope) use ($clubIds, $participantPichangaIds, $createdByIds, $hasRivalColumn) {
                $appliedAny = false;
                if (!empty($clubIds)) {
                    $scope->whereIn('club_id', $clubIds);
                    if ($hasRivalColumn) {
                        $scope->orWhereIn('rival_club_id', $clubIds);
                    }
                    $appliedAny = true;
                }
                if (!empty($participantPichangaIds)) {
                    if ($appliedAny) {
                        $scope->orWhereIn('id', $participantPichangaIds);
                    } else {
                        $scope->whereIn('id', $participantPichangaIds);
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

        $pichangas = $query->limit(2000)->get();
        $venues = $this->venuesForPichangas($pichangas);

        $confirmedItems = [];
        $pendingItems = [];
        $terminatedItems = [];
        foreach ($pichangas as $pichanga) {
            if (!$pichanga->starts_at) {
                continue;
            }

            $startAt = $pichanga->starts_at->copy();
            $durationMinutes = max(1, (int) ($pichanga->duration_minutes ?? 90));
            $endAt = $startAt->copy()->addMinutes($durationMinutes);
            $isTerminated = $now->gt($endAt);
            $isInProgress = $startAt->lte($now) && $endAt->gte($now);

            $isWithinUpcomingWindow = $startAt->gte($todayStart) && $startAt->lte($windowEnd);
            $isRelevantNow = $isInProgress || $isWithinUpcomingWindow;

            $meParticipantStatus = $participantStatusByPichanga[(int) $pichanga->id] ?? null;
            $isConfirmed = $meParticipantStatus === 'confirmed';

            $extra = [
                '_me_user_id' => (int) $auth->id,
                'me_participant_status' => $meParticipantStatus,
                'end_at' => $endAt->toISOString(),
                'is_in_progress' => $isInProgress,
                'watch_used' => false,
            ];
            $serialized = $this->serializePichanga(
                $pichanga,
                array_merge($extra, $venues[(int) $pichanga->id] ?? [])
            );

            if ($isTerminated) {
                $terminatedItems[] = $serialized;
                continue;
            }
            if (!$isRelevantNow) {
                continue;
            }

            if ($isConfirmed) {
                $confirmedItems[] = $serialized;
            } else {
                $pendingItems[] = $serialized;
            }
        }

        usort($confirmedItems, fn($a, $b) => strcmp((string) ($a['starts_at'] ?? ''), (string) ($b['starts_at'] ?? '')));
        usort($pendingItems, fn($a, $b) => strcmp((string) ($a['starts_at'] ?? ''), (string) ($b['starts_at'] ?? '')));
        usort($terminatedItems, fn($a, $b) => strcmp((string) ($b['starts_at'] ?? ''), (string) ($a['starts_at'] ?? '')));

        $offset = ($page - 1) * $terminatedLimit;
        $terminatedPage = array_slice($terminatedItems, $offset, $terminatedLimit);

        if ($watchTableReady) {
            $idsForWatchLookup = collect($confirmedItems)
                ->merge($terminatedPage)
                ->map(fn($item) => (int) ($item['id'] ?? 0))
                ->filter(fn($id) => $id > 0)
                ->unique()
                ->values()
                ->all();

            if (!empty($idsForWatchLookup)) {
                $watchUsedSet = WatchMatchSession::query()
                    ->where('user_id', (int) $auth->id)
                    ->whereIn('group_pichanga_id', $idsForWatchLookup)
                    ->pluck('group_pichanga_id')
                    ->map(fn($id) => (int) $id)
                    ->unique()
                    ->values()
                    ->all();
                $watchLookup = array_fill_keys($watchUsedSet, true);

                $confirmedItems = array_map(function (array $item) use ($watchLookup) {
                    $item['watch_used'] = isset($watchLookup[(int) ($item['id'] ?? 0)]);
                    return $item;
                }, $confirmedItems);

                $terminatedPage = array_map(function (array $item) use ($watchLookup) {
                    $item['watch_used'] = isset($watchLookup[(int) ($item['id'] ?? 0)]);
                    return $item;
                }, $terminatedPage);
            }
        }

        return response()->json([
            'confirmed_items' => array_values($confirmedItems),
            'pending_items' => array_values($pendingItems),
            'terminated_items' => array_values($terminatedPage),
            'meta' => [
                'days' => $days,
                'window_from' => $todayStart->toISOString(),
                'window_to' => $windowEnd->toISOString(),
                'terminated_limit' => $terminatedLimit,
                'page' => $page,
                'terminated_total' => count($terminatedItems),
                'terminated_has_more' => ($offset + count($terminatedPage)) < count($terminatedItems),
            ],
        ]);
    }

    /**
     * Returns one navigable calendar month of pichangas relevant to the
     * authenticated user. Historical months are intentionally loaded on
     * demand instead of downloading the entire history with the board.
     */
    public function calendar(Request $request)
    {
        $auth = $request->user() ?? abort(401);
        $month = trim((string) $request->query('month', now()->format('Y-m')));
        abort_unless((bool) preg_match('/^\\d{4}-(0[1-9]|1[0-2])$/', $month), 422, 'El mes debe tener el formato YYYY-MM.');

        $monthStart = now()->createFromFormat('Y-m', $month)->startOfMonth();
        $monthEnd = $monthStart->copy()->endOfMonth();
        $hasRivalColumn = Schema::hasColumn('group_pichangas', 'rival_club_id');
        $hasCreatedByColumn = Schema::hasColumn('group_pichangas', 'created_by_user_id');

        $clubIds = ClubUser::query()
            ->where('user_id', (int) $auth->id)
            ->active()
            ->pluck('club_id')
            ->map(fn($id) => (int) $id)
            ->unique()
            ->values()
            ->all();
        $participantRows = GroupPichangaParticipant::query()
            ->where('user_id', (int) $auth->id)
            ->get(['pichanga_id', 'status']);
        $participantStatusByPichanga = $participantRows
            ->mapWithKeys(fn(GroupPichangaParticipant $row) => [(int) $row->pichanga_id => (string) $row->status])
            ->all();
        $participantPichangaIds = array_keys($participantStatusByPichanga);
        $createdByIds = $hasCreatedByColumn
            ? GroupPichanga::query()
                ->where('created_by_user_id', (int) $auth->id)
                ->pluck('id')
                ->map(fn($id) => (int) $id)
                ->unique()
                ->values()
                ->all()
            : [];

        if (empty($clubIds) && empty($participantPichangaIds) && empty($createdByIds)) {
            return response()->json([
                'items' => [],
                'meta' => ['month' => $month],
            ]);
        }

        $pichangas = GroupPichanga::query()
            ->whereIn('status', ['published', 'confirmed'])
            ->whereBetween('starts_at', [$monthStart, $monthEnd])
            ->where(function ($scope) use ($clubIds, $participantPichangaIds, $createdByIds, $hasRivalColumn) {
                $appliedAny = false;
                if (!empty($clubIds)) {
                    $scope->whereIn('club_id', $clubIds);
                    if ($hasRivalColumn) {
                        $scope->orWhereIn('rival_club_id', $clubIds);
                    }
                    $appliedAny = true;
                }
                if (!empty($participantPichangaIds)) {
                    $appliedAny ? $scope->orWhereIn('id', $participantPichangaIds) : $scope->whereIn('id', $participantPichangaIds);
                    $appliedAny = true;
                }
                if (!empty($createdByIds)) {
                    $appliedAny ? $scope->orWhereIn('id', $createdByIds) : $scope->whereIn('id', $createdByIds);
                }
            })
            ->orderBy('starts_at')
            ->limit(2000)
            ->get();
        $venues = $this->venuesForPichangas($pichangas);
        $now = now();

        $items = $pichangas->map(function (GroupPichanga $pichanga) use ($auth, $now, $participantStatusByPichanga, $venues) {
            $startAt = $pichanga->starts_at->copy();
            $endAt = $startAt->copy()->addMinutes(max(1, (int) ($pichanga->duration_minutes ?? 90)));
            $isTerminated = $now->gt($endAt);
            $participantStatus = $participantStatusByPichanga[(int) $pichanga->id] ?? null;
            $section = $isTerminated
                ? 'terminated'
                : ($participantStatus === 'confirmed' ? 'confirmed' : 'pending');

            return $this->serializePichanga($pichanga, array_merge([
                '_me_user_id' => (int) $auth->id,
                'me_participant_status' => $participantStatus,
                'end_at' => $endAt->toISOString(),
                'is_in_progress' => !$isTerminated && $startAt->lte($now),
                'calendar_section' => $section,
            ], $venues[(int) $pichanga->id] ?? []));
        })->values();

        return response()->json([
            'items' => $items,
            'meta' => [
                'month' => $month,
                'from' => $monthStart->toISOString(),
                'to' => $monthEnd->toISOString(),
            ],
        ]);
    }

    public function confirmedNextWidget(Request $request)
    {
        $auth = $request->user() ?? abort(401);
        $now = now();
        $limit = min(3, max(1, (int) $request->query('limit', 3)));

        $pichangaIds = GroupPichangaParticipant::query()
            ->join('group_pichangas as gp', 'gp.id', '=', 'group_pichanga_participants.pichanga_id')
            ->where('group_pichanga_participants.user_id', (int) $auth->id)
            ->where('group_pichanga_participants.status', 'confirmed')
            ->where('gp.starts_at', '>=', $now)
            ->whereIn('gp.status', ['published', 'confirmed'])
            ->orderBy('gp.starts_at')
            ->limit($limit)
            ->pluck('gp.id')
            ->map(fn($id) => (int) $id)
            ->unique()
            ->values()
            ->all();

        if (empty($pichangaIds)) {
            return response()->json([
                'items' => [],
            ]);
        }

        $items = GroupPichanga::query()
            ->whereIn('id', $pichangaIds)
            ->orderBy('starts_at')
            ->get()
            ->map(function (GroupPichanga $pichanga) use ($auth) {
                $serialized = $this->serializePichanga($pichanga, [
                    '_me_user_id' => (int) $auth->id,
                    'me_participant_status' => 'confirmed',
                ]);

                $teams = collect($serialized['teams'] ?? [])
                    ->filter(fn($team) => is_array($team))
                    ->map(function (array $team) {
                        $slots = collect($team['slots'] ?? [])
                            ->filter(fn($slot) => is_array($slot))
                            ->map(function (array $slot) {
                                $user = is_array($slot['user'] ?? null) ? $slot['user'] : null;
                                return [
                                    'slot' => (int) ($slot['slot'] ?? 0),
                                    'user' => $user ? [
                                        'name' => $user['name'] ?? null,
                                        'nick' => $user['nick'] ?? null,
                                        'is_me' => (bool) ($user['is_me'] ?? false),
                                    ] : null,
                                ];
                            })
                            ->values()
                            ->all();

                        return [
                            'code' => (string) ($team['code'] ?? ''),
                            'avg_rating' => $team['avg_rating'] ?? null,
                            'slots' => $slots,
                        ];
                    })
                    ->values()
                    ->all();

                return [
                    'id' => (int) $serialized['id'],
                    'title' => $serialized['title'],
                    'starts_at' => $serialized['starts_at'],
                    'duration_minutes' => (int) ($serialized['duration_minutes'] ?? 0),
                    'match_format' => $serialized['match_format'] ?? null,
                    'team_count' => (int) ($serialized['team_count'] ?? 0),
                    'players_per_team' => (int) ($serialized['players_per_team'] ?? 0),
                    'me_participant_status' => 'confirmed',
                    'share_url' => $serialized['share_url'] ?? $this->buildPichangaShareUrl((int) $serialized['id']),
                    'teams' => $teams,
                ];
            })
            ->values();

        return response()->json([
            'items' => $items,
        ]);
    }

    public function store(Request $request, Club $club)
    {
        $auth = $request->user() ?? abort(401);
        abort_unless($this->canCreatePichanga($club, $auth->id, (bool) $auth->is_superadmin), 403);

        $data = $request->validate([
            'title' => ['nullable', 'string', 'max:160'],
            'description' => ['nullable', 'string'],
            'field_id' => ['nullable', 'integer'],
            'cancha_id' => ['nullable', 'integer', 'min:1'],
            'address' => ['nullable', 'string', 'max:255'],
            'starts_at' => ['required', 'date'],
            'duration_minutes' => ['required', 'integer', 'min:30', 'max:600'],
            'capacity' => ['nullable', 'integer', 'min:2', 'max:200'],
            'match_format' => ['nullable', Rule::in(['versus', 'triangular', 'cuadrangular'])],
            'players_per_team' => ['nullable', 'integer', 'min:5', 'max:11'],
            'status' => ['nullable', Rule::in(['published', 'confirmed'])],
            'confirmation_mode' => ['nullable', Rule::in(['auto_by_capacity', 'manual_paid'])],
            'is_open' => ['nullable', 'boolean'],
            'notify_degree' => ['nullable', 'integer', 'min:1', 'max:3'],
            'allow_external_requests' => ['nullable', 'boolean'],
            'auto_reminder_enabled' => ['nullable', 'boolean'],
            'withdraw_until' => ['nullable', 'date'],
            'audience_sex' => ['nullable', Rule::in(['M', 'F'])],
            'audience_age_min' => ['nullable', 'integer', 'min:14', 'max:80'],
            'audience_age_max' => ['nullable', 'integer', 'min:14', 'max:80'],
            'skill_fisico_min' => ['nullable', 'numeric', 'min:0', 'max:5', 'decimal:0,1'],
            'skill_arquero_min' => ['nullable', 'numeric', 'min:0', 'max:5', 'decimal:0,1'],
            'skill_delantero_min' => ['nullable', 'numeric', 'min:0', 'max:5', 'decimal:0,1'],
            'skill_mediocampo_min' => ['nullable', 'numeric', 'min:0', 'max:5', 'decimal:0,1'],
            'skill_defensa_min' => ['nullable', 'numeric', 'min:0', 'max:5', 'decimal:0,1'],
        ]);

        if (!empty($data['audience_age_min']) && !empty($data['audience_age_max'])) {
            abort_if((int) $data['audience_age_min'] > (int) $data['audience_age_max'], 422, 'Rango de edad inválido.');
        }

        if (!empty($data['cancha_id'])) {
            $cancha = Cancha::query()->find((int) $data['cancha_id']);
            abort_if(!$cancha, 422, 'La cancha no existe.');
            $data['field_id'] = (int) ($data['field_id'] ?? $cancha->id_polideportivo);
        }

        $maxDegree = (int) ($club->audience_max_degree ?? 1);
        $notifyDegree = min(max((int) ($data['notify_degree'] ?? 1), 1), max(1, $maxDegree));
        $allowExternal = (bool) ($data['allow_external_requests'] ?? ($notifyDegree > 1));
        $matchFormat = (string) ($data['match_format'] ?? 'versus');
        $teamCount = $this->teamCountFromFormat($matchFormat);

        $playersPerTeam = null;
        if (array_key_exists('players_per_team', $data) && $data['players_per_team'] !== null) {
            $playersPerTeam = (int) $data['players_per_team'];
        } elseif (!empty($data['capacity'])) {
            // Compat temporal para clientes viejos que aún envían "capacity".
            $playersPerTeam = (int) ceil(((int) $data['capacity']) / $teamCount);
            $playersPerTeam = max(5, min(11, $playersPerTeam));
        } else {
            $playersPerTeam = 7;
        }
        abort_if($playersPerTeam === null || $playersPerTeam < 5 || $playersPerTeam > 11, 422, 'Jugadores por equipo inválido (5-11).');

        $capacity = $teamCount * $playersPerTeam;

        $payload = array_merge($data, [
            'club_id' => $club->id,
            'created_by_user_id' => $auth->id,
            'notify_degree' => $notifyDegree,
            'allow_external_requests' => $allowExternal,
            'match_format' => $matchFormat,
            'team_count' => $teamCount,
            'players_per_team' => $playersPerTeam,
            'capacity' => $capacity,
            'status' => $data['status'] ?? 'published',
            'confirmation_mode' => $data['confirmation_mode'] ?? 'auto_by_capacity',
            'is_open' => (bool) ($data['is_open'] ?? false),
            'auto_reminder_enabled' => (bool) ($data['auto_reminder_enabled'] ?? ($club->auto_reminder_enabled ?? true)),
        ]);
        $payload = $this->filterPayloadByTableColumns('group_pichangas', $payload);

        $pichanga = GroupPichanga::create($payload);

        $audience = $this->audienceService->resolveAudience($pichanga);
        $targetIds = collect($audience['target_user_ids'])->map(fn($id) => (int) $id)->unique()->values();
        $notMuted = $this->muteService->filterNotMutedUserIds($targetIds, (int) $club->id);
        $mutedSkipped = $targetIds->count() - $notMuted->count();

        $sent = $this->clubNotifications->notifyUsers($club, $targetIds->all(), [
            'group_pichanga_id' => $pichanga->id,
            'type' => 'pichanga_created',
            'category' => 'pichangas',
            'title' => 'Nueva pichanga',
            'body' => (string) ($pichanga->title ?: 'Se creó una pichanga en tu grupo'),
            'target_type' => 'pichanga',
            'target_id' => (int) $pichanga->id,
            'image_kind' => 'pichanga',
            'image_url' => $this->pichangaImageUrl($pichanga),
            'data_json' => ['pichanga_id' => $pichanga->id],
        ], (int) $auth->id);

        GroupPichangaNotificationBatch::create([
            'pichanga_id' => $pichanga->id,
            'triggered_by_user_id' => $auth->id,
            'batch_type' => 'initial',
            'target_degree' => (int) $audience['target_degree'],
            'filters_json' => $audience['filters'],
            'target_count' => $targetIds->count(),
            'muted_skipped_count' => $mutedSkipped,
            'sent_count' => $sent,
        ]);

        $this->refreshAutoStatus($pichanga);
        $this->eventService->track('pichanga_created', (int) $auth->id, (int) $club->id, (int) $pichanga->id, [
            'notify_degree' => (int) $pichanga->notify_degree,
            'capacity' => (int) $pichanga->capacity,
        ]);

        return response()->json([
            'message' => 'Pichanga creada.',
            'pichanga' => $this->serializePichanga($pichanga->fresh()),
        ], 201);
    }

    public function show(Request $request, GroupPichanga $pichanga)
    {
        $auth = $request->user();
        if (!$auth) {
            $club = $pichanga->club;
            $isPublic = $club
                && (!Schema::hasColumn('clubs', 'estado') || (int) $club->estado === 1)
                && (!Schema::hasColumn('clubs', 'is_visible') || (bool) $club->is_visible)
                && (bool) $pichanga->is_open
                && $pichanga->starts_at
                && $pichanga->starts_at->gte(now())
                && in_array((string) $pichanga->status, ['published', 'confirmed'], true);
            abort_unless($isPublic, 403);

            return response()->json([
                'pichanga' => $this->serializePichanga(
                    $pichanga,
                    array_merge(
                        $this->venuesForPichangas(collect([$pichanga]))[(int) $pichanga->id] ?? [],
                        $this->detailPresentation($pichanga, null, false, null)
                    ),
                ),
                'me' => [
                    'is_member' => false,
                    'is_admin' => false,
                    'participant_status' => null,
                    'participant_team_code' => null,
                    'participant_team_slot' => null,
                    'external_request_status' => null,
                ],
            ]);
        }
        $userClubIds = ClubUser::query()
            ->where('user_id', $auth->id)
            ->active()
            ->pluck('club_id')
            ->map(fn($i) => (int) $i)
            ->all();
        $isMember = $this->isMemberOfPichanga($pichanga, $userClubIds);
        // Some lightweight API test databases do not include the legacy profile
        // tables that back this accessor. In production this preserves the same
        // superadmin rule while keeping the detail endpoint self-contained.
        $isSuper = Schema::hasTable('perfil')
            && Schema::hasTable('user_perfil')
            && (bool) $auth->is_superadmin;
        $isAdmin = $this->isClubAdminForPichanga($pichanga, (int) $auth->id) || $isSuper;

        $allowed = $isMember;
        if (!$allowed && ($pichanga->is_open || $pichanga->allow_external_requests)) {
            $allowed = $this->audienceService->externalEligibility($pichanga, (int) $auth->id)['eligible'];
        }
        abort_unless($allowed || $isAdmin, 403);

        $meParticipant = GroupPichangaParticipant::where('pichanga_id', $pichanga->id)->where('user_id', $auth->id)->first();
        $meRequest = GroupPichangaExternalRequest::where('pichanga_id', $pichanga->id)->where('user_id', $auth->id)->first();
        $meWaitlist = Schema::hasTable('group_pichanga_waitlist')
            ? GroupPichangaWaitlistEntry::query()->where('pichanga_id', $pichanga->id)->where('user_id', $auth->id)->first()
            : null;
        $presentation = $this->detailPresentation(
            $pichanga,
            $meParticipant,
            $isMember,
            $meRequest?->status
        );

        return response()->json([
            'pichanga' => $this->serializePichanga($pichanga, array_merge([
                '_me_user_id' => (int) $auth->id,
            ], $this->venuesForPichangas(collect([$pichanga]))[(int) $pichanga->id] ?? [], $presentation)),
            'me' => [
                'is_member' => $isMember,
                'is_admin' => $isAdmin,
                'participant_status' => $meParticipant?->status,
                'participant_team_code' => Schema::hasColumn('group_pichanga_participants', 'team_code') ? $meParticipant?->team_code : null,
                'participant_team_slot' => Schema::hasColumn('group_pichanga_participants', 'team_slot') ? $meParticipant?->team_slot : null,
                'external_request_status' => $meRequest?->status,
                'can_confirm' => $presentation['can_confirm'],
                'can_request_external' => $presentation['can_request_external'],
                'can_change_team' => $presentation['can_change_team'],
                'can_withdraw' => $presentation['can_withdraw'],
                'waitlist_status' => $meWaitlist?->status,
                'waitlist_position' => $meWaitlist?->status === 'waiting'
                    ? $this->waitlistPosition($meWaitlist)
                    : null,
            ],
        ]);
    }

    /**
     * A privacy-safe, event-backed summary for a finished match. No score is
     * manufactured: a match without synced Watch events deliberately returns
     * empty events and zero totals.
     */
    public function matchSummary(Request $request, GroupPichanga $pichanga)
    {
        $club = $pichanga->club;
        $endAt = $pichanga->starts_at?->copy()->addMinutes(max(1, (int) $pichanga->duration_minutes));
        $finished = in_array((string) $pichanga->status, ['completed', 'cancelled'], true)
            || ($endAt && now()->gt($endAt));
        abort_unless($finished, 422, 'El resumen estará disponible al terminar la pichanga.');

        $auth = $request->user();
        $isPublic = $club
            && (!Schema::hasColumn('clubs', 'estado') || (int) $club->estado === 1)
            && (!Schema::hasColumn('clubs', 'is_visible') || (bool) $club->is_visible)
            && (bool) $pichanga->is_open;
        $isConfirmed = $auth && GroupPichangaParticipant::query()
            ->where('pichanga_id', $pichanga->id)
            ->where('user_id', $auth->id)
            ->where('status', 'confirmed')
            ->exists();
        $isAdmin = $auth && $this->isClubAdminForPichanga($pichanga, (int) $auth->id);
        abort_unless($isPublic || $isConfirmed || $isAdmin, 403);

        if (!Schema::hasTable('watch_match_sessions') || !Schema::hasTable('watch_match_events')) {
            return response()->json($this->emptyMatchSummary($pichanga));
        }

        $playerColumns = ['users.id as user_id', 'users.name'];
        if (Schema::hasColumn('users', 'nick')) {
            $playerColumns[] = 'users.nick';
        }
        if (Schema::hasColumn('users', 'avatar_url')) {
            $playerColumns[] = 'users.avatar_url';
        }
        $rows = WatchMatchEvent::query()
            ->join('watch_match_sessions as sessions', 'sessions.id', '=', 'watch_match_events.session_id')
            ->join('group_pichanga_participants as participants', function ($join) use ($pichanga) {
                $join->on('participants.user_id', '=', 'sessions.user_id')
                    ->where('participants.pichanga_id', '=', $pichanga->id)
                    ->where('participants.status', '=', 'confirmed');
            })
            ->join('users', 'users.id', '=', 'sessions.user_id')
            ->where('sessions.group_pichanga_id', $pichanga->id)
            ->whereIn('watch_match_events.event_type', ['goal', 'assist'])
            ->orderBy('watch_match_events.event_at')
            ->orderBy('watch_match_events.id')
            ->get(array_merge([
                'watch_match_events.id', 'watch_match_events.event_type', 'watch_match_events.event_at',
                'watch_match_events.minute', 'watch_match_events.clock_time', 'watch_match_events.metadata_json',
                'participants.team_code',
            ], $playerColumns));

        $score = [];
        $events = $rows->map(function ($row) use (&$score) {
            $team = strtoupper((string) ($row->team_code ?? '?'));
            if ((string) $row->event_type === 'goal') {
                $score[$team] = ($score[$team] ?? 0) + 1;
            }
            return [
                'id' => (int) $row->id,
                'type' => (string) $row->event_type,
                'minute' => $row->minute === null ? null : (int) $row->minute,
                'clock_time' => $row->clock_time,
                'event_at' => $row->event_at ? \Illuminate\Support\Carbon::parse($row->event_at)->toISOString() : null,
                'team_code' => $team,
                'player' => [
                    'id' => (int) $row->user_id,
                    'name' => $row->name,
                    'nick' => $row->nick,
                    'avatar_url' => $row->avatar_url,
                ],
            ];
        })->values();

        return response()->json([
            'pichanga_id' => (int) $pichanga->id,
            'has_watch_data' => $events->isNotEmpty(),
            'score' => collect($score)->map(fn ($goals, $team) => ['team_code' => $team, 'goals' => $goals])->values(),
            'totals' => [
                'goals' => $events->where('type', 'goal')->count(),
                'assists' => $events->where('type', 'assist')->count(),
            ],
            'events' => $events,
        ]);
    }

    public function formationSuggestion(Request $request, GroupPichanga $pichanga, string $teamCode)
    {
        $auth = $request->user() ?? abort(401);
        $team = $this->validatedTeamCode($pichanga, $teamCode);
        $this->ensureFormationReadable($pichanga, (int) $auth->id, $team);
        return response()->json([
            'team_code' => $team,
            'formation' => $this->suggestFormation($pichanga, $team),
        ]);
    }

    public function updateFormation(Request $request, GroupPichanga $pichanga, string $teamCode)
    {
        $auth = $request->user() ?? abort(401);
        $team = $this->validatedTeamCode($pichanga, $teamCode);
        $isAdmin = $this->isClubAdminForPichanga($pichanga, (int) $auth->id);
        $this->ensureFormationMutable($pichanga, (int) $auth->id, $team, $isAdmin);
        $data = $request->validate([
            'positions' => ['required', 'array', 'min:1'],
            'positions.*.user_id' => ['required', 'integer'],
            'positions.*.formation_role' => ['required', Rule::in(['goalkeeper', 'defender', 'midfielder', 'forward'])],
            'positions.*.formation_order' => ['required', 'integer', 'min:1', 'max:99'],
            'positions.*.formation_x' => ['nullable', 'numeric', 'between:0,1'],
            'positions.*.formation_y' => ['nullable', 'numeric', 'between:0,1'],
        ]);
        $ids = collect($data['positions'])->pluck('user_id')->map(fn ($id) => (int) $id)->unique()->values();
        $teamParticipantIds = GroupPichangaParticipant::query()
            ->where('pichanga_id', $pichanga->id)->where('status', 'confirmed')->where('team_code', $team)
            ->pluck('user_id')->map(fn ($id) => (int) $id)->sort()->values();
        abort_unless($ids->sort()->values()->all() === $teamParticipantIds->all(), 422, 'Las posiciones deben incluir exactamente a los integrantes del equipo.');

        $hasFormationCoordinates = Schema::hasColumn('group_pichanga_participants', 'formation_x')
            && Schema::hasColumn('group_pichanga_participants', 'formation_y');
        DB::transaction(function () use ($pichanga, $team, $data, $hasFormationCoordinates) {
            foreach ($data['positions'] as $position) {
                $updates = [
                    'formation_role' => $position['formation_role'],
                    'formation_order' => (int) $position['formation_order'],
                ];
                if ($hasFormationCoordinates) {
                    $updates['formation_x'] = $position['formation_x'] ?? null;
                    $updates['formation_y'] = $position['formation_y'] ?? null;
                }
                GroupPichangaParticipant::query()
                    ->where('pichanga_id', $pichanga->id)->where('team_code', $team)
                    ->where('user_id', (int) $position['user_id'])->where('status', 'confirmed')
                    ->update($updates);
            }
        });
        return response()->json(['message' => 'Formación actualizada.']);
    }

    public function moveParticipantTeam(Request $request, GroupPichanga $pichanga, User $user)
    {
        $auth = $request->user() ?? abort(401);
        abort_unless($this->isClubAdminForPichanga($pichanga, (int) $auth->id), 403);
        $this->ensurePichangaFormationIsMutable($pichanga);
        $data = $request->validate(['team_code' => ['required', Rule::in($this->allowedTeamCodes($this->resolveTeamCount($pichanga)))] ]);
        $team = strtoupper((string) $data['team_code']);
        DB::transaction(function () use ($pichanga, $user, $team) {
            $participant = GroupPichangaParticipant::query()->where('pichanga_id', $pichanga->id)
                ->where('user_id', $user->id)->where('status', 'confirmed')->lockForUpdate()->firstOrFail();
            $teamSize = $this->resolvePlayersPerTeam($pichanga, $this->resolveTeamCount($pichanga));
            $occupied = GroupPichangaParticipant::query()->where('pichanga_id', $pichanga->id)
                ->where('status', 'confirmed')->where('team_code', $team)->where('id', '!=', $participant->id)->count();
            abort_if($occupied >= $teamSize, 422, 'El equipo ya está completo.');
            $this->teamAssignments->assign($pichanga, $participant, $team);
        });
        return response()->json(['message' => "Jugador movido a equipo {$team}."]);
    }

    public function updateAudience(Request $request, GroupPichanga $pichanga)
    {
        $auth = $request->user() ?? abort(401);
        abort_unless($this->isClubAdmin((int) $pichanga->club_id, (int) $auth->id) || (bool) $auth->is_superadmin, 403);

        $data = $request->validate([
            'notify_degree' => ['sometimes', 'integer', 'min:1', 'max:3'],
            'allow_external_requests' => ['sometimes', 'boolean'],
            'is_open' => ['sometimes', 'boolean'],
            'auto_reminder_enabled' => ['sometimes', 'boolean'],
            'audience_sex' => ['sometimes', 'nullable', Rule::in(['M', 'F'])],
            'audience_age_min' => ['sometimes', 'nullable', 'integer', 'min:14', 'max:80'],
            'audience_age_max' => ['sometimes', 'nullable', 'integer', 'min:14', 'max:80'],
            'skill_fisico_min' => ['sometimes', 'nullable', 'numeric', 'min:0', 'max:5', 'decimal:0,1'],
            'skill_arquero_min' => ['sometimes', 'nullable', 'numeric', 'min:0', 'max:5', 'decimal:0,1'],
            'skill_delantero_min' => ['sometimes', 'nullable', 'numeric', 'min:0', 'max:5', 'decimal:0,1'],
            'skill_mediocampo_min' => ['sometimes', 'nullable', 'numeric', 'min:0', 'max:5', 'decimal:0,1'],
            'skill_defensa_min' => ['sometimes', 'nullable', 'numeric', 'min:0', 'max:5', 'decimal:0,1'],
        ]);

        if (array_key_exists('notify_degree', $data)) {
            $maxDegree = (int) ($pichanga->club->audience_max_degree ?? 1);
            $data['notify_degree'] = min(max((int) $data['notify_degree'], 1), max(1, $maxDegree));
        }

        if (!empty($data['audience_age_min']) && !empty($data['audience_age_max'])) {
            abort_if((int) $data['audience_age_min'] > (int) $data['audience_age_max'], 422, 'Rango de edad inválido.');
        }

        $payload = $this->filterPayloadByTableColumns('group_pichangas', $data);
        $pichanga->update($payload);

        $this->eventService->track(
            'pichanga_audience_updated',
            (int) $auth->id,
            (int) $pichanga->club_id,
            (int) $pichanga->id,
            [
                'notify_degree' => $payload['notify_degree'] ?? $pichanga->notify_degree,
            ]
        );

        return response()->json([
            'message' => 'Audiencia actualizada.',
            'pichanga' => $this->serializePichanga($pichanga->fresh()),
        ]);
    }

    public function confirm(Request $request, GroupPichanga $pichanga)
    {
        $auth = $request->user() ?? abort(401);
        $userClubIds = ClubUser::query()
            ->where('user_id', $auth->id)
            ->active()
            ->pluck('club_id')
            ->map(fn($i) => (int) $i)
            ->all();
        abort_unless($this->isMemberOfPichanga($pichanga, $userClubIds), 403, 'Solo miembros de los grupos participantes pueden confirmar directo.');
        abort_if(in_array($pichanga->status, ['cancelled', 'completed'], true), 422, 'La pichanga no permite confirmaciones.');
        abort_if(now()->greaterThanOrEqualTo($pichanga->starts_at), 422, 'La pichanga ya empezó.');

        $teamCount = $this->resolveTeamCount($pichanga);
        $allowedTeamCodes = $this->allowedTeamCodes($teamCount);
        $data = $request->validate([
            'team_code' => ['required', Rule::in($allowedTeamCodes)],
        ]);

        $teamCode = strtoupper((string) $data['team_code']);

        DB::transaction(function () use ($pichanga, $auth, $teamCode) {
            $lockedPichanga = GroupPichanga::query()->lockForUpdate()->findOrFail($pichanga->id);
            $participant = GroupPichangaParticipant::query()
                ->where('pichanga_id', $lockedPichanga->id)
                ->where('user_id', $auth->id)
                ->lockForUpdate()
                ->first();

            if (!$participant || $participant->status !== 'confirmed') {
                $confirmedCount = $this->confirmedParticipantsCount((int) $lockedPichanga->id);
                abort_if($confirmedCount >= (int) $lockedPichanga->capacity, 422, 'No hay cupos disponibles.');
            }

            $payload = $this->filterPayloadByTableColumns('group_pichanga_participants', [
                'origin' => 'member',
                'status' => 'confirmed',
                'confirmed_at' => $participant?->confirmed_at ?? now(),
                'withdrawn_at' => null,
            ]);

            if ($participant) {
                $participant->update($payload);
            } else {
                $participant = GroupPichangaParticipant::create(array_merge(
                    ['pichanga_id' => $lockedPichanga->id, 'user_id' => $auth->id],
                    $payload
                ));
            }
            $this->teamAssignments->assign($lockedPichanga, $participant, $teamCode);
        });

        $this->refreshAutoStatus($pichanga->fresh());
        $this->eventService->track('pichanga_confirmed', (int) $auth->id, (int) $pichanga->club_id, (int) $pichanga->id, [
            'team_code' => $teamCode,
        ]);

        return response()->json(['message' => "Asistencia confirmada en equipo {$teamCode}."]);
    }

    public function withdraw(Request $request, GroupPichanga $pichanga)
    {
        $auth = $request->user() ?? abort(401);
        $participant = GroupPichangaParticipant::where('pichanga_id', $pichanga->id)
            ->where('user_id', $auth->id)
            ->first();
        abort_unless($participant && $participant->status === 'confirmed', 422, 'No tienes asistencia confirmada.');

        $payload = $this->filterPayloadByTableColumns('group_pichanga_participants', [
            'status' => 'withdrawn',
            'withdrawn_at' => now(),
            'team_code' => null,
            'team_slot' => null,
        ]);
        $promotion = DB::transaction(function () use ($pichanga, $participant, $payload) {
            $lockedPichanga = GroupPichanga::query()->lockForUpdate()->findOrFail($pichanga->id);
            $lockedParticipant = GroupPichangaParticipant::query()->whereKey($participant->id)->lockForUpdate()->firstOrFail();
            $lockedParticipant->update($payload);

            return $this->promoteNextWaitlistLocked($lockedPichanga);
        });
        $this->refreshAutoStatus($pichanga->fresh());
        $this->eventService->track('pichanga_withdrawn', (int) $auth->id, (int) $pichanga->club_id, (int) $pichanga->id);

        $club = $pichanga->club ?: Club::find($pichanga->club_id);
        if ($club && $promotion !== null) {
            $this->clubNotifications->notifyUsers($club, [(int) $promotion['user_id']], [
                'type' => 'pichanga_waitlist_promoted',
                'category' => 'pichangas',
                'title' => 'Se liberó un cupo',
                'body' => 'Tu asistencia fue confirmada desde la lista de espera.',
                'target_type' => 'pichanga',
                'target_id' => (int) $pichanga->id,
                'group_pichanga_id' => (int) $pichanga->id,
                'image_kind' => 'pichanga',
                'image_url' => $this->pichangaImageUrl($pichanga),
                'data_json' => ['pichanga_id' => (int) $pichanga->id, 'waitlist_promoted' => true],
            ]);
        } elseif ($club) {
            $this->clubNotifications->notifyAdmins($club, [
                'type' => 'pichanga_spot_available',
                'category' => 'pichangas',
                'title' => 'Hay un cupo disponible',
                'body' => 'Una persona se dio de baja de la pichanga.',
                'target_type' => 'pichanga',
                'target_id' => (int) $pichanga->id,
                'group_pichanga_id' => (int) $pichanga->id,
                'image_kind' => 'pichanga',
                'image_url' => $this->pichangaImageUrl($pichanga),
                'data_json' => ['pichanga_id' => (int) $pichanga->id],
            ], (int) $auth->id);
        }

        return response()->json(['message' => 'Te diste de baja de la pichanga.']);
    }

    public function joinWaitlist(Request $request, GroupPichanga $pichanga)
    {
        $auth = $request->user() ?? abort(401);
        abort_unless(Schema::hasTable('group_pichanga_waitlist'), 422, 'Ejecuta la migración de lista de espera.');
        $clubIds = ClubUser::query()->where('user_id', $auth->id)->active()->pluck('club_id')->map(fn ($id) => (int) $id)->all();
        abort_unless($this->isMemberOfPichanga($pichanga, $clubIds), 403, 'Solo miembros de los grupos participantes pueden unirse a la lista de espera.');
        abort_if(in_array((string) $pichanga->status, ['cancelled', 'completed'], true) || now()->greaterThanOrEqualTo($pichanga->starts_at), 422, 'La pichanga ya no acepta lista de espera.');
        $data = $request->validate(['team_code' => ['nullable', Rule::in($this->allowedTeamCodes($this->resolveTeamCount($pichanga)))] ]);

        $entry = DB::transaction(function () use ($pichanga, $auth, $data) {
            $locked = GroupPichanga::query()->lockForUpdate()->findOrFail($pichanga->id);
            $participant = GroupPichangaParticipant::query()->where('pichanga_id', $locked->id)->where('user_id', $auth->id)->lockForUpdate()->first();
            abort_if($participant?->status === 'confirmed', 422, 'Ya tienes asistencia confirmada.');
            abort_if($this->confirmedParticipantsCount((int) $locked->id) < (int) $locked->capacity, 422, 'Hay un cupo disponible; confirma tu asistencia directamente.');

            $entry = GroupPichangaWaitlistEntry::query()->where('pichanga_id', $locked->id)->where('user_id', $auth->id)->lockForUpdate()->first();
            if ($entry) {
                $entry->update(['team_code' => isset($data['team_code']) ? strtoupper((string) $data['team_code']) : $entry->team_code, 'status' => 'waiting', 'withdrawn_at' => null]);
            } else {
                $entry = GroupPichangaWaitlistEntry::create([
                    'pichanga_id' => $locked->id,
                    'user_id' => $auth->id,
                    'team_code' => isset($data['team_code']) ? strtoupper((string) $data['team_code']) : null,
                    'status' => 'waiting',
                ]);
            }
            return $entry->fresh();
        });

        return response()->json(['message' => 'Te uniste a la lista de espera.', 'position' => $this->waitlistPosition($entry), 'entry' => $entry]);
    }

    public function leaveWaitlist(Request $request, GroupPichanga $pichanga)
    {
        $auth = $request->user() ?? abort(401);
        abort_unless(Schema::hasTable('group_pichanga_waitlist'), 422, 'Ejecuta la migración de lista de espera.');
        $entry = GroupPichangaWaitlistEntry::query()->where('pichanga_id', $pichanga->id)->where('user_id', $auth->id)->where('status', 'waiting')->first();
        abort_unless($entry, 422, 'No estás en la lista de espera.');
        $entry->update(['status' => 'withdrawn', 'withdrawn_at' => now()]);
        return response()->json(['message' => 'Saliste de la lista de espera.']);
    }

    public function waitlist(Request $request, GroupPichanga $pichanga)
    {
        $auth = $request->user() ?? abort(401);
        abort_unless(Schema::hasTable('group_pichanga_waitlist'), 422, 'Ejecuta la migración de lista de espera.');
        abort_unless($this->isClubAdminForPichanga($pichanga, (int) $auth->id) || $this->isMemberOfPichanga($pichanga, ClubUser::query()->where('user_id', $auth->id)->active()->pluck('club_id')->map(fn ($id) => (int) $id)->all()), 403);
        $items = GroupPichangaWaitlistEntry::query()->where('pichanga_id', $pichanga->id)->where('status', 'waiting')->with('user:id,name,nick,avatar_url')->orderBy('created_at')->orderBy('id')->get();
        return response()->json(['items' => $items->values()->map(fn ($entry, $index) => ['id' => $entry->id, 'position' => $index + 1, 'team_code' => $entry->team_code, 'user' => $entry->user, 'created_at' => optional($entry->created_at)->toISOString()])]);
    }

    public function setStatus(Request $request, GroupPichanga $pichanga)
    {
        $auth = $request->user() ?? abort(401);
        abort_unless($this->isClubAdminForPichanga($pichanga, (int) $auth->id) || (bool) $auth->is_superadmin, 403);

        $data = $request->validate([
            'status' => ['required', Rule::in(['published', 'confirmed', 'cancelled', 'completed'])],
        ]);

        $pichanga->update(['status' => $data['status']]);

        $club = $pichanga->club ?: Club::find($pichanga->club_id);
        if ($club && in_array($data['status'], ['cancelled', 'confirmed'], true)) {
            $participantIds = GroupPichangaParticipant::query()
                ->where('pichanga_id', $pichanga->id)
                ->where('status', 'confirmed')
                ->pluck('user_id')->map(fn ($id) => (int) $id)->all();
            $this->clubNotifications->notifyUsers($club, $participantIds, [
                'type' => $data['status'] === 'cancelled' ? 'pichanga_cancelled' : 'pichanga_confirmed',
                'category' => 'pichangas',
                'title' => $data['status'] === 'cancelled' ? 'Pichanga cancelada' : 'Pichanga confirmada',
                'body' => (string) ($pichanga->title ?: 'La pichanga actualizó su estado.'),
                'target_type' => 'pichanga',
                'target_id' => (int) $pichanga->id,
                'group_pichanga_id' => (int) $pichanga->id,
                'image_kind' => 'pichanga',
                'image_url' => $this->pichangaImageUrl($pichanga),
                'data_json' => ['pichanga_id' => (int) $pichanga->id],
            ], (int) $auth->id);
        }

        $this->eventService->track(
            'pichanga_status_updated',
            (int) $auth->id,
            (int) $pichanga->club_id,
            (int) $pichanga->id,
            ['status' => (string) $data['status']]
        );

        return response()->json([
            'message' => 'Estado actualizado.',
            'status' => $pichanga->status,
        ]);
    }

    public function updateSchedule(Request $request, GroupPichanga $pichanga)
    {
        $auth = $request->user() ?? abort(401);
        abort_unless($this->isClubAdminForPichanga($pichanga, (int) $auth->id) || (bool) $auth->is_superadmin, 403);
        abort_if(in_array((string) $pichanga->status, ['cancelled', 'completed'], true), 422, 'No puedes reprogramar una pichanga cerrada.');
        $data = $request->validate([
            'starts_at' => ['required', 'date', 'after:now'],
            'duration_minutes' => ['nullable', 'integer', 'min:30', 'max:360'],
            'cancha_id' => ['nullable', 'integer', 'exists:cancha,id'],
        ]);

        $previousStart = optional($pichanga->starts_at)->toISOString();
        $pichanga->update($this->filterPayloadByTableColumns('group_pichangas', $data));
        $club = $pichanga->club ?: Club::find($pichanga->club_id);
        if ($club) {
            $participantIds = GroupPichangaParticipant::query()
                ->where('pichanga_id', $pichanga->id)->where('status', 'confirmed')
                ->pluck('user_id')->map(fn ($id) => (int) $id)->all();
            $this->clubNotifications->notifyUsers($club, $participantIds, [
                'type' => 'pichanga_rescheduled',
                'category' => 'pichangas',
                'title' => 'Pichanga reprogramada',
                'body' => (string) ($pichanga->title ?: 'Revisa la nueva fecha, hora o cancha.'),
                'target_type' => 'pichanga',
                'target_id' => (int) $pichanga->id,
                'group_pichanga_id' => (int) $pichanga->id,
                'image_kind' => 'pichanga',
                'image_url' => $this->pichangaImageUrl($pichanga),
                'data_json' => ['pichanga_id' => (int) $pichanga->id, 'previous_starts_at' => $previousStart],
            ], (int) $auth->id);
        }
        $this->eventService->track('pichanga_rescheduled', (int) $auth->id, (int) $pichanga->club_id, (int) $pichanga->id, ['previous_starts_at' => $previousStart]);

        return response()->json(['message' => 'Pichanga reprogramada.', 'pichanga' => $this->serializePichanga($pichanga->fresh())]);
    }

    public function createExternalRequest(Request $request, GroupPichanga $pichanga)
    {
        $auth = $request->user() ?? abort(401);
        abort_if((string) ($pichanga->match_context ?? 'regular') === 'club_challenge', 422, 'Las pichangas por reto no aceptan solicitudes externas.');
        abort_if($this->isMember((int) $pichanga->club_id, (int) $auth->id), 422, 'Ya eres miembro del grupo, confirma directo.');
        abort_if(!$pichanga->allow_external_requests, 422, 'Esta pichanga no recibe solicitudes externas.');
        abort_if(now()->greaterThanOrEqualTo($pichanga->starts_at), 422, 'La pichanga ya empezó.');

        $this->expirePendingExternalRequests($pichanga);

        $eligibility = $this->audienceService->externalEligibility($pichanga, (int) $auth->id);
        abort_unless($eligibility['eligible'], 403, 'No estás dentro de la audiencia objetivo.');

        $existing = GroupPichangaExternalRequest::where('pichanga_id', $pichanga->id)
            ->where('user_id', $auth->id)
            ->first();
        if ($existing && $existing->status === 'pending') {
            return response()->json(['message' => 'Ya tienes una solicitud pendiente.']);
        }

        $externalRequest = GroupPichangaExternalRequest::updateOrCreate(
            ['pichanga_id' => $pichanga->id, 'user_id' => $auth->id],
            [
                'status' => 'pending',
                'origin_degree' => $eligibility['degree'],
                'requested_at' => now(),
                'decided_at' => null,
                'decided_by_user_id' => null,
            ]
        );

        $this->eventService->track(
            'pichanga_external_request_created',
            (int) $auth->id,
            (int) $pichanga->club_id,
            (int) $pichanga->id,
            ['degree' => $eligibility['degree']]
        );

        $club = $pichanga->club ?: Club::find($pichanga->club_id);
        if ($club) {
            $requesterName = (string) ($auth->nick ?: $auth->name ?: 'Un jugador');
            $this->clubNotifications->notifyAdmins($club, [
                'type' => 'pichanga_external_request_created',
                'category' => 'requests',
                'title' => 'Nueva solicitud para pichanga',
                'body' => "{$requesterName} quiere participar en " . ($pichanga->title ?: 'tu pichanga') . '.',
                'target_type' => 'pichanga_external_request',
                'target_id' => (int) $externalRequest->id,
                'group_pichanga_id' => (int) $pichanga->id,
                'image_kind' => 'pichanga',
                'image_url' => $this->pichangaImageUrl($pichanga),
                'data_json' => ['pichanga_id' => (int) $pichanga->id, 'external_request_id' => (int) $externalRequest->id],
            ], (int) $auth->id);
        }

        return response()->json(['message' => 'Solicitud enviada al administrador.'], 201);
    }

    public function listExternalRequests(Request $request, GroupPichanga $pichanga)
    {
        $auth = $request->user() ?? abort(401);
        abort_unless($this->isClubAdmin((int) $pichanga->club_id, (int) $auth->id) || (bool) $auth->is_superadmin, 403);
        $this->expirePendingExternalRequests($pichanga);

        $items = GroupPichangaExternalRequest::query()
            ->where('pichanga_id', $pichanga->id)
            ->with('user:id,name,nick,email,sexo,fec_nac')
            ->orderByRaw("CASE WHEN status='pending' THEN 0 ELSE 1 END")
            ->orderByDesc('requested_at')
            ->get()
            ->map(function (GroupPichangaExternalRequest $row) {
                return [
                    'id' => $row->id,
                    'user_id' => $row->user_id,
                    'status' => $row->status,
                    'origin_degree' => $row->origin_degree,
                    'requested_at' => optional($row->requested_at)->toISOString(),
                    'decided_at' => optional($row->decided_at)->toISOString(),
                    'note' => $row->note,
                    'user' => $row->user,
                ];
            })->values();

        return response()->json(['items' => $items]);
    }

    public function decideExternalRequest(Request $request, GroupPichanga $pichanga, GroupPichangaExternalRequest $externalRequest)
    {
        $auth = $request->user() ?? abort(401);
        abort_unless((int) $externalRequest->pichanga_id === (int) $pichanga->id, 404);
        abort_unless($this->isClubAdmin((int) $pichanga->club_id, (int) $auth->id) || (bool) $auth->is_superadmin, 403);
        $this->expirePendingExternalRequests($pichanga);

        $data = $request->validate([
            'action' => ['required', Rule::in(['accept', 'reject'])],
            'note' => ['nullable', 'string', 'max:255'],
        ]);

        abort_if($externalRequest->status !== 'pending', 422, 'La solicitud ya fue resuelta.');

        if ($data['action'] === 'reject') {
            $externalRequest->update([
                'status' => 'rejected',
                'decided_at' => now(),
                'decided_by_user_id' => $auth->id,
                'note' => $data['note'] ?? null,
            ]);

            $this->eventService->track(
                'pichanga_external_request_rejected',
                (int) $auth->id,
                (int) $pichanga->club_id,
                (int) $pichanga->id,
                ['external_request_id' => (int) $externalRequest->id, 'user_id' => (int) $externalRequest->user_id]
            );
            $club = $pichanga->club ?: Club::find($pichanga->club_id);
            if ($club) {
                $this->clubNotifications->notifyUsers($club, [(int) $externalRequest->user_id], [
                    'type' => 'pichanga_external_request_rejected',
                    'category' => 'requests',
                    'title' => 'Solicitud actualizada',
                    'body' => 'Tu solicitud para participar no fue aceptada.',
                    'target_type' => 'pichanga',
                    'target_id' => (int) $pichanga->id,
                    'group_pichanga_id' => (int) $pichanga->id,
                    'image_kind' => 'pichanga',
                    'image_url' => $this->pichangaImageUrl($pichanga),
                    'data_json' => ['pichanga_id' => (int) $pichanga->id],
                ], (int) $auth->id);
            }
            return response()->json(['message' => 'Solicitud rechazada.']);
        }

        $confirmedCount = $this->confirmedParticipantsCount($pichanga->id);
        abort_if($confirmedCount >= (int) $pichanga->capacity, 422, 'No hay cupos disponibles.');

        DB::transaction(function () use ($externalRequest, $auth, $pichanga, $data) {
            $lockedPichanga = GroupPichanga::query()->lockForUpdate()->findOrFail($pichanga->id);
            $confirmedCount = $this->confirmedParticipantsCount($lockedPichanga->id);
            abort_if($confirmedCount >= (int) $lockedPichanga->capacity, 422, 'No hay cupos disponibles.');
            $externalRequest->update([
                'status' => 'accepted',
                'decided_at' => now(),
                'decided_by_user_id' => $auth->id,
                'note' => $data['note'] ?? null,
            ]);

            $participantPayload = $this->filterPayloadByTableColumns('group_pichanga_participants', [
                'origin' => 'external',
                'status' => 'confirmed',
                'confirmed_at' => now(),
                'withdrawn_at' => null,
            ]);

            $participant = GroupPichangaParticipant::updateOrCreate(
                ['pichanga_id' => $lockedPichanga->id, 'user_id' => $externalRequest->user_id],
                $participantPayload
            );
            $this->teamAssignments->assign($lockedPichanga, $participant);
        });

        $this->refreshAutoStatus($pichanga->fresh());
        $this->eventService->track(
            'pichanga_external_request_accepted',
            (int) $auth->id,
            (int) $pichanga->club_id,
            (int) $pichanga->id,
            ['external_request_id' => (int) $externalRequest->id, 'user_id' => (int) $externalRequest->user_id]
        );

        $club = $pichanga->club ?: Club::find($pichanga->club_id);
        if ($club) {
            $this->clubNotifications->notifyUsers($club, [(int) $externalRequest->user_id], [
                'type' => 'pichanga_external_request_accepted',
                'category' => 'requests',
                'title' => 'Asistencia confirmada',
                'body' => 'Tu solicitud fue aceptada. Ya tienes un cupo confirmado.',
                'target_type' => 'pichanga',
                'target_id' => (int) $pichanga->id,
                'group_pichanga_id' => (int) $pichanga->id,
                'image_kind' => 'pichanga',
                'image_url' => $this->pichangaImageUrl($pichanga),
                'data_json' => ['pichanga_id' => (int) $pichanga->id],
            ], (int) $auth->id);
        }

        return response()->json(['message' => 'Solicitud aceptada y asistencia confirmada.']);
    }

    public function renotifyPreview(Request $request, GroupPichanga $pichanga)
    {
        $auth = $request->user() ?? abort(401);
        abort_unless($this->canRenotify($pichanga, $auth->id, (bool) $auth->is_superadmin), 403);

        $overrides = $this->validateAudienceOverrides($request);
        $audience = $this->audienceService->resolveAudience($pichanga, $overrides);
        $targetIds = collect($audience['target_user_ids'])->map(fn($id) => (int) $id)->values();

        $notMuted = $this->muteService->filterNotMutedUserIds($targetIds, (int) $pichanga->club_id);
        $mutedSkipped = $targetIds->count() - $notMuted->count();

        return response()->json([
            'message' => "Con estos filtros se invitaría a {$targetIds->count()} personas.",
            'target_count' => $targetIds->count(),
            'sendable_count' => $notMuted->count(),
            'muted_skipped_count' => $mutedSkipped,
            'by_degree' => collect($audience['by_degree'])->map(fn($row) => [
                'pool' => $row['pool'],
                'eligible' => $row['eligible'],
            ])->all(),
            'filters' => $audience['filters'],
            'target_degree' => $audience['target_degree'],
        ]);
    }

    public function renotifySend(Request $request, GroupPichanga $pichanga)
    {
        $auth = $request->user() ?? abort(401);
        abort_unless($this->canRenotify($pichanga, $auth->id, (bool) $auth->is_superadmin), 403);

        $club = $pichanga->club;
        $cooldown = max(1, (int) ($club->renotify_cooldown_minutes ?? 30));
        $maxPerPichanga = max(1, (int) ($club->renotify_max_per_pichanga ?? 5));

        if ((int) ($pichanga->renotify_sent_count ?? 0) >= $maxPerPichanga) {
            abort(422, 'Ya alcanzaste el máximo de re-avisos para esta pichanga.');
        }
        if ($pichanga->last_renotify_at && now()->lt($pichanga->last_renotify_at->copy()->addMinutes($cooldown))) {
            $remaining = now()->diffInSeconds($pichanga->last_renotify_at->copy()->addMinutes($cooldown), false);
            abort(422, "Debes esperar {$remaining} segundos para volver a avisar.");
        }

        $overrides = $this->validateAudienceOverrides($request);
        $audience = $this->audienceService->resolveAudience($pichanga, $overrides);
        $targetIds = collect($audience['target_user_ids'])->map(fn($id) => (int) $id)->values();

        $notMuted = $this->muteService->filterNotMutedUserIds($targetIds, (int) $pichanga->club_id);
        $mutedSkipped = $targetIds->count() - $notMuted->count();

        GroupPichangaNotificationBatch::create([
            'pichanga_id' => $pichanga->id,
            'triggered_by_user_id' => $auth->id,
            'batch_type' => 'manual_renotify',
            'target_degree' => (int) $audience['target_degree'],
            'filters_json' => $audience['filters'],
            'target_count' => $targetIds->count(),
            'muted_skipped_count' => $mutedSkipped,
            'sent_count' => 0,
        ]);

        $sent = $this->pushNotificationService->createForUsers($notMuted->all(), [
            'club_id' => $pichanga->club_id,
            'group_pichanga_id' => $pichanga->id,
            'type' => 'pichanga_renotify',
            'title' => 'Recordatorio de pichanga',
            'body' => (string) ($pichanga->title ?: 'Revisa la pichanga y confirma tu asistencia'),
            'data_json' => ['pichanga_id' => $pichanga->id, 'club_id' => $pichanga->club_id],
        ]);

        GroupPichangaNotificationBatch::where('pichanga_id', $pichanga->id)
            ->where('triggered_by_user_id', $auth->id)
            ->latest('id')
            ->limit(1)
            ->update(['sent_count' => $sent]);

        $pichanga->update([
            'last_renotify_at' => now(),
            'renotify_sent_count' => (int) ($pichanga->renotify_sent_count ?? 0) + 1,
        ]);

        $this->eventService->track(
            'pichanga_renotify_sent',
            (int) $auth->id,
            (int) $pichanga->club_id,
            (int) $pichanga->id,
            [
                'target_count' => $targetIds->count(),
                'sent_count' => $sent,
                'muted_skipped_count' => $mutedSkipped,
                'target_degree' => (int) $audience['target_degree'],
            ]
        );

        return response()->json([
            'message' => 'Re-aviso registrado.',
            'target_count' => $targetIds->count(),
            'sendable_count' => $sent,
            'muted_skipped_count' => $mutedSkipped,
            'renotify_sent_count' => (int) $pichanga->fresh()->renotify_sent_count,
        ]);
    }

    private function validateAudienceOverrides(Request $request): array
    {
        return $request->validate([
            'target_degree' => ['nullable', 'integer', 'min:1', 'max:3'],
            'audience_sex' => ['nullable', Rule::in(['M', 'F'])],
            'audience_age_min' => ['nullable', 'integer', 'min:14', 'max:80'],
            'audience_age_max' => ['nullable', 'integer', 'min:14', 'max:80'],
            'skill_fisico_min' => ['nullable', 'numeric', 'min:0', 'max:5', 'decimal:0,1'],
            'skill_arquero_min' => ['nullable', 'numeric', 'min:0', 'max:5', 'decimal:0,1'],
            'skill_delantero_min' => ['nullable', 'numeric', 'min:0', 'max:5', 'decimal:0,1'],
            'skill_mediocampo_min' => ['nullable', 'numeric', 'min:0', 'max:5', 'decimal:0,1'],
            'skill_defensa_min' => ['nullable', 'numeric', 'min:0', 'max:5', 'decimal:0,1'],
        ]);
    }

    private function refreshAutoStatus(GroupPichanga $pichanga): void
    {
        if ($pichanga->confirmation_mode !== 'auto_by_capacity') {
            return;
        }

        $confirmed = $this->confirmedParticipantsCount($pichanga->id);
        if ($pichanga->status === 'published' && $confirmed >= (int) $pichanga->capacity) {
            $pichanga->update(['status' => 'confirmed']);
        } elseif ($pichanga->status === 'confirmed' && $confirmed < (int) $pichanga->capacity) {
            $pichanga->update(['status' => 'published']);
        }
    }

    private function confirmedParticipantsCount(int $pichangaId): int
    {
        return GroupPichangaParticipant::where('pichanga_id', $pichangaId)
            ->where('status', 'confirmed')
            ->count();
    }

    /** @return array{user_id:int,team_code:?string}|null */
    private function promoteNextWaitlistLocked(GroupPichanga $pichanga): ?array
    {
        if (!Schema::hasTable('group_pichanga_waitlist') || $this->confirmedParticipantsCount((int) $pichanga->id) >= (int) $pichanga->capacity) {
            return null;
        }

        $entry = GroupPichangaWaitlistEntry::query()
            ->where('pichanga_id', $pichanga->id)
            ->where('status', 'waiting')
            ->orderBy('created_at')
            ->orderBy('id')
            ->lockForUpdate()
            ->first();
        if (!$entry) {
            return null;
        }

        $payload = $this->filterPayloadByTableColumns('group_pichanga_participants', [
            'origin' => 'waitlist',
            'status' => 'confirmed',
            'confirmed_at' => now(),
            'withdrawn_at' => null,
        ]);
        $participant = GroupPichangaParticipant::query()
            ->where('pichanga_id', $pichanga->id)
            ->where('user_id', $entry->user_id)
            ->lockForUpdate()
            ->first();
        if ($participant) {
            $participant->update($payload);
        } else {
            $participant = GroupPichangaParticipant::create(array_merge([
                'pichanga_id' => $pichanga->id,
                'user_id' => $entry->user_id,
            ], $payload));
        }
        $this->teamAssignments->assign($pichanga, $participant, $entry->team_code ?: null);
        $entry->update(['status' => 'promoted', 'promoted_at' => now()]);

        return ['user_id' => (int) $entry->user_id, 'team_code' => $entry->team_code];
    }

    private function waitlistPosition(GroupPichangaWaitlistEntry $entry): int
    {
        return GroupPichangaWaitlistEntry::query()
            ->where('pichanga_id', $entry->pichanga_id)
            ->where('status', 'waiting')
            ->where(function ($query) use ($entry) {
                $query->where('created_at', '<', $entry->created_at)
                    ->orWhere(function ($sameMoment) use ($entry) {
                        $sameMoment->where('created_at', '=', $entry->created_at)->where('id', '<=', $entry->id);
                    });
            })
            ->count();
    }

    private function monthlyPlayedCount(int $userId, \Illuminate\Support\Carbon $now): int
    {
        $monthStart = $now->copy()->startOfMonth();
        $monthEnd = $now->copy()->endOfMonth();
        $windowStart = $monthStart->copy()->subDay();

        $participants = GroupPichangaParticipant::query()
            ->where('user_id', $userId)
            ->where('status', 'confirmed')
            ->whereHas('pichanga', function ($query) use ($windowStart, $monthEnd) {
                $query
                    ->where('starts_at', '>=', $windowStart)
                    ->where('starts_at', '<=', $monthEnd)
                    ->whereNotIn('status', ['cancelled']);
            })
            ->with(['pichanga:id,starts_at,duration_minutes,status'])
            ->get();

        return $participants->filter(function (GroupPichangaParticipant $participant) use ($monthStart, $monthEnd, $now) {
            $startsAt = $participant->pichanga?->starts_at;
            if ($startsAt === null) {
                return false;
            }

            $durationMinutes = max(0, (int) ($participant->pichanga?->duration_minutes ?? 0));
            $endsAt = $startsAt->copy()->addMinutes($durationMinutes);

            return $endsAt->gte($monthStart)
                && $endsAt->lte($monthEnd)
                && $endsAt->lte($now);
        })->count();
    }

    private function expirePendingExternalRequests(GroupPichanga $pichanga): void
    {
        if (now()->lt($pichanga->starts_at)) {
            return;
        }

        GroupPichangaExternalRequest::where('pichanga_id', $pichanga->id)
            ->where('status', 'pending')
            ->update(['status' => 'expired', 'decided_at' => now()]);
    }

    private function isMember(int $clubId, int $userId): bool
    {
        return ClubUser::where('club_id', $clubId)->where('user_id', $userId)->active()->exists();
    }

    private function isClubAdmin(int $clubId, int $userId): bool
    {
        return ClubUser::where('club_id', $clubId)
            ->where('user_id', $userId)
            ->active()
            ->where('rol', 'admin')
            ->exists();
    }

    private function canCreatePichanga(Club $club, int $userId, bool $isSuper): bool
    {
        if ($isSuper) {
            return true;
        }
        if (!$this->isMember((int) $club->id, $userId)) {
            return false;
        }

        $scope = $club->pichanga_create_scope ?? 'admins';
        if ($scope === 'members') {
            return true;
        }

        return $this->isClubAdmin((int) $club->id, $userId);
    }

    private function canRenotify(GroupPichanga $pichanga, int $userId, bool $isSuper): bool
    {
        if ($isSuper) {
            return true;
        }
        if (!$this->isMemberOfPichanga($pichanga, ClubUser::query()
            ->where('user_id', $userId)
            ->active()
            ->pluck('club_id')
            ->map(fn($i) => (int) $i)
            ->all())) {
            return false;
        }

        if ((string) ($pichanga->match_context ?? 'regular') === 'club_challenge') {
            return $this->isClubAdminForPichanga($pichanga, $userId);
        }

        $scope = $pichanga->club->renotify_scope ?? 'admins';
        if ($scope === 'members') {
            return true;
        }

        return $this->isClubAdmin((int) $pichanga->club_id, $userId);
    }

    /**
     * @param \Illuminate\Support\Collection<int,GroupPichanga> $pichangas
     * @return array<int,array{court_name:?string,field_name:?string,venue_photo_url:?string,venue_field_id:?int}>
     */
    private function participantStatusesFor($pichangas, ?int $userId): array
    {
        if (!$userId || $pichangas->isEmpty() || !Schema::hasTable('group_pichanga_participants')) {
            return [];
        }

        return GroupPichangaParticipant::query()
            ->where('user_id', $userId)
            ->whereIn('pichanga_id', $pichangas->pluck('id')->map(fn ($id) => (int) $id))
            ->pluck('status', 'pichanga_id')
            ->mapWithKeys(fn ($status, $pichangaId) => [(int) $pichangaId => (string) $status])
            ->all();
    }

    private function venuesForPichangas($pichangas): array
    {
        $courtIds = $pichangas->pluck('cancha_id')->filter()->map(fn ($id) => (int) $id)->unique()->values();
        $fieldIds = $pichangas->pluck('field_id')->filter()->map(fn ($id) => (int) $id)->unique()->values();

        $courts = $courtIds->isEmpty() || !Schema::hasTable('cancha')
            ? collect()
            : Cancha::query()->with('polideportivo:id,nombre,url_foto')->whereIn('id', $courtIds)->get()->keyBy('id');
        $fields = $fieldIds->isEmpty() || !Schema::hasTable('polideportivo')
            ? collect()
            : Polideportivo::query()->whereIn('id', $fieldIds)->pluck('nombre', 'id');

        return $pichangas->mapWithKeys(function (GroupPichanga $pichanga) use ($courts, $fields) {
            $court = $courts->get((int) $pichanga->cancha_id);
            $fieldName = $court?->polideportivo?->nombre ?? $fields->get((int) $pichanga->field_id);
            return [(int) $pichanga->id => [
                'court_name' => $court?->nombre,
                'field_name' => $fieldName,
                'venue_photo_url' => $court?->url_foto ?? $court?->polideportivo?->url_foto,
                'venue_field_id' => $court?->polideportivo?->id ?? $pichanga->field_id,
            ]];
        })->all();
    }

    /** @return array<string,mixed> */
    private function detailPresentation(
        GroupPichanga $pichanga,
        ?GroupPichangaParticipant $participant,
        bool $isMember,
        ?string $externalRequestStatus
    ): array {
        $startAt = $pichanga->starts_at;
        $endAt = $startAt?->copy()->addMinutes(max(1, (int) ($pichanga->duration_minutes ?? 90)));
        $isCancelled = (string) $pichanga->status === 'cancelled';
        $isCompleted = (string) $pichanga->status === 'completed';
        $phase = $isCancelled || $isCompleted || ($endAt && now()->gt($endAt))
            ? 'finished'
            : ($startAt && now()->gte($startAt) ? 'in_progress' : 'upcoming');
        $confirmed = $this->confirmedParticipantsCount((int) $pichanga->id);
        $spotsLeft = max(0, (int) $pichanga->capacity - $confirmed);
        $isConfirmed = $participant?->status === 'confirmed';
        $canAct = $phase === 'upcoming' && !$isCancelled && !$isCompleted;
        $canWithdraw = $isConfirmed && $canAct;
        $statusLabel = $isCancelled
            ? 'Cancelada'
            : ($phase === 'finished'
                ? 'Finalizada'
                : ($phase === 'in_progress'
                    ? 'En curso'
                    : ($spotsLeft === 0 ? 'Cupos completos' : 'Abierta')));

        return [
            'phase' => $phase,
            'status_label' => $statusLabel,
            'end_at' => optional($endAt)->toISOString(),
            'can_confirm' => $isMember && !$isConfirmed && $canAct && $spotsLeft > 0,
            'can_request_external' => !$isMember && $canAct && $spotsLeft > 0
                && $externalRequestStatus !== 'pending'
                && ((bool) $pichanga->is_open || (bool) $pichanga->allow_external_requests),
            'can_change_team' => $isMember && $isConfirmed && $canAct,
            'can_withdraw' => $canWithdraw,
        ];
    }

    /** @return array<string,mixed> */
    private function emptyMatchSummary(GroupPichanga $pichanga): array
    {
        return [
            'pichanga_id' => (int) $pichanga->id,
            'has_watch_data' => false,
            'score' => [],
            'totals' => ['goals' => 0, 'assists' => 0],
            'events' => [],
        ];
    }

    private function validatedTeamCode(GroupPichanga $pichanga, string $teamCode): string
    {
        $team = strtoupper(trim($teamCode));
        abort_unless(in_array($team, $this->allowedTeamCodes($this->resolveTeamCount($pichanga)), true), 422, 'Equipo no válido.');
        return $team;
    }

    private function ensurePichangaFormationIsMutable(GroupPichanga $pichanga): void
    {
        abort_if(in_array((string) $pichanga->status, ['cancelled', 'completed'], true)
            || ($pichanga->starts_at && now()->gte($pichanga->starts_at)), 422, 'La formación no puede modificarse cuando la pichanga ya empezó.');
    }

    private function ensureFormationReadable(GroupPichanga $pichanga, int $userId, string $team): void
    {
        $isAdmin = $this->isClubAdminForPichanga($pichanga, $userId);
        $isConfirmed = GroupPichangaParticipant::query()->where('pichanga_id', $pichanga->id)
            ->where('user_id', $userId)->where('status', 'confirmed')->exists();
        abort_unless($isAdmin || $isConfirmed, 403);
    }

    private function ensureFormationMutable(GroupPichanga $pichanga, int $userId, string $team, bool $isAdmin): void
    {
        $this->ensurePichangaFormationIsMutable($pichanga);
        if ($isAdmin) {
            return;
        }
        $isOnTeam = GroupPichangaParticipant::query()->where('pichanga_id', $pichanga->id)
            ->where('user_id', $userId)->where('status', 'confirmed')->where('team_code', $team)->exists();
        abort_unless($isOnTeam, 403, 'Solo puedes editar la formación de tu equipo.');
    }

    /** @return array<int,array<string,mixed>> */
    private function suggestFormation(GroupPichanga $pichanga, string $teamCode): array
    {
        $participants = GroupPichangaParticipant::query()->where('pichanga_id', $pichanga->id)
            ->where('status', 'confirmed')->where('team_code', $teamCode)->with('user:id,name,nick,avatar_url')->get();
        $ratings = $this->combinedSkillRatings->averagesByUserIds($participants->pluck('user_id')->map(fn ($id) => (int) $id), null);
        $players = $participants->map(function (GroupPichangaParticipant $participant) use ($ratings) {
            $summary = $ratings->has((int) $participant->user_id)
                ? $this->combinedSkillRatings->deriveSummary($ratings->get((int) $participant->user_id))
                : null;
            return ['participant' => $participant, 'summary' => $summary];
        })->values();
        $goalkeeper = $players->sortByDesc(fn ($player) => $player['summary']['arquero'] ?? -1)->first();
        $outfield = $players->reject(fn ($player) => $goalkeeper && $player['participant']->id === $goalkeeper['participant']->id)
            ->sortByDesc(fn ($player) => $player['summary']['stars'] ?? -1)->values();
        $roles = [];
        if ($goalkeeper) {
            $roles[] = ['player' => $goalkeeper, 'role' => 'goalkeeper'];
        }
        $roleSequence = ['defender', 'midfielder', 'forward'];
        foreach ($outfield as $index => $player) {
            $summary = $player['summary'] ?? [];
            $candidates = [
                'defender' => $summary['defensa'] ?? -1,
                'midfielder' => $summary['mediocampo'] ?? -1,
                'forward' => $summary['delantero'] ?? -1,
            ];
            arsort($candidates);
            $role = array_key_first($candidates);
            if (($candidates[$role] ?? -1) < 0) {
                $role = $roleSequence[$index % count($roleSequence)];
            }
            $roles[] = ['player' => $player, 'role' => $role];
        }
        $hasFormationCoordinates = Schema::hasColumn('group_pichanga_participants', 'formation_x')
            && Schema::hasColumn('group_pichanga_participants', 'formation_y');
        return collect($roles)->values()->map(function (array $item, int $index) use ($hasFormationCoordinates) {
            /** @var GroupPichangaParticipant $participant */
            $participant = $item['player']['participant'];
            $user = $participant->user;
            return [
                'user_id' => (int) $participant->user_id,
                'nick' => $user?->nick,
                'name' => $user?->name,
                'formation_role' => $participant->formation_role ?: $item['role'],
                'formation_order' => $participant->formation_order ?: $index + 1,
                'formation_x' => $hasFormationCoordinates ? $participant->formation_x : null,
                'formation_y' => $hasFormationCoordinates ? $participant->formation_y : null,
            ];
        })->all();
    }

    /**
     * @param array<string,mixed> $extra
     * @return array<string,mixed>
     */
    private function serializePichanga(GroupPichanga $pichanga, array $extra = []): array
    {
        $confirmed = array_key_exists('_confirmed_count', $extra)
            ? (int) $extra['_confirmed_count']
            : $this->confirmedParticipantsCount((int) $pichanga->id);
        unset($extra['_confirmed_count']);
        $meUserId = array_key_exists('_me_user_id', $extra) ? (int) $extra['_me_user_id'] : null;
        unset($extra['_me_user_id']);

        $teamCount = $this->resolveTeamCount($pichanga);
        $playersPerTeam = $this->resolvePlayersPerTeam($pichanga, $teamCount);
        $matchFormat = $this->resolveMatchFormat($pichanga, $teamCount);
        $teams = $this->buildTeamsBoard($pichanga, $teamCount, $playersPerTeam, $meUserId);

        return array_merge([
            'id' => $pichanga->id,
            'club_id' => $pichanga->club_id,
            'rival_club_id' => Schema::hasColumn('group_pichangas', 'rival_club_id') ? $pichanga->rival_club_id : null,
            'challenge_id' => Schema::hasColumn('group_pichangas', 'challenge_id') ? $pichanga->challenge_id : null,
            'match_context' => Schema::hasColumn('group_pichangas', 'match_context') ? ($pichanga->match_context ?? 'regular') : 'regular',
            'created_by_user_id' => $pichanga->created_by_user_id,
            'title' => $pichanga->title,
            'description' => $pichanga->description,
            'field_id' => $pichanga->field_id,
            'cancha_id' => Schema::hasColumn('group_pichangas', 'cancha_id') ? $pichanga->cancha_id : null,
            'address' => $pichanga->address,
            'starts_at' => optional($pichanga->starts_at)->toISOString(),
            'duration_minutes' => (int) $pichanga->duration_minutes,
            'capacity' => (int) $pichanga->capacity,
            'match_format' => $matchFormat,
            'team_count' => $teamCount,
            'players_per_team' => $playersPerTeam,
            'confirmed_count' => $confirmed,
            'spots_left' => max(0, (int) $pichanga->capacity - $confirmed),
            'waitlist_count' => Schema::hasTable('group_pichanga_waitlist')
                ? GroupPichangaWaitlistEntry::query()->where('pichanga_id', $pichanga->id)->where('status', 'waiting')->count()
                : 0,
            'status' => $pichanga->status,
            'confirmation_mode' => $pichanga->confirmation_mode,
            'is_open' => (bool) $pichanga->is_open,
            'notify_degree' => (int) $pichanga->notify_degree,
            'allow_external_requests' => (bool) $pichanga->allow_external_requests,
            'invited_link_enabled' => Schema::hasColumn('group_pichangas', 'invited_link_enabled') ? (bool) ($pichanga->invited_link_enabled ?? false) : false,
            'invited_link_code' => Schema::hasColumn('group_pichangas', 'invited_link_code') ? $pichanga->invited_link_code : null,
            'auto_reminder_enabled' => (bool) ($pichanga->auto_reminder_enabled ?? true),
            'auto_reminder_48h_sent_at' => optional($pichanga->auto_reminder_48h_sent_at)->toISOString(),
            'auto_reminder_24h_sent_at' => optional($pichanga->auto_reminder_24h_sent_at)->toISOString(),
            'withdraw_until' => optional($pichanga->withdraw_until)->toISOString(),
            'audience_filters' => [
                'sex' => $pichanga->audience_sex,
                'age_min' => $pichanga->audience_age_min,
                'age_max' => $pichanga->audience_age_max,
                'fisico_min' => $pichanga->skill_fisico_min,
                'arquero_min' => $pichanga->skill_arquero_min,
                'delantero_min' => $pichanga->skill_delantero_min,
                'mediocampo_min' => $pichanga->skill_mediocampo_min,
                'defensa_min' => $pichanga->skill_defensa_min,
            ],
            'renotify_sent_count' => (int) ($pichanga->renotify_sent_count ?? 0),
            'last_renotify_at' => optional($pichanga->last_renotify_at)->toISOString(),
            'share_url' => $this->buildPichangaShareUrl((int) $pichanga->id),
            'teams' => $teams,
        ], $extra);
    }

    private function resolveMatchFormat(GroupPichanga $pichanga, int $teamCount): string
    {
        if (Schema::hasColumn('group_pichangas', 'match_format')) {
            $value = (string) ($pichanga->match_format ?? '');
            if (in_array($value, ['versus', 'triangular', 'cuadrangular'], true)) {
                return $value;
            }
        }

        return match ($teamCount) {
            3 => 'triangular',
            4 => 'cuadrangular',
            default => 'versus',
        };
    }

    private function teamCountFromFormat(string $matchFormat): int
    {
        return match ($matchFormat) {
            'triangular' => 3,
            'cuadrangular' => 4,
            default => 2,
        };
    }

    private function resolveTeamCount(GroupPichanga $pichanga): int
    {
        if (Schema::hasColumn('group_pichangas', 'team_count')) {
            $value = (int) ($pichanga->team_count ?? 0);
            if (in_array($value, [2, 3, 4], true)) {
                return $value;
            }
        }

        if (Schema::hasColumn('group_pichangas', 'match_format')) {
            return $this->teamCountFromFormat((string) ($pichanga->match_format ?? 'versus'));
        }

        return 2;
    }

    private function resolvePlayersPerTeam(GroupPichanga $pichanga, int $teamCount): int
    {
        if (Schema::hasColumn('group_pichangas', 'players_per_team')) {
            $value = (int) ($pichanga->players_per_team ?? 0);
            if ($value > 0) {
                return $value;
            }
        }

        $capacity = max(1, (int) $pichanga->capacity);
        return max(1, (int) ceil($capacity / max(1, $teamCount)));
    }

    /**
     * @return array<int, string>
     */
    private function allowedTeamCodes(int $teamCount): array
    {
        return array_slice(['A', 'B', 'C', 'D'], 0, max(2, min(4, $teamCount)));
    }

    private function nextTeamSlot(int $pichangaId, string $teamCode): int
    {
        if (!Schema::hasColumn('group_pichanga_participants', 'team_slot') || !Schema::hasColumn('group_pichanga_participants', 'team_code')) {
            return 1;
        }

        $slots = GroupPichangaParticipant::query()
            ->where('pichanga_id', $pichangaId)
            ->where('status', 'confirmed')
            ->where('team_code', $teamCode)
            ->lockForUpdate()
            ->pluck('team_slot')
            ->filter(fn($slot) => $slot !== null)
            ->map(fn($slot) => (int) $slot)
            ->all();

        $max = empty($slots) ? 0 : max($slots);
        return $max + 1;
    }

    private function pickLeastLoadedTeamCode(GroupPichanga $pichanga): string
    {
        $teamCount = $this->resolveTeamCount($pichanga);
        $teamCodes = $this->allowedTeamCodes($teamCount);
        if (!Schema::hasColumn('group_pichanga_participants', 'team_code')) {
            return $teamCodes[0];
        }

        $counts = GroupPichangaParticipant::query()
            ->selectRaw('team_code, COUNT(*) as total')
            ->where('pichanga_id', $pichanga->id)
            ->where('status', 'confirmed')
            ->whereIn('team_code', $teamCodes)
            ->groupBy('team_code')
            ->pluck('total', 'team_code');

        $bestCode = $teamCodes[0];
        $bestCount = PHP_INT_MAX;
        foreach ($teamCodes as $code) {
            $count = (int) ($counts[$code] ?? 0);
            if ($count < $bestCount) {
                $bestCount = $count;
                $bestCode = $code;
            }
        }

        return $bestCode;
    }

    /**
     * @return array<int, array<string, mixed>>
     */
    private function buildTeamsBoard(GroupPichanga $pichanga, int $teamCount, int $playersPerTeam, ?int $meUserId): array
    {
        $teamCodes = $this->allowedTeamCodes($teamCount);
        $hasTeamColumns = Schema::hasColumn('group_pichanga_participants', 'team_code')
            && Schema::hasColumn('group_pichanga_participants', 'team_slot');

        $rows = GroupPichangaParticipant::query()
            ->where('pichanga_id', $pichanga->id)
            ->where('status', 'confirmed')
            ->with(['user:id,name,nick,avatar_url'])
            ->orderByRaw('COALESCE(confirmed_at, created_at) asc')
            ->orderBy('id')
            ->get();

        $assigned = [];
        if ($hasTeamColumns) {
            foreach ($rows as $row) {
                $code = strtoupper((string) ($row->team_code ?? ''));
                if (!in_array($code, $teamCodes, true)) {
                    continue;
                }
                $slot = max(1, (int) ($row->team_slot ?? 1));
                $assigned[$code][$slot] = $row;
            }
        } else {
            $i = 0;
            foreach ($rows as $row) {
                $code = $teamCodes[$i % $teamCount];
                $slot = intdiv($i, $teamCount) + 1;
                $assigned[$code][$slot] = $row;
                $i++;
            }
        }

        $allUserIds = collect($rows)->pluck('user_id')->map(fn($id) => (int) $id)->unique()->values();
        $skillRows = $this->combinedSkillRatings->averagesByUserIds($allUserIds, null);

        $teams = [];
        foreach ($teamCodes as $code) {
            /** @var array<int, GroupPichangaParticipant> $teamSlots */
            $teamSlots = $assigned[$code] ?? [];
            $maxSlot = empty($teamSlots) ? $playersPerTeam : max($playersPerTeam, max(array_keys($teamSlots)));
            $orderedSlots = [];
            $teamUserIds = [];

            for ($slot = 1; $slot <= $maxSlot; $slot++) {
                $participant = $teamSlots[$slot] ?? null;
                if ($participant) {
                    $user = $participant->user;
                    $teamUserIds[] = (int) $participant->user_id;
                    $userRow = $skillRows->get((int) $participant->user_id);
                    $summary = $userRow ? $this->combinedSkillRatings->deriveSummary($userRow) : null;
                    $userStars = $summary['stars'] ?? null;

                    $orderedSlots[] = [
                        'slot' => $slot,
                        'formation_role' => Schema::hasColumn('group_pichanga_participants', 'formation_role') ? $participant->formation_role : null,
                        'formation_order' => Schema::hasColumn('group_pichanga_participants', 'formation_order') ? $participant->formation_order : null,
                        'user' => [
                            'id' => (int) $participant->user_id,
                            'nick' => $user?->nick,
                            'name' => $user?->name,
                            'avatar_url' => $user?->avatar_url,
                            'avg_rating' => $userStars !== null ? (float) $userStars : null,
                            'is_me' => $meUserId !== null && (int) $participant->user_id === $meUserId,
                        ],
                    ];
                } else {
                    $orderedSlots[] = [
                        'slot' => $slot,
                        'user' => null,
                    ];
                }
            }

            $teams[] = [
                'code' => $code,
                'label' => "Equipo {$code}",
                'base_size' => $playersPerTeam,
                'confirmed_count' => count($teamSlots),
                'next_slot' => empty($teamSlots) ? 1 : (max(array_keys($teamSlots)) + 1),
                'avg_rating' => $this->teamOverallAverage($teamUserIds, $skillRows),
                'slots' => $orderedSlots,
            ];
        }

        return $teams;
    }

    private function teamOverallAverage(array $userIds, \Illuminate\Support\Collection $skillRows): ?float
    {
        if (empty($userIds)) {
            return null;
        }

        $scores = [];
        foreach ($userIds as $userId) {
            $row = $skillRows->get((int) $userId);
            if (!$row) {
                continue;
            }

            $summary = $this->combinedSkillRatings->deriveSummary($row);
            if ($summary['stars'] === null) {
                continue;
            }
            $scores[] = $summary['stars'];
        }

        if (empty($scores)) {
            return null;
        }

        return round(array_sum($scores) / count($scores), 1);
    }

    private function filterPayloadByTableColumns(string $table, array $payload): array
    {
        return collect($payload)
            ->filter(fn($_, $key) => Schema::hasColumn($table, (string) $key))
            ->all();
    }

    private function buildPichangaShareUrl(int $pichangaId): string
    {
        $base = rtrim((string) config('services.app_links.base_url', config('app.url')), '/');
        return $base . '/pichanga/' . $pichangaId;
    }

    private function pichangaImageUrl(GroupPichanga $pichanga): string
    {
        $canchaId = (int) ($pichanga->cancha_id ?? 0);
        if ($canchaId <= 0 || !Schema::hasTable('cancha')) {
            return '';
        }
        $cancha = Cancha::query()->with(['photos', 'polideportivo.photos'])->find($canchaId);
        return (string) ($cancha?->photos->first()?->photo_url
            ?? $cancha?->polideportivo?->photos->first()?->photo_url
            ?? '');
    }

    /**
     * @param array<int> $userClubIds
     */
    private function isMemberOfPichanga(GroupPichanga $pichanga, array $userClubIds): bool
    {
        if (in_array((int) $pichanga->club_id, $userClubIds, true)) {
            return true;
        }

        if ((string) ($pichanga->match_context ?? 'regular') === 'club_challenge') {
            $rivalClubId = (int) ($pichanga->rival_club_id ?? 0);
            if ($rivalClubId > 0 && in_array($rivalClubId, $userClubIds, true)) {
                return true;
            }
        }

        return false;
    }

    private function isClubAdminForPichanga(GroupPichanga $pichanga, int $userId): bool
    {
        if ($this->isClubAdmin((int) $pichanga->club_id, $userId)) {
            return true;
        }

        if ((string) ($pichanga->match_context ?? 'regular') === 'club_challenge') {
            $rivalClubId = (int) ($pichanga->rival_club_id ?? 0);
            if ($rivalClubId > 0 && $this->isClubAdmin($rivalClubId, $userId)) {
                return true;
            }
        }

        return false;
    }
}
