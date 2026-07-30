<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\GroupPichanga;
use App\Models\GroupPichangaParticipant;
use App\Models\Polideportivo;
use App\Models\UserFavoriteField;
use Illuminate\Http\Request;

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
                'field_id',
                'address',
                'starts_at',
                'duration_minutes',
                'status',
            ]);

        return response()->json(['items' => $items]);
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
