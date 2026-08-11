<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\GroupPichanga;
use App\Models\GroupPichangaComment;
use App\Models\GroupPichangaPost;
use App\Models\ClubChallengeMessage;
use App\Models\ClubGroupMessage;
use App\Models\Polideportivo;
use App\Models\Report;
use App\Models\User;
use App\Services\ProductEventService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
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
            'content_type' => ['nullable', Rule::in(['pichanga_post', 'pichanga_comment', 'club_group_message', 'challenge_message'])],
            'content_id' => ['nullable', 'integer', 'min:1', 'required_with:content_type'],
        ]);

        $this->assertTargetExists($data['target_type'], (int) $data['target_id']);
        $this->assertContextExists($data, (int) $user->id);
        abort_if((string) $data['target_type'] === 'user' && (int) $data['target_id'] === (int) $user->id, 422, 'No puedes reportarte a ti mismo.');

        $recent = Report::query()
            ->where('reporter_user_id', $user->id)
            ->where('target_type', $data['target_type'])
            ->where('target_id', (int) $data['target_id'])
            ->where('status', 'pending')
            ->where('created_at', '>=', now()->subDay());
        if (!empty($data['content_type'])) {
            $recent->where('content_type', $data['content_type'])->where('content_id', (int) $data['content_id']);
        } else {
            $recent->whereNull('content_type');
        }
        abort_if($recent->exists(), 422, 'Ya enviaste un reporte pendiente para este contenido.');

        $payload = [
            'reporter_user_id' => $user->id,
            'target_type' => $data['target_type'],
            'target_id' => (int) $data['target_id'],
            'reason_code' => $data['reason_code'],
            'description' => $data['description'] ?? null,
            'status' => 'pending',
        ];
        $payload['content_type'] = $data['content_type'] ?? null;
        $payload['content_id'] = $data['content_id'] ?? null;
        $report = Report::create($payload);

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

    private function assertContextExists(array $data, int $reporterId): void
    {
        if (empty($data['content_type'])) {
            return;
        }

        $contentId = (int) $data['content_id'];
        $targetId = (int) $data['target_id'];
        $targetType = (string) $data['target_type'];
        $valid = match ((string) $data['content_type']) {
            'pichanga_post' => $targetType === 'group_pichanga'
                && GroupPichangaPost::query()->whereKey($contentId)->where('pichanga_id', $targetId)->exists(),
            'pichanga_comment' => $targetType === 'group_pichanga'
                && GroupPichangaComment::query()->whereKey($contentId)->where('pichanga_id', $targetId)->exists(),
            'club_group_message' => $targetType === 'user'
                && Schema::hasTable('club_group_messages')
                && ClubGroupMessage::query()->whereKey($contentId)->where('user_id', $targetId)->where('user_id', '!=', $reporterId)->exists(),
            'challenge_message' => $targetType === 'user'
                && Schema::hasTable('club_challenge_messages')
                && ClubChallengeMessage::query()->whereKey($contentId)->where('user_id', $targetId)->where('user_id', '!=', $reporterId)->exists(),
            default => false,
        };
        abort_unless($valid, 422, 'El contenido reportado no existe o no coincide con su contexto.');
    }
}
