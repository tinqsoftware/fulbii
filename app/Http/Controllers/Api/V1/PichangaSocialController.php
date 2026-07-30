<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\ClubUser;
use App\Models\GroupPichanga;
use App\Models\GroupPichangaComment;
use App\Models\GroupPichangaParticipant;
use App\Models\GroupPichangaPost;
use App\Models\GroupPichangaRating;
use App\Models\User;
use App\Services\CombinedSkillRatingService;
use App\Services\GroupPichangaAudienceService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;

class PichangaSocialController extends Controller
{
    public function __construct(
        private readonly GroupPichangaAudienceService $audienceService,
        private readonly CombinedSkillRatingService $combinedSkillRatings
    )
    {
    }

    public function feed(Request $request, GroupPichanga $pichanga)
    {
        $auth = $request->user() ?? abort(401);
        abort_unless($this->canAccessPichanga($pichanga, $auth), 403);

        $posts = GroupPichangaPost::query()
            ->where('pichanga_id', $pichanga->id)
            ->where('status', 'active')
            ->with([
                'user:id,name,nick,avatar_url',
                'comments' => fn($q) => $q->where('status', 'active')->with('user:id,name,nick,avatar_url')->orderBy('id'),
            ])
            ->orderByDesc('id')
            ->limit(100)
            ->get();

        return response()->json(['items' => $posts]);
    }

    public function addPost(Request $request, GroupPichanga $pichanga)
    {
        $auth = $request->user() ?? abort(401);
        abort_unless($this->canPost($pichanga, $auth->id), 403, 'Solo asistentes confirmados pueden publicar en el feed.');

        $data = $request->validate([
            'post_type' => ['required', Rule::in(['text', 'photo'])],
            'content' => ['nullable', 'string', 'max:500'],
            'photo_url' => ['nullable', 'string', 'max:500'],
        ]);

        if ($data['post_type'] === 'text') {
            abort_if(empty($data['content']), 422, 'El contenido es requerido para post de texto.');
        }
        if ($data['post_type'] === 'photo') {
            abort_if(empty($data['photo_url']), 422, 'La foto es requerida para post de foto.');
        }

        $post = GroupPichangaPost::create([
            'pichanga_id' => $pichanga->id,
            'user_id' => $auth->id,
            'post_type' => $data['post_type'],
            'content' => $data['content'] ?? null,
            'photo_url' => $data['photo_url'] ?? null,
            'status' => 'active',
        ]);

        return response()->json(['message' => 'Post publicado.', 'post' => $post->load('user:id,name,nick,avatar_url')], 201);
    }

    public function removePost(Request $request, GroupPichanga $pichanga, GroupPichangaPost $post)
    {
        $auth = $request->user() ?? abort(401);
        abort_unless((int) $post->pichanga_id === (int) $pichanga->id, 404);

        $isAdmin = $this->isClubAdmin((int) $pichanga->club_id, (int) $auth->id) || (bool) $auth->is_superadmin;
        abort_unless($isAdmin || (int) $post->user_id === (int) $auth->id, 403);

        $data = $request->validate([
            'reason' => ['nullable', 'string', 'max:255'],
        ]);

        $post->update([
            'status' => 'removed',
            'removed_by_user_id' => $auth->id,
            'removed_reason' => $data['reason'] ?? null,
        ]);

        return response()->json(['message' => 'Post removido.']);
    }

    public function addComment(Request $request, GroupPichanga $pichanga, GroupPichangaPost $post)
    {
        $auth = $request->user() ?? abort(401);
        abort_unless((int) $post->pichanga_id === (int) $pichanga->id, 404);
        abort_unless($this->canPost($pichanga, $auth->id), 403, 'Solo asistentes confirmados pueden comentar.');

        $data = $request->validate([
            'content' => ['required', 'string', 'max:500'],
        ]);

        $comment = GroupPichangaComment::create([
            'post_id' => $post->id,
            'pichanga_id' => $pichanga->id,
            'user_id' => $auth->id,
            'content' => trim($data['content']),
            'status' => 'active',
        ]);

        return response()->json([
            'message' => 'Comentario agregado.',
            'comment' => $comment->load('user:id,name,nick,avatar_url'),
        ], 201);
    }

    public function removeComment(Request $request, GroupPichanga $pichanga, GroupPichangaPost $post, GroupPichangaComment $comment)
    {
        $auth = $request->user() ?? abort(401);
        abort_unless((int) $post->pichanga_id === (int) $pichanga->id, 404);
        abort_unless((int) $comment->post_id === (int) $post->id, 404);

        $isAdmin = $this->isClubAdmin((int) $pichanga->club_id, (int) $auth->id) || (bool) $auth->is_superadmin;
        abort_unless($isAdmin || (int) $comment->user_id === (int) $auth->id, 403);

        $data = $request->validate([
            'reason' => ['nullable', 'string', 'max:255'],
        ]);

        $comment->update([
            'status' => 'removed',
            'removed_by_user_id' => $auth->id,
            'removed_reason' => $data['reason'] ?? null,
        ]);

        return response()->json(['message' => 'Comentario removido.']);
    }

