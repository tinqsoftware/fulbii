<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\FieldSubmission;
use App\Models\Polideportivo;
use App\Models\Report;
use App\Models\Strike;
use App\Models\User;
use App\Services\AdminAccessService;
use App\Services\ModerationService;
use App\Services\ProductEventService;
use Carbon\Carbon;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\Schema;
use Illuminate\Validation\Rule;
use Illuminate\View\View;

class BackofficeController extends Controller
{
    public function __construct(
        private readonly AdminAccessService $adminAccess,
        private readonly ModerationService $moderationService,
        private readonly ProductEventService $eventService
    ) {
    }

    public function dashboard(Request $request): View
    {
        $auth = $request->user() ?? abort(401);
        $this->adminAccess->ensureBackoffice($auth);

        $stats = [
            'pending_reports' => $this->safeCount('reports', ['status' => 'pending']),
            'pending_field_submissions' => $this->safeCount('field_submissions', ['status' => 'pending']),
            'active_strikes' => Schema::hasTable('strikes')
                ? (int) Strike::query()
                    ->where('status', 'active')
                    ->where(fn ($q) => $q->whereNull('expires_at')->orWhere('expires_at', '>', now()))
                    ->count()
                : 0,
            'jobs_pending' => Schema::hasTable('jobs') ? (int) DB::table('jobs')->count() : 0,
            'failed_jobs_count' => Schema::hasTable('failed_jobs') ? (int) DB::table('failed_jobs')->count() : 0,
        ];

        $readiness = $this->buildReadiness();
        $growth = $this->buildGrowth(now()->copy()->subDays(6)->startOfDay(), now()->endOfDay());

        return view('admin.dashboard', [
            'stats' => $stats,
            'readiness' => $readiness,
            'growth' => $growth,
            'canCritical' => $auth->canPerformCriticalAdminActions(),
        ]);
    }

    public function reports(Request $request): View
    {
        $auth = $request->user() ?? abort(401);
        $this->adminAccess->ensureBackoffice($auth);

        $filters = $request->validate([
            'status' => ['nullable', Rule::in(['pending', 'reviewed', 'dismissed', 'actioned'])],
            'target_type' => ['nullable', Rule::in(['user', 'field', 'field_photo', 'group_pichanga'])],
            'q' => ['nullable', 'string', 'max:120'],
        ]);

        $query = Report::query()
            ->with('reporter:id,name,nick,email')
            ->orderByDesc('id');

        if (!empty($filters['status'])) {
            $query->where('status', $filters['status']);
        }
        if (!empty($filters['target_type'])) {
            $query->where('target_type', $filters['target_type']);
        }
        if (!empty($filters['q'])) {
            $q = trim((string) $filters['q']);
            $query->where(function ($sub) use ($q) {
                $sub->where('reason_code', 'like', "%{$q}%")
                    ->orWhere('description', 'like', "%{$q}%")
                    ->orWhere('target_id', 'like', "%{$q}%")
                    ->orWhereHas('reporter', function ($uq) use ($q) {
                        $uq->where('name', 'like', "%{$q}%")
                            ->orWhere('nick', 'like', "%{$q}%")
                            ->orWhere('email', 'like', "%{$q}%");
                    });
            });
        }

        return view('admin.reports', [
            'items' => $query->paginate(30)->withQueryString(),
            'filters' => $filters,
        ]);
    }

    public function resolveReport(Request $request, Report $report): RedirectResponse
    {
        $auth = $request->user() ?? abort(401);
        $this->adminAccess->ensureBackoffice($auth);

        $data = $request->validate([
            'status' => ['required', Rule::in(['reviewed', 'dismissed', 'actioned'])],
            'resolution_note' => ['nullable', 'string', 'max:255'],
        ]);

        $report->update([
            'status' => (string) $data['status'],
            'resolved_by_user_id' => $auth->id,
            'resolved_at' => now(),
            'resolution_note' => $data['resolution_note'] ?? null,
        ]);

        $this->eventService->track(
            'admin_web_report_resolved',
            (int) $auth->id,
            null,
            null,
            [
                'report_id' => (int) $report->id,
                'status' => (string) $data['status'],
            ],
            'admin_web'
        );

        return back()->with('ok', 'Reporte actualizado.');
    }

