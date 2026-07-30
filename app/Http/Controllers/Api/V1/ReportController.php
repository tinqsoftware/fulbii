<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\GroupPichanga;
use App\Models\Polideportivo;
use App\Models\Report;
use App\Models\User;
use App\Services\ProductEventService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;

class ReportController extends Controller
{
    public function __construct(private readonly ProductEventService $eventService)
    {
    }

    public function indexMine(Request $request)
    {
        $user = $request->user() ?? abort(401);
        $items = Report::query()
            ->where('reporter_user_id', $user->id)
            ->orderByDesc('id')
            ->limit(200)
            ->get();

        return response()->json(['items' => $items]);
    }

    public function store(Request $request)
    {
        $user = $request->user() ?? abort(401);

        $data = $request->validate([
            'target_type' => ['required', Rule::in(['user', 'field', 'field_photo', 'group_pichanga'])],
            'target_id' => ['required', 'integer', 'min:1'],
            'reason_code' => ['required', 'string', 'max:60'],
            'description' => ['nullable', 'string', 'max:500'],
        ]);

        $this->assertTargetExists($data['target_type'], (int) $data['target_id']);

        $report = Report::create([
            'reporter_user_id' => $user->id,
            'target_type' => $data['target_type'],
            'target_id' => (int) $data['target_id'],
            'reason_code' => $data['reason_code'],
            'description' => $data['description'] ?? null,
            'status' => 'pending',
        ]);

        $this->eventService->track(
            'report_created',
            (int) $user->id,
            null,
            null,
            [
                'report_id' => (int) $report->id,
                'target_type' => (string) $report->target_type,
                'target_id' => (int) $report->target_id,
            ]
        );

        return response()->json([
            'message' => 'Reporte enviado.',
            'report' => $report,
        ], 201);
    }

    private function assertTargetExists(string $targetType, int $targetId): void
    {
        $exists = match ($targetType) {
            'user' => User::where('id', $targetId)->exists(),
            'field' => Polideportivo::where('id', $targetId)->exists(),
            'field_photo' => DB::table('field_submission_photos')->where('id', $targetId)->exists(),
            'group_pichanga' => GroupPichanga::where('id', $targetId)->exists(),
            default => false,
        };

        abort_unless($exists, 422, 'El objetivo reportado no existe.');
    }
}
