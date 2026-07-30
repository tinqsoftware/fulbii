<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\FieldSubmission;
use App\Models\FieldSubmissionPhoto;
use App\Models\Polideportivo;
use App\Models\Report;
use App\Models\Strike;
use App\Models\User;
use App\Services\AdminAccessService;
use App\Services\ModerationService;
use App\Services\ProductEventService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;

class AdminModerationController extends Controller
{
    public function __construct(
        private readonly AdminAccessService $adminAccess,
        private readonly ModerationService $moderationService,
        private readonly ProductEventService $eventService
    )
    {
    }

    public function reports(Request $request)
    {
        $auth = $request->user() ?? abort(401);
        $this->adminAccess->ensureBackoffice($auth);

        $status = (string) $request->query('status', '');
        $targetType = (string) $request->query('target_type', '');

        $query = Report::query()->with('reporter:id,name,nick,email')->orderByDesc('id');
        if ($status !== '' && in_array($status, ['pending', 'reviewed', 'dismissed', 'actioned'], true)) {
            $query->where('status', $status);
        }
        if ($targetType !== '' && in_array($targetType, ['user', 'field', 'field_photo', 'group_pichanga'], true)) {
            $query->where('target_type', $targetType);
        }

        return response()->json(['items' => $query->limit(300)->get()]);
    }

    public function resolveReport(Request $request, Report $report)
    {
        $auth = $request->user() ?? abort(401);
        $this->adminAccess->ensureBackoffice($auth);

        $data = $request->validate([
            'status' => ['required', Rule::in(['reviewed', 'dismissed', 'actioned'])],
            'resolution_note' => ['nullable', 'string', 'max:255'],
        ]);

        $this->resolveReportItem($report, $auth, (string) $data['status'], $data['resolution_note'] ?? null);
        $this->eventService->track(
            'admin_report_resolved',
            (int) $auth->id,
            null,
            null,
            [
                'report_id' => (int) $report->id,
                'status' => (string) $data['status'],
            ],
            'admin_api'
        );

        return response()->json(['message' => 'Reporte actualizado.', 'report' => $report->fresh()]);
    }

    public function bulkResolveReports(Request $request)
    {
        $auth = $request->user() ?? abort(401);
        $this->adminAccess->ensureBackoffice($auth);

        $data = $request->validate([
            'ids' => ['required', 'array', 'min:1', 'max:500'],
            'ids.*' => ['required', 'integer', 'min:1'],
            'status' => ['required', Rule::in(['reviewed', 'dismissed', 'actioned'])],
            'resolution_note' => ['nullable', 'string', 'max:255'],
        ]);

        $ids = collect($data['ids'])->map(fn ($id) => (int) $id)->unique()->values()->all();
        $results = $this->emptyBulkResult();

        foreach ($ids as $reportId) {
            try {
                DB::transaction(function () use ($reportId, $data, $auth, &$results) {
                    $report = Report::query()->find((int) $reportId);
                    if (!$report) {
                        $this->bulkError($results, (int) $reportId, 'not_found');
                        return;
                    }
                    if ($report->status !== 'pending') {
                        $this->bulkSkip($results, (int) $reportId, 'already_resolved');
                        return;
                    }

                    $this->resolveReportItem($report, $auth, (string) $data['status'], $data['resolution_note'] ?? null);
                    $results['processed']++;
                });
            } catch (\Throwable $e) {
                $this->bulkError($results, (int) $reportId, 'exception');
            }
        }

        $this->eventService->track(
            'admin_bulk_reports_resolved',
            (int) $auth->id,
            null,
            null,
            [
                'processed' => (int) $results['processed'],
                'skipped_count' => (int) $results['skipped'],
                'errors_count' => (int) $results['errors'],
                'status' => (string) $data['status'],
            ],
            'admin_api'
        );

        return response()->json($results);
    }

    public function strikes(Request $request)
    {
        $auth = $request->user() ?? abort(401);
        $this->adminAccess->ensureBackoffice($auth);

        $status = (string) $request->query('status', '');
        $userId = (int) $request->query('user_id', 0);

        $query = Strike::query()->with('user:id,name,nick,email')->orderByDesc('id');
        if ($status !== '' && in_array($status, ['active', 'revoked'], true)) {
            $query->where('status', $status);
        }
        if ($userId > 0) {
            $query->where('user_id', $userId);
        }

        return response()->json(['items' => $query->limit(300)->get()]);
    }