    public function bulkResolveReports(Request $request): RedirectResponse
    {
        $auth = $request->user() ?? abort(401);
        $this->adminAccess->ensureBackoffice($auth);

        $data = $request->validate([
            'ids' => ['required', 'array', 'min:1', 'max:500'],
            'ids.*' => ['required', 'integer', 'min:1'],
            'status' => ['required', Rule::in(['reviewed', 'dismissed', 'actioned'])],
            'resolution_note' => ['nullable', 'string', 'max:255'],
        ]);

        $ids = collect((array) $data['ids'])->map(fn ($id) => (int) $id)->unique()->values()->all();
        $result = $this->processBulkReports(
            $auth,
            $ids,
            (string) $data['status'],
            $data['resolution_note'] ?? null
        );

        return back()->with('ok', $this->formatBulkFlashMessage('Reportes', $result));
    }

    public function fieldSubmissions(Request $request): View
    {
        $auth = $request->user() ?? abort(401);
        $this->adminAccess->ensureBackoffice($auth);

        $filters = $request->validate([
            'status' => ['nullable', Rule::in(['pending', 'approved', 'rejected'])],
            'q' => ['nullable', 'string', 'max:120'],
        ]);

        $query = FieldSubmission::query()
            ->with([
                'user:id,name,nick,email',
                'photos',
                'existingPolideportivo' => fn ($query) => $query
                    ->select(['id', 'nombre', 'direccion', 'url_foto'])
                    ->withCount('canchas'),
                'approvedPolideportivo:id,nombre',
                'approvedCancha:id,nombre',
            ])
            ->orderByDesc('id');

        if (!empty($filters['status'])) {
            $query->where('status', (string) $filters['status']);
        }
        if (!empty($filters['q'])) {
            $q = trim((string) $filters['q']);
            $query->where(function ($sub) use ($q) {
                $sub->where('nombre', 'like', "%{$q}%")
                    ->orWhere('direccion', 'like', "%{$q}%")
                    ->orWhere('descripcion', 'like', "%{$q}%")
                    ->orWhereHas('user', function ($uq) use ($q) {
                        $uq->where('name', 'like', "%{$q}%")
                            ->orWhere('nick', 'like', "%{$q}%")
                            ->orWhere('email', 'like', "%{$q}%");
                    });
            });
        }

        return view('admin.field_submissions', [
            'items' => $query->paginate(30)->withQueryString(),
            'filters' => $filters,
            'correctionPolideportivos' => Polideportivo::query()
                ->select(['id', 'nombre', 'direccion'])
                ->orderBy('nombre')
                ->limit(300)
                ->get(),
        ]);
    }

    public function decideFieldSubmission(Request $request, FieldSubmission $submission): RedirectResponse
    {
        $auth = $request->user() ?? abort(401);
        $this->adminAccess->ensureBackoffice($auth);

        $data = $request->validate([
            'action' => ['required', Rule::in(['approve', 'reject'])],
            'resolution_note' => ['nullable', 'string', 'max:255'],
            'existing_polideportivo_id' => [
                'nullable',
                'integer',
                'min:1',
                Rule::exists('polideportivo', 'id'),
            ],
        ]);

        if ($data['action'] === 'approve' && !empty($data['existing_polideportivo_id'])) {
            $this->correctFieldSubmissionDestination(
                $submission,
                (int) $data['existing_polideportivo_id']
            );
        }

        $this->decideFieldSubmissionItem(
            $submission,
            $auth,
            (string) $data['action'],
            $data['resolution_note'] ?? null
        );

        $this->eventService->track(
            'admin_web_field_submission_decided',
            (int) $auth->id,
            null,
            null,
            [
                'submission_id' => (int) $submission->id,
                'action' => (string) $data['action'],
            ],
            'admin_web'
        );

        return back()->with('ok', 'Solicitud procesada.');
    }

