<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\GroupPichanga;
use App\Models\GroupPichangaParticipant;
use App\Models\GroupPichangaRating;
use App\Models\Cancha;
use App\Models\Polideportivo;
use App\Models\UserFavoriteField;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

class MeActivityController extends Controller
{
    public function pichangaHistory(Request $request)
    {
        $user = $request->user() ?? abort(401);
        $limit = max(1, min(200, (int) $request->query('limit', 50)));

        $pichangaIds = GroupPichangaParticipant::query()
            ->where('user_id', $user->id)
            ->where('status', 'confirmed')
            ->orderByDesc('id')
            ->limit($limit)
            ->pluck('pichanga_id');

        $items = GroupPichanga::query()
            ->whereIn('id', $pichangaIds)
            ->orderByDesc('starts_at')
            ->get([
                'id',
                'club_id',
                'title',
                'field_id', 'cancha_id',
                'address',
                'starts_at',
                'duration_minutes',
                'status',
            ]);

        $courtIds = $items->pluck('cancha_id')->filter()->map(fn ($id) => (int) $id)->unique();
        $courts = $courtIds->isEmpty() || !Schema::hasTable('cancha') ? collect() : Cancha::query()
            ->with('polideportivo:id,nombre')->whereIn('id', $courtIds)->get()->keyBy('id');
        $fieldIds = $items->pluck('field_id')->filter()->map(fn ($id) => (int) $id)->unique();
        $fields = $fieldIds->isEmpty() || !Schema::hasTable('polideportivo') ? collect() : Polideportivo::query()
            ->whereIn('id', $fieldIds)->pluck('nombre', 'id');
        $stats = !Schema::hasTable('group_pichanga_ratings') || $items->isEmpty()
            ? collect()
            : GroupPichangaRating::query()->whereIn('pichanga_id', $items->pluck('id'))
                ->where('rated_user_id', $user->id)
                ->selectRaw('pichanga_id, COUNT(*) as votes')
                ->groupBy('pichanga_id')->pluck('votes', 'pichanga_id');
        $watchStats = !Schema::hasTable('watch_match_sessions') || !Schema::hasTable('watch_match_events') || $items->isEmpty()
            ? collect()
            : DB::table('watch_match_sessions as sessions')
                ->join('watch_match_events as events', 'events.session_id', '=', 'sessions.id')
                ->where('sessions.user_id', $user->id)
                ->whereIn('sessions.group_pichanga_id', $items->pluck('id'))
                ->whereIn('events.event_type', ['goal', 'assist'])
                ->selectRaw("sessions.group_pichanga_id, SUM(CASE WHEN events.event_type = 'goal' THEN 1 ELSE 0 END) as goals, SUM(CASE WHEN events.event_type = 'assist' THEN 1 ELSE 0 END) as assists")
                ->groupBy('sessions.group_pichanga_id')->get()->keyBy('group_pichanga_id');

        return response()->json(['items' => $items->map(function (GroupPichanga $pichanga) use ($courts, $fields, $stats, $watchStats, $user) {
            $court = $courts->get((int) $pichanga->cancha_id);
            $end = $pichanga->starts_at?->copy()->addMinutes(max(1, (int) $pichanga->duration_minutes));
            $participant = GroupPichangaParticipant::query()->where('pichanga_id', $pichanga->id)
                ->where('user_id', $user->id)->first();
            return [
                'id' => (int) $pichanga->id,
                'club_id' => (int) $pichanga->club_id,
                'title' => $pichanga->title,
                'starts_at' => optional($pichanga->starts_at)->toISOString(),
                'end_at' => optional($end)->toISOString(),
                'status' => $pichanga->status,
                'status_label' => in_array((string) $pichanga->status, ['completed', 'cancelled'], true) || ($end && now()->gt($end)) ? 'Finalizada' : 'Próxima',
                'court_name' => $court?->nombre,
                'field_name' => $court?->polideportivo?->nombre ?? $fields->get((int) $pichanga->field_id),
                'address' => $pichanga->address,
                'my_team_code' => $participant?->team_code,
                'my_ratings_received' => (int) ($stats[(int) $pichanga->id] ?? 0),
                'my_goals' => (int) ($watchStats->get((int) $pichanga->id)->goals ?? 0),
                'my_assists' => (int) ($watchStats->get((int) $pichanga->id)->assists ?? 0),
            ];
        })->values()]);
    }

    public function favoriteFields(Request $request)
    {
        $user = $request->user() ?? abort(401);

        $items = UserFavoriteField::query()
            ->where('user_id', $user->id)
            ->with('field:id,nombre,x,y,descripcion,precio_desde,url_foto')
            ->orderByDesc('id')
            ->get()
            ->map(fn(UserFavoriteField $f) => [
                'id' => $f->id,
                'polideportivo_id' => $f->polideportivo_id,
                'field' => $f->field,
                'created_at' => optional($f->created_at)->toISOString(),
            ]);

        return response()->json(['items' => $items]);
    }

    public function addFavoriteField(Request $request, int $polideportivo)
    {
        $user = $request->user() ?? abort(401);
        abort_unless(Polideportivo::where('id', $polideportivo)->exists(), 404, 'Cancha no encontrada.');

        $favorite = UserFavoriteField::firstOrCreate([
            'user_id' => $user->id,
            'polideportivo_id' => $polideportivo,
        ]);

        return response()->json([
            'message' => 'Cancha agregada a favoritos.',
            'favorite' => $favorite,
        ], 201);
    }

    public function removeFavoriteField(Request $request, int $polideportivo)
    {
        $user = $request->user() ?? abort(401);

        UserFavoriteField::query()
            ->where('user_id', $user->id)
            ->where('polideportivo_id', $polideportivo)
            ->delete();

        return response()->json(['message' => 'Cancha removida de favoritos.']);
    }
}
