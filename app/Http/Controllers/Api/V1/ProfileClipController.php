<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Models\UserProfileClip;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\Storage;

class ProfileClipController extends Controller
{
    private const MAX_ACTIVE_CLIPS = 5;

    public function indexMine(Request $request)
    {
        $user = $request->user() ?? abort(401);
        $this->ensureTableExists();

        $items = UserProfileClip::query()
            ->where('user_id', $user->id)
            ->where('status', 'active')
            ->orderBy('sort_order')
            ->orderByDesc('id')
            ->get();

        return response()->json(['items' => $items]);
    }

    public function indexByUser(Request $request, User $user)
    {
        $this->ensureTableExists();

        $items = UserProfileClip::query()
            ->where('user_id', $user->id)
            ->where('status', 'active')
            ->orderBy('sort_order')
            ->orderByDesc('id')
            ->get([
                'id',
                'user_id',
                'title',
                'mp4_url',
                'duration_ms',
                'width',
                'height',
                'has_audio',
                'file_size_bytes',
                'sort_order',
                'created_at',
            ]);

        return response()->json(['items' => $items]);
    }

    public function store(Request $request)
    {
        $user = $request->user() ?? abort(401);
        $this->ensureTableExists();

        $normalizedHasAudio = $this->normalizeBoolean($request->input('has_audio'));
        if ($normalizedHasAudio === null) {
            return response()->json([
                'message' => 'has_audio inválido; se esperaba true/false o 1/0.',
                'errors' => [
                    'has_audio' => ['has_audio inválido; se esperaba true/false o 1/0.'],
                ],
            ], 422);
        }
        $request->merge(['has_audio' => $normalizedHasAudio ? 1 : 0]);

        $activeCount = UserProfileClip::query()
            ->where('user_id', $user->id)
            ->where('status', 'active')
            ->count();
        abort_if($activeCount >= self::MAX_ACTIVE_CLIPS, 422, 'Máximo 5 clips activos por perfil.');

        $data = $request->validate([
            'title' => ['nullable', 'string', 'max:120'],
            'clip' => ['required', 'file', 'mimetypes:video/mp4', 'max:1331'],
            'source_duration_ms' => ['required', 'integer', 'min:7000', 'max:20000'],
            'duration_ms' => ['required', 'integer', 'in:7000'],
            'width' => ['nullable', 'integer', 'min:64', 'max:2048'],
            'height' => ['nullable', 'integer', 'min:64', 'max:2048'],
            'has_audio' => ['required', 'integer', 'in:0,1'],
        ], [
            'clip.max' => 'El clip final no puede superar 1.3MB.',
        ]);

        if (!empty($data['width']) && !empty($data['height'])) {
            abort_if((int) $data['height'] <= (int) $data['width'], 422, 'El clip final debe ser vertical.');
        }
        abort_if((int) $data['has_audio'] !== 1, 422, 'El clip debe mantener audio.');

        $file = $request->file('clip');
        $path = $file->store("profile_clips/{$user->id}", 'public');
        $url = Storage::disk('public')->url($path);

        $nextOrder = (int) UserProfileClip::query()
            ->where('user_id', $user->id)
            ->where('status', 'active')
            ->max('sort_order');
        $nextOrder++;

        $clip = UserProfileClip::create([
            'user_id' => $user->id,
            'title' => trim((string) ($data['title'] ?? '')),
            'mp4_url' => $url,
            'duration_ms' => (int) $data['duration_ms'],
            'width' => $data['width'] ?? null,
            'height' => $data['height'] ?? null,
            'has_audio' => (bool) $data['has_audio'],
            'file_size_bytes' => $file->getSize(),
            'sort_order' => max(1, $nextOrder),
            'status' => 'active',
        ]);

        return response()->json([
            'message' => 'Clip subido correctamente.',
            'item' => $clip,
        ], 201);
    }

    public function destroy(Request $request, UserProfileClip $clip)
    {
        $user = $request->user() ?? abort(401);
        $this->ensureTableExists();
        abort_unless((int) $clip->user_id === (int) $user->id, 403);

        if ($clip->status !== 'deleted') {
            $clip->status = 'deleted';
            $clip->save();
        }

        return response()->json(['message' => 'Clip eliminado.']);
    }

    public function reorder(Request $request)
    {
        $user = $request->user() ?? abort(401);
        $this->ensureTableExists();

        $data = $request->validate([
            'clip_ids' => ['required', 'array', 'min:1', 'max:' . self::MAX_ACTIVE_CLIPS],
            'clip_ids.*' => ['integer', 'distinct'],
        ]);

        $activeIds = UserProfileClip::query()
            ->where('user_id', $user->id)
            ->where('status', 'active')
            ->pluck('id')
            ->map(fn($id) => (int) $id)
            ->all();
        $activeMap = array_flip($activeIds);

        foreach ($data['clip_ids'] as $clipId) {
            abort_if(!isset($activeMap[(int) $clipId]), 422, 'Uno o más clips no pertenecen al usuario.');
        }

        $ordered = [];
        foreach ($data['clip_ids'] as $clipId) {
            $ordered[] = (int) $clipId;
        }
        foreach ($activeIds as $clipId) {
            if (!in_array($clipId, $ordered, true)) {
                $ordered[] = $clipId;
            }
        }

        foreach ($ordered as $index => $clipId) {
            UserProfileClip::query()
                ->where('id', $clipId)
                ->update(['sort_order' => $index + 1]);
        }

        return response()->json(['message' => 'Orden de clips actualizado.']);
    }

    private function ensureTableExists(): void
    {
        abort_unless(Schema::hasTable('user_profile_clips'), 503, 'Falta ejecutar SQL incremental: user_profile_clips.');
    }

    private function normalizeBoolean(mixed $value): ?bool
    {
        if (is_bool($value)) {
            return $value;
        }

        if (is_int($value)) {
            return match ($value) {
                1 => true,
                0 => false,
                default => null,
            };
        }

        if (is_string($value)) {
            $normalized = strtolower(trim($value));
            return match ($normalized) {
                '1', 'true' => true,
                '0', 'false' => false,
                default => null,
            };
        }

        return null;
    }
}