    public function bulkDecisionFieldSubmissions(Request $request): RedirectResponse
    {
        $auth = $request->user() ?? abort(401);
        $this->adminAccess->ensureBackoffice($auth);

        $data = $request->validate([
            'ids' => ['required', 'array', 'min:1', 'max:500'],
            'ids.*' => ['required', 'integer', 'min:1'],
            'action' => ['required', Rule::in(['approve', 'reject'])],
            'resolution_note' => ['nullable', 'string', 'max:255'],
        ]);

        $ids = collect((array) $data['ids'])->map(fn ($id) => (int) $id)->unique()->values()->all();
        $result = $this->emptyBulkCounter();
        foreach ($ids as $id) {
            try {
                DB::transaction(function () use ($id, $auth, $data, &$result) {
                    $submission = FieldSubmission::query()->with('photos')->find((int) $id);
                    if (!$submission) {
                        $result['errors']++;
                        return;
                    }
                    if ($submission->status !== 'pending') {
                        $result['skipped']++;
                        return;
                    }
                    $this->decideFieldSubmissionItem(
                        $submission,
                        $auth,
                        (string) $data['action'],
                        $data['resolution_note'] ?? null
                    );
                    $result['processed']++;
                });
            } catch (\Throwable $e) {
                $result['errors']++;
            }
        }

        $this->eventService->track(
            'admin_web_bulk_field_submissions_decided',
            (int) $auth->id,
            null,
            null,
            [
                'processed' => (int) $result['processed'],
                'skipped' => (int) $result['skipped'],
                'errors' => (int) $result['errors'],
                'action' => (string) $data['action'],
            ],
            'admin_web'
        );

        return back()->with('ok', $this->formatBulkFlashMessage('Solicitudes', $result));
    }

    public function strikes(Request $request): View
    {
        $auth = $request->user() ?? abort(401);
        $this->adminAccess->ensureBackoffice($auth);

        $filters = $request->validate([
            'status' => ['nullable', Rule::in(['active', 'revoked'])],
            'q' => ['nullable', 'string', 'max:120'],
            'user_id' => ['nullable', 'integer', 'min:1'],
        ]);

        $query = Strike::query()
            ->with(['user:id,name,nick,email'])
            ->orderByDesc('id');

        if (!empty($filters['status'])) {
            $query->where('status', $filters['status']);
        }
        if (!empty($filters['user_id'])) {
            $query->where('user_id', (int) $filters['user_id']);
        }
        if (!empty($filters['q'])) {
            $q = trim((string) $filters['q']);
            $query->where(function ($sub) use ($q) {
                $sub->where('reason_code', 'like', "%{$q}%")
                    ->orWhere('description', 'like', "%{$q}%")
                    ->orWhereHas('user', function ($uq) use ($q) {
                        $uq->where('name', 'like', "%{$q}%")
                            ->orWhere('nick', 'like', "%{$q}%")
                            ->orWhere('email', 'like', "%{$q}%");
                    });
            });
        }

        return view('admin.strikes', [
            'items' => $query->paginate(30)->withQueryString(),
            'filters' => $filters,
            'canCritical' => $auth->canPerformCriticalAdminActions(),
        ]);
    }

    public function issueStrike(Request $request): RedirectResponse
    {
        $auth = $request->user() ?? abort(401);
        $this->adminAccess->ensureBackoffice($auth);

        $data = $request->validate([
            'user_id' => ['required', 'integer', 'exists:users,id'],
            'report_id' => ['nullable', 'integer', 'exists:reports,id'],
            'reason_code' => ['required', 'string', 'max:60'],
            'description' => ['nullable', 'string', 'max:500'],
            'expires_days' => ['nullable', 'integer', 'min:1', 'max:365'],
        ]);

        $target = User::findOrFail((int) $data['user_id']);
        $this->adminAccess->ensureNotSelfAction($auth, (int) $target->id, 'un strike');
        if (!$auth->canPerformCriticalAdminActions() && $target->canAccessBackoffice()) {
            $this->eventService->track(
                'admin_web_action_blocked',
                (int) $auth->id,
                null,
                null,
                [
                    'action' => 'issue_strike',
                    'target_user_id' => (int) $target->id,
                    'reason' => 'target_backoffice_user',
                ],
                'admin_web'
            );
        }
        $this->adminAccess->ensureCanIssueStrike($auth, $target);
        $strike = $this->moderationService->issueStrike(
            $target,
            $auth,
            (string) $data['reason_code'],
            $data['description'] ?? null,
            $data['report_id'] ?? null,
            $data['expires_days'] ?? null
        );

        $this->eventService->track(
            'admin_web_strike_issued',
            (int) $auth->id,
            null,
            null,
            [
                'strike_id' => (int) $strike->id,
                'target_user_id' => (int) $target->id,
                'report_id' => !empty($data['report_id']) ? (int) $data['report_id'] : null,
            ],
            'admin_web'
        );

        return back()->with('ok', 'Strike aplicado.');
    }