    public function addOrUpdateRating(Request $request, GroupPichanga $pichanga)
    {
        $auth = $request->user() ?? abort(401);
        abort_unless($this->isConfirmedParticipant((int) $pichanga->id, (int) $auth->id), 403, 'Solo asistentes confirmados pueden calificar.');
        abort_if(now()->lt($pichanga->starts_at), 422, 'Podrás calificar cuando inicie la pichanga.');

        $data = $request->validate([
            'rated_user_id' => ['required', 'integer', 'exists:users,id'],
            'fisico' => ['required', 'numeric', 'min:0', 'max:10', 'decimal:0,1'],
            'arquero' => ['required', 'numeric', 'min:0', 'max:10', 'decimal:0,1'],
            'delantero' => ['required', 'numeric', 'min:0', 'max:10', 'decimal:0,1'],
            'mediocampo' => ['required', 'numeric', 'min:0', 'max:10', 'decimal:0,1'],
            'defensa' => ['required', 'numeric', 'min:0', 'max:10', 'decimal:0,1'],
            'comentario' => ['nullable', 'string', 'max:500'],
        ]);

        $ratedUserId = (int) $data['rated_user_id'];
        abort_if($ratedUserId === (int) $auth->id, 422, 'No puedes calificarte a ti mismo en esta pichanga.');
        abort_unless($this->isConfirmedParticipant((int) $pichanga->id, $ratedUserId), 422, 'Solo puedes calificar asistentes confirmados.');

        $rating = GroupPichangaRating::updateOrCreate(
            [
                'pichanga_id' => $pichanga->id,
                'rater_user_id' => $auth->id,
                'rated_user_id' => $ratedUserId,
            ],
            [
                'fisico' => $data['fisico'],
                'arquero' => $data['arquero'],
                'delantero' => $data['delantero'],
                'mediocampo' => $data['mediocampo'],
                'defensa' => $data['defensa'],
                'comentario' => $data['comentario'] ?? null,
            ]
        );

        return response()->json([
            'message' => 'Calificación guardada.',
            'rating' => $rating,
        ]);
    }

    public function ratings(Request $request, GroupPichanga $pichanga)
    {
        $auth = $request->user() ?? abort(401);
        abort_unless($this->canAccessPichanga($pichanga, $auth), 403);

        $items = GroupPichangaRating::query()
            ->where('pichanga_id', $pichanga->id)
            ->with(['rater:id,name,nick', 'rated:id,name,nick'])
            ->orderByDesc('id')
            ->get();

        return response()->json(['items' => $items]);
    }

    public function userCard(Request $request, User $user)
    {
        $auth = $request->user() ?? abort(401);
        $withUserId = (int) $request->query('with_user_id', 0);

        $totalPlayed = GroupPichangaParticipant::query()
            ->where('user_id', $user->id)
            ->where('status', 'confirmed')
            ->count();

        $sharedWithUser = 0;
        if ($withUserId > 0) {
            $pichangaIdsA = GroupPichangaParticipant::query()
                ->where('user_id', $user->id)
                ->where('status', 'confirmed')
                ->pluck('pichanga_id');

            $sharedWithUser = GroupPichangaParticipant::query()
                ->where('user_id', $withUserId)
                ->where('status', 'confirmed')
                ->whereIn('pichanga_id', $pichangaIdsA)
                ->count();
        }

        $clubId = (int) $request->query('club_id', 0);
        $summary = $this->combinedSkillRatings->summaryForUser(
            (int) $user->id,
            $clubId > 0 ? $clubId : null
        );

        return response()->json([
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'nick' => $user->nick,
                'email' => $user->email,
                'sexo' => $user->sexo,
                'fec_nac' => $user->fec_nac,
                'avatar_url' => $user->avatar_url,
            ],
            'stats' => [
                'total_played_pichangas' => $totalPlayed,
                'shared_with_user' => $sharedWithUser,
                'ratings' => [
                    'votos' => $summary['votos'],
                    'fisico' => $summary['fisico'],
                    'arquero' => $summary['arquero'],
                    'delantero' => $summary['delantero'],
                    'mediocampo' => $summary['mediocampo'],
                    'defensa' => $summary['defensa'],
                ],
            ],
        ]);
    }

    private function canAccessPichanga(GroupPichanga $pichanga, User $user): bool
    {
        if ((bool) $user->is_superadmin) {
            return true;
        }
        if ($this->isMember((int) $pichanga->club_id, (int) $user->id)) {
            return true;
        }
        if ($pichanga->is_open || $pichanga->allow_external_requests) {
            return $this->audienceService->externalEligibility($pichanga, (int) $user->id)['eligible'];
        }
        return false;
    }

    private function canPost(GroupPichanga $pichanga, int $userId): bool
    {
        if (now()->lt($pichanga->starts_at)) {
            return false;
        }
        return $this->isConfirmedParticipant((int) $pichanga->id, $userId);
    }

    private function isConfirmedParticipant(int $pichangaId, int $userId): bool
    {
        return GroupPichangaParticipant::where('pichanga_id', $pichangaId)
            ->where('user_id', $userId)
            ->where('status', 'confirmed')
            ->exists();
    }

    private function isMember(int $clubId, int $userId): bool
    {
        return ClubUser::where('club_id', $clubId)->where('user_id', $userId)->exists();
    }

    private function isClubAdmin(int $clubId, int $userId): bool
    {
        return ClubUser::where('club_id', $clubId)->where('user_id', $userId)->where('rol', 'admin')->exists();
    }
}