    public function issueStrike(Request $request)
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
                'admin_action_blocked',
                (int) $auth->id,
                null,
                null,
                ['action' => 'issue_strike', 'target_user_id' => (int) $target->id, 'reason' => 'target_backoffice_user'],
                'admin_api'
            );
        }
        $this->adminAccess->ensureCanIssueStrike($auth, $target);

        $strike = $this->moderationService->issueStrike(
            $target,
            $auth,
            $data['reason_code'],
            $data['description'] ?? null,
            $data['report_id'] ?? null,
            $data['expires_days'] ?? null
        );

        if (!empty($data['report_id'])) {
            Report::where('id', (int) $data['report_id'])->update([
                'status' => 'actioned',
                'resolved_by_user_id' => $auth->id,
                'resolved_at' => now(),
                'resolution_note' => 'Strike aplicado.',
            ]);
        }

        $this->eventService->track(
            'admin_strike_issued',
            (int) $auth->id,
            null,
            null,
            [
                'strike_id' => (int) $strike->id,
                'target_user_id' => (int) $target->id,
                'report_id' => !empty($data['report_id']) ? (int) $data['report_id'] : null,
            ],
            'admin_api'
        );

        return response()->json([
            'message' => 'Strike aplicado.',
            'strike' => $strike->fresh(),
            'user_suspended_until' => optional($target->fresh()->suspended_until)->toISOString(),
        ], 201);
    }

    public function revokeStrike(Request $request, Strike $strike)
    {
        $auth = $request->user() ?? abort(401);
        $this->adminAccess->ensureBackoffice($auth);
        if ($this->adminAccess->isStaffCriticalBlock($auth, $strike)) {
            $this->eventService->track(
                'admin_action_blocked',
                (int) $auth->id,
                null,
                null,
                ['action' => 'revoke_strike', 'strike_id' => (int) $strike->id, 'reason' => 'critical_revoke_blocked_for_staff'],
                'admin_api'
            );
        }
        $this->adminAccess->ensureCanRevokeStrike($auth, $strike);

        $data = $request->validate([
            'revoked_note' => ['nullable', 'string', 'max:255'],
        ]);

        $this->moderationService->revokeStrike($strike, $auth, $data['revoked_note'] ?? null);
        $this->eventService->track(
            'admin_strike_revoked',
            (int) $auth->id,
            null,
            null,
            ['strike_id' => (int) $strike->id],
            'admin_api'
        );

        return response()->json(['message' => 'Strike revocado.']);
    }

    public function bulkRevokeStrikes(Request $request)
    {
        $auth = $request->user() ?? abort(401);
        $this->adminAccess->ensureBackoffice($auth);

        $data = $request->validate([
            'ids' => ['required', 'array', 'min:1', 'max:500'],
            'ids.*' => ['required', 'integer', 'min:1'],
            'revoked_note' => ['nullable', 'string', 'max:255'],
        ]);

        $ids = collect($data['ids'])->map(fn ($id) => (int) $id)->unique()->values()->all();
        $results = $this->emptyBulkResult();

        foreach ($ids as $strikeId) {
            try {
                DB::transaction(function () use ($strikeId, $data, $auth, &$results) {
                    $strike = Strike::query()->with('user')->find((int) $strikeId);
                    if (!$strike) {
                        $this->bulkError($results, (int) $strikeId, 'not_found');
                        return;
                    }
                    if ($strike->status === 'revoked') {
                        $this->bulkSkip($results, (int) $strikeId, 'already_revoked');
                        return;
                    }
                    if ($this->adminAccess->isStaffCriticalBlock($auth, $strike)) {
                        $this->bulkSkip($results, (int) $strikeId, 'critical_revoke_blocked_for_staff');
                        $this->eventService->track(
                            'admin_action_blocked',
                            (int) $auth->id,
                            null,
                            null,
                            ['action' => 'bulk_revoke_strike', 'strike_id' => (int) $strikeId, 'reason' => 'critical_revoke_blocked_for_staff'],
                            'admin_api'
                        );
                        return;
                    }

                    $this->moderationService->revokeStrike($strike, $auth, $data['revoked_note'] ?? null);
                    $results['processed']++;
                });
            } catch (\Throwable $e) {
                $this->bulkError($results, (int) $strikeId, 'exception');
            }
        }

        $this->eventService->track(
            'admin_bulk_strikes_revoked',
            (int) $auth->id,
            null,
            null,
            [
                'processed' => (int) $results['processed'],
                'skipped_count' => (int) $results['skipped'],
                'errors_count' => (int) $results['errors'],
            ],
            'admin_api'
        );

        return response()->json($results);
    }

    public function setUserSuspension(Request $request, User $user)
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
            'admin_user_suspension_updated',
            (int) $auth->id,
            null,
            null,
            [
                'target_user_id' => (int) $user->id,
                'suspended_until' => $data['suspended_until'] ?? null,
                'reason' => $data['suspension_reason'] ?? null,
            ],
            'admin_api'
        );

        return response()->json([
            'message' => 'Suspensión de usuario actualizada.',
            'user' => $user->fresh(),
        ]);
    }

    public function fieldSubmissions(Request $request)
    {
        $auth = $request->user() ?? abort(401);
        $this->adminAccess->ensureBackoffice($auth);

        $status = (string) $request->query('status', '');
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
        if ($status !== '' && in_array($status, ['pending', 'approved', 'rejected'], true)) {
            $query->where('status', $status);
        }

        return response()->json(['items' => $query->limit(300)->get()]);
    }

    public function decideFieldSubmission(Request $request, FieldSubmission $submission)
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

        $result = $this->decideFieldSubmissionItem(
            $submission,
            $auth,
            (string) $data['action'],
            $data['resolution_note'] ?? null
        );

        $this->eventService->track(
            'admin_field_submission_decided',
            (int) $auth->id,
            null,
            null,
            [
                'submission_id' => (int) $submission->id,
                'action' => (string) $data['action'],
            ],
            'admin_api'
        );

        return response()->json($result);
    }

    public function bulkDecisionFieldSubmissions(Request $request)
    {
        $auth = $request->user() ?? abort(401);
        $this->adminAccess->ensureBackoffice($auth);

        $data = $request->validate([
            'ids' => ['required', 'array', 'min:1', 'max:500'],
            'ids.*' => ['required', 'integer', 'min:1'],
            'action' => ['required', Rule::in(['approve', 'reject'])],
            'resolution_note' => ['nullable', 'string', 'max:255'],
        ]);

        $ids = collect($data['ids'])->map(fn ($id) => (int) $id)->unique()->values()->all();
        $results = $this->emptyBulkResult();

        foreach ($ids as $submissionId) {
            try {
                DB::transaction(function () use ($submissionId, $data, $auth, &$results) {
                    $submission = FieldSubmission::query()
                        ->with('photos')
                        ->find((int) $submissionId);
                    if (!$submission) {
                        $this->bulkError($results, (int) $submissionId, 'not_found');
                        return;
                    }
                    if ($submission->status !== 'pending') {
                        $this->bulkSkip($results, (int) $submissionId, 'already_resolved');
                        return;
                    }

                    $this->decideFieldSubmissionItem(
                        $submission,
                        $auth,
                        (string) $data['action'],
                        $data['resolution_note'] ?? null
                    );

                    $results['processed']++;
                });
            } catch (\Throwable $e) {
                $this->bulkError($results, (int) $submissionId, 'exception');
            }
        }

        $this->eventService->track(
            'admin_bulk_field_submissions_decided',
            (int) $auth->id,
            null,
            null,
            [
                'processed' => (int) $results['processed'],
                'skipped_count' => (int) $results['skipped'],
                'errors_count' => (int) $results['errors'],
                'action' => (string) $data['action'],
            ],
            'admin_api'
        );

        return response()->json($results);
    }

    public function removeFieldSubmissionPhoto(Request $request, FieldSubmission $submission, FieldSubmissionPhoto $photo)
    {
        $auth = $request->user() ?? abort(401);
        $this->adminAccess->ensureBackoffice($auth);

        abort_unless((int) $photo->field_submission_id === (int) $submission->id, 404);

        $data = $request->validate([
            'reason' => ['nullable', 'string', 'max:255'],
        ]);

        $photo->update([
            'status' => 'removed',
            'removed_by_user_id' => $auth->id,
            'removed_reason' => $data['reason'] ?? null,
        ]);

        $this->eventService->track(
            'admin_field_submission_photo_removed',
            (int) $auth->id,
            null,
            null,
            [
                'submission_id' => (int) $submission->id,
                'photo_id' => (int) $photo->id,
            ],
            'admin_api'
        );

        return response()->json(['message' => 'Foto removida.']);
    }

    private function resolveReportItem(Report $report, User $auth, string $status, ?string $resolutionNote): void
    {
        $report->update([
            'status' => $status,
            'resolved_by_user_id' => $auth->id,
            'resolved_at' => now(),
            'resolution_note' => $resolutionNote,
        ]);
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
     * @return array{processed:int,skipped:int,errors:int,skipped_items:array<int,array{id:int,reason:string}>,error_items:array<int,array{id:int,reason:string}>}
     */
    private function emptyBulkResult(): array
    {
        return [
            'processed' => 0,
            'skipped' => 0,
            'errors' => 0,
            'skipped_items' => [],
            'error_items' => [],
        ];
    }

    /**
     * @param array{processed:int,skipped:int,errors:int,skipped_items:array<int,array{id:int,reason:string}>,error_items:array<int,array{id:int,reason:string}>} $results
     */
    private function bulkSkip(array &$results, int $id, string $reason): void
    {
        $results['skipped']++;
        $results['skipped_items'][] = ['id' => $id, 'reason' => $reason];
    }

    /**
     * @param array{processed:int,skipped:int,errors:int,skipped_items:array<int,array{id:int,reason:string}>,error_items:array<int,array{id:int,reason:string}>} $results
     */
    private function bulkError(array &$results, int $id, string $reason): void
    {
        $results['errors']++;
        $results['error_items'][] = ['id' => $id, 'reason' => $reason];
    }
}