    public function revokeStrike(Request $request, Strike $strike): RedirectResponse
    {
        $auth = $request->user() ?? abort(401);
        $this->adminAccess->ensureBackoffice($auth);
        if ($this->adminAccess->isStaffCriticalBlock($auth, $strike)) {
            $this->eventService->track(
                'admin_web_action_blocked',
                (int) $auth->id,
                null,
                null,
                [
                    'action' => 'revoke_strike',
                    'strike_id' => (int) $strike->id,
                    'reason' => 'critical_revoke_blocked_for_staff',
                ],
                'admin_web'
            );
        }
        $this->adminAccess->ensureCanRevokeStrike($auth, $strike);

        $data = $request->validate([
            'revoked_note' => ['nullable', 'string', 'max:255'],
        ]);

        $this->moderationService->revokeStrike($strike, $auth, $data['revoked_note'] ?? null);
        $this->eventService->track(
            'admin_web_strike_revoked',
            (int) $auth->id,
            null,
            null,
            ['strike_id' => (int) $strike->id],
            'admin_web'
        );

        return back()->with('ok', 'Strike revocado.');
    }

    public function bulkRevokeStrikes(Request $request): RedirectResponse
    {
        $auth = $request->user() ?? abort(401);
        $this->adminAccess->ensureBackoffice($auth);

        $data = $request->validate([
            'ids' => ['required', 'array', 'min:1', 'max:500'],
            'ids.*' => ['required', 'integer', 'min:1'],
            'revoked_note' => ['nullable', 'string', 'max:255'],
        ]);

        $ids = collect((array) $data['ids'])->map(fn ($id) => (int) $id)->unique()->values()->all();
        $result = $this->emptyBulkCounter();
        foreach ($ids as $id) {
            try {
                DB::transaction(function () use ($id, $auth, $data, &$result) {
                    $strike = Strike::query()->with('user')->find((int) $id);
                    if (!$strike) {
                        $result['errors']++;
                        return;
                    }
                    if ($strike->status === 'revoked') {
                        $result['skipped']++;
                        return;
                    }
                    if ($this->adminAccess->isStaffCriticalBlock($auth, $strike)) {
                        $result['skipped']++;
                        $this->eventService->track(
                            'admin_web_action_blocked',
                            (int) $auth->id,
                            null,
                            null,
                            [
                                'action' => 'bulk_revoke_strike',
                                'strike_id' => (int) $id,
                                'reason' => 'critical_revoke_blocked_for_staff',
                            ],
                            'admin_web'
                        );
                        return;
                    }
                    $this->moderationService->revokeStrike($strike, $auth, $data['revoked_note'] ?? null);
                    $result['processed']++;
                });
            } catch (\Throwable $e) {
                $result['errors']++;
            }
        }

        $this->eventService->track(
            'admin_web_bulk_strikes_revoked',
            (int) $auth->id,
            null,
            null,
            [
                'processed' => (int) $result['processed'],
                'skipped' => (int) $result['skipped'],
                'errors' => (int) $result['errors'],
            ],
            'admin_web'
        );

        return back()->with('ok', $this->formatBulkFlashMessage('Strikes', $result));
    }

    public function setUserSuspension(Request $request, User $user): RedirectResponse
    {
        $auth = $request->user() ?? abort(401);
        $this->adminAccess->ensureSuper($auth);
        $this->adminAccess->ensureNotSelfAction($auth, (int) $user->id, 'una suspensión');

        $data = $request->validate([
            'suspended_until' => ['nullable', 'date'],
            'suspension_reason' => ['nullable', 'string', 'max:255'],
        ]);

        $user->update([
            'suspended_until' => $data['suspended_until'] ?? null,
            'suspension_reason' => $data['suspension_reason'] ?? null,
        ]);

        $this->eventService->track(
            'admin_web_user_suspension_updated',
            (int) $auth->id,
            null,
            null,
            [
                'target_user_id' => (int) $user->id,
                'suspended_until' => $data['suspended_until'] ?? null,
                'reason' => $data['suspension_reason'] ?? null,
            ],
            'admin_web'
        );

        return back()->with('ok', 'Suspensión actualizada.');
    }

    public function metricsGrowth(Request $request): View
    {
        $auth = $request->user() ?? abort(401);
        $this->adminAccess->ensureBackoffice($auth);

        $data = $request->validate([
            'from' => ['nullable', 'date'],
            'to' => ['nullable', 'date'],
        ]);

        $from = !empty($data['from']) ? Carbon::parse((string) $data['from'])->startOfDay() : now()->copy()->subDays(29)->startOfDay();
        $to = !empty($data['to']) ? Carbon::parse((string) $data['to'])->endOfDay() : now()->endOfDay();
        abort_if($from->gt($to), 422, 'Rango de fechas inválido.');

        return view('admin.metrics_growth', [
            'growth' => $this->buildGrowth($from, $to),
            'from' => $from->toDateString(),
            'to' => $to->toDateString(),
        ]);
    }

    public function opsReadiness(Request $request): View
    {
        $auth = $request->user() ?? abort(401);
        $this->adminAccess->ensureBackoffice($auth);

        return view('admin.ops_readiness', [
            'readiness' => $this->buildReadiness(),
        ]);
    }

    private function processBulkReports(User $auth, array $ids, string $status, ?string $note): array
    {
        $result = ['processed' => 0, 'skipped' => 0, 'errors' => 0];

        foreach ($ids as $id) {
            try {
                DB::transaction(function () use ($id, $auth, $status, $note, &$result) {
                    $report = Report::query()->find((int) $id);
                    if (!$report) {
                        $result['errors']++;
                        return;
                    }
                    if ($report->status !== 'pending') {
                        $result['skipped']++;
                        return;
                    }

                    $report->update([
                        'status' => $status,
                        'resolved_by_user_id' => $auth->id,
                        'resolved_at' => now(),
                        'resolution_note' => $note,
                    ]);
                    $result['processed']++;
                });
            } catch (\Throwable $e) {
                $result['errors']++;
            }
        }

        $this->eventService->track(
            'admin_web_bulk_reports_resolved',
            (int) $auth->id,
            null,
            null,
            $result + ['status' => $status],
            'admin_web'
        );

        return $result;
    }

    /**
     * @return array{message:string,approved_polideportivo_id?:int}
     */
    private function decideFieldSubmissionItem(
        FieldSubmission $submission,
        User $auth,
        string $action,
        ?string $resolutionNote
    ): array {
        return app(\App\Services\FieldSubmissionApprovalService::class)->decide($submission, $auth, $action, $resolutionNote);
    }

    private function correctFieldSubmissionDestination(
        FieldSubmission $submission,
        int $polideportivoId
    ): void {
        abort_if(
            $submission->status !== 'pending',
            422,
            'Solo se pueden corregir solicitudes pendientes.'
        );

        $submission->update([
            'submission_type' => 'existing_polideportivo',
            'existing_polideportivo_id' => $polideportivoId,
        ]);
    }

    /**
     * @return array{range:array{from:string,to:string},totals:array<string,mixed>,daily:array<int,array<string,mixed>>}
     */
    private function buildGrowth(Carbon $from, Carbon $to): array
    {
        if (!Schema::hasTable('product_events')) {
            return [
                'range' => ['from' => $from->toDateString(), 'to' => $to->toDateString()],
                'totals' => [],
                'daily' => [],
            ];
        }

        $rows = DB::table('product_events')
            ->selectRaw('DATE(happened_at) as day, event_name, COUNT(*) as total')
            ->whereBetween('happened_at', [$from, $to])
            ->groupByRaw('DATE(happened_at), event_name')
            ->orderBy('day')
            ->get();

        $daily = [];
        foreach ($rows as $row) {
            $day = (string) $row->day;
            if (!isset($daily[$day])) {
                $daily[$day] = [
                    'day' => $day,
                    'club_join_request_created' => 0,
                    'club_join_request_cancelled' => 0,
                    'club_join_request_accepted' => 0,
                    'club_join_request_rejected' => 0,
                    'pichanga_created' => 0,
                    'pichanga_confirmed' => 0,
                    'pichanga_withdrawn' => 0,
                    'pichanga_renotify_sent' => 0,
                    'pichanga_auto_48h_sent' => 0,
                    'pichanga_auto_24h_sent' => 0,
                ];
            }
            $eventName = (string) $row->event_name;
            if (array_key_exists($eventName, $daily[$day])) {
                $daily[$day][$eventName] = (int) $row->total;
            }
        }

        ksort($daily);
        $dailyItems = array_values($daily);
        $totals = [
            'join_requests' => 0,
            'join_accepted' => 0,
            'join_rejected' => 0,
            'join_cancelled' => 0,
            'pichangas_created' => 0,
            'confirmations' => 0,
            'withdrawals' => 0,
            'renotify_sent' => 0,
            'auto_48h_sent' => 0,
            'auto_24h_sent' => 0,
        ];
        foreach ($dailyItems as $item) {
            $totals['join_requests'] += (int) $item['club_join_request_created'];
            $totals['join_accepted'] += (int) $item['club_join_request_accepted'];
            $totals['join_rejected'] += (int) $item['club_join_request_rejected'];
            $totals['join_cancelled'] += (int) $item['club_join_request_cancelled'];
            $totals['pichangas_created'] += (int) $item['pichanga_created'];
            $totals['confirmations'] += (int) $item['pichanga_confirmed'];
            $totals['withdrawals'] += (int) $item['pichanga_withdrawn'];
            $totals['renotify_sent'] += (int) $item['pichanga_renotify_sent'];
            $totals['auto_48h_sent'] += (int) $item['pichanga_auto_48h_sent'];
            $totals['auto_24h_sent'] += (int) $item['pichanga_auto_24h_sent'];
        }

        $denominator = max(1, $totals['pichangas_created']);
        $totals['avg_confirmations_per_pichanga'] = round($totals['confirmations'] / $denominator, 2);

        return [
            'range' => ['from' => $from->toDateString(), 'to' => $to->toDateString()],
            'totals' => $totals,
            'daily' => $dailyItems,
        ];
    }

    /**
     * @return array<string,mixed>
     */
    private function buildReadiness(): array
    {
        $queueConnection = (string) config('queue.default', 'sync');
        $jobsPending = Schema::hasTable('jobs') ? (int) DB::table('jobs')->count() : 0;
        $failedJobsCount = Schema::hasTable('failed_jobs') ? (int) DB::table('failed_jobs')->count() : 0;

        $lastAutoWaveAt = null;
        if (Schema::hasTable('group_pichanga_notification_batches')) {
            $lastAutoWaveAt = DB::table('group_pichanga_notification_batches')
                ->whereIn('batch_type', ['auto_48h', 'auto_24h'])
                ->max('created_at');
        }

        $commands = Artisan::all();
        $autoReminderCommandAvailable = array_key_exists('pichangas:auto-reminders', $commands);
        $pushDriver = (string) config('push.driver', 'log');
        $appLinkBaseUrl = (string) config('services.app_links.base_url', '');
        $fcmV1Ready = $pushDriver !== 'fcm'
            || (
                trim((string) config('push.fcm_project_id', '')) !== ''
                && trim((string) config('push.fcm_service_account_path', '')) !== ''
            );

        $iosAppIds = array_filter((array) config('services.app_links.ios_app_ids', []));
        $androidPackageName = (string) config('services.app_links.android_package_name', '');
        $androidFingerprints = array_filter((array) config('services.app_links.android_sha256_cert_fingerprints', []));

        $wellKnownRoutesPresent = Route::has('well-known.aasa') && Route::has('well-known.assetlinks');
        $wellKnownEndpointsOk = $wellKnownRoutesPresent
            && !empty($iosAppIds)
            && $androidPackageName !== ''
            && !empty($androidFingerprints);

        return [
            'queue_connection' => $queueConnection,
            'jobs_pending' => $jobsPending,
            'failed_jobs_count' => $failedJobsCount,
            'auto_reminder_command_available' => $autoReminderCommandAvailable,
            'last_auto_wave_at' => $lastAutoWaveAt ? Carbon::parse((string) $lastAutoWaveAt)->toISOString() : null,
            'product_events_enabled' => Schema::hasTable('product_events'),
            'push_driver' => $pushDriver,
            'fcm_v1_ready' => $fcmV1Ready,
            'app_link_base_url' => $appLinkBaseUrl,
            'well_known_endpoints_ok' => $wellKnownEndpointsOk,
        ];
    }

    private function safeCount(string $table, array $where = []): int
    {
        if (!Schema::hasTable($table)) {
            return 0;
        }

        $query = DB::table($table);
        foreach ($where as $key => $value) {
            $query->where($key, $value);
        }

        return (int) $query->count();
    }

    /**
     * @param array{processed:int,skipped:int,errors:int} $result
     */
    private function formatBulkFlashMessage(string $label, array $result): string
    {
        return "{$label}: procesados {$result['processed']}, omitidos {$result['skipped']}, errores {$result['errors']}.";
    }

    /**
     * @return array{processed:int,skipped:int,errors:int}
     */
    private function emptyBulkCounter(): array
    {
        return [
            'processed' => 0,
            'skipped' => 0,
            'errors' => 0,
        ];
    }

}
