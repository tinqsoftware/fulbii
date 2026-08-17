<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\FieldSubmission;
use App\Models\FieldSubmissionPhoto;
use App\Models\User;
use App\Services\FieldSubmissionApprovalService;
use App\Services\ProductEventService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\Storage;
use Illuminate\Validation\Rule;

class FieldSubmissionController extends Controller
{
    public function __construct(
        private readonly ProductEventService $eventService,
        private readonly FieldSubmissionApprovalService $approvalService,
    )
    {
    }

    public function indexMine(Request $request)
    {
        $user = $request->user() ?? abort(401);

        $items = FieldSubmission::query()
            ->where('user_id', $user->id)
            ->with('photos')
            ->orderByDesc('id')
            ->limit(100)
            ->get();

        return response()->json([
            'items' => $items,
            'summary' => $this->submissionSummary($user),
        ]);
    }

    public function store(Request $request)
    {
        $user = $request->user() ?? abort(401);

        $data = $request->validate([
            'nombre' => ['required', 'string', 'max:250'],
            'submission_type' => ['nullable', Rule::in(['new_polideportivo', 'existing_polideportivo'])],
            'direccion' => ['nullable', 'string', 'max:255'],
            'x' => ['nullable', 'string', 'max:50'],
            'y' => ['nullable', 'string', 'max:50'],
            'celular' => ['nullable', 'string', 'max:20'],
            'wsp' => ['nullable', 'boolean'],
            'id_distrito' => ['nullable', 'integer', 'min:1'],
            'descripcion' => ['nullable', 'string', 'max:300'],
            'precio_desde' => ['nullable', 'string', 'max:10'],
            'source_type' => ['nullable', Rule::in(['gps', 'manual_map'])],
            'existing_polideportivo_id' => [
                'nullable',
                'required_if:submission_type,existing_polideportivo',
                'integer',
                'min:1',
            ],
            'cancha_nombre' => ['nullable', 'string', 'max:250'],
            'cancha_equiposvs' => ['nullable', Rule::in(['5', '6', '7', '8', '9', '11'])],
            'cancha_tipo_superficie' => ['nullable', Rule::in(['losa', 'sintetico', 'natural'])],
            'cancha_anchom2' => ['nullable', 'numeric', 'min:1', 'max:200'],
            'cancha_largom2' => ['nullable', 'numeric', 'min:1', 'max:300'],
            'create_default_cancha' => ['nullable', 'boolean'],
            'canchas' => ['nullable', 'array', 'max:12'],
            'canchas.*.nombre' => ['required_with:canchas', 'string', 'max:250'],
            'canchas.*.anchom2' => ['nullable', 'numeric', 'min:1', 'max:200'],
            'canchas.*.largom2' => ['nullable', 'numeric', 'min:1', 'max:300'],
            // `photos` and `photo_files` are the legacy court-photo contract.
            'photos' => ['nullable', 'array', 'max:3'],
            'photos.*' => ['string', 'max:500'],
            'photo_files' => ['nullable', 'array', 'max:3'],
            'photo_files.*' => ['file', 'image', 'mimes:jpg,jpeg,png,webp', 'max:2048'],
            'venue_photo_files' => ['nullable', 'array', 'max:5'],
            'venue_photo_files.*' => ['file', 'image', 'mimes:jpg,jpeg,png,webp', 'max:2048'],
            'court_photo_files' => ['nullable', 'array', 'max:3'],
            'court_photo_files.*' => ['file', 'image', 'mimes:jpg,jpeg,png,webp', 'max:2048'],
        ]);

        // A selected centre is authoritative. This also protects submissions
        // from older mobile builds that sent the ID but omitted the new type.
        $data['submission_type'] = !empty($data['existing_polideportivo_id'])
            ? 'existing_polideportivo'
            : ($data['submission_type'] ?? 'new_polideportivo');

        if ($data['submission_type'] === 'existing_polideportivo') {
            abort_unless(!empty($data['existing_polideportivo_id']) && \App\Models\Polideportivo::query()->whereKey($data['existing_polideportivo_id'])->exists(), 422, 'El polideportivo seleccionado ya no existe.');
        }

        $isSuperadmin = $this->isSuperadmin($user);
        $submission = DB::transaction(function () use ($data, $user, $request, $isSuperadmin) {
            // Locking the parent user row serializes submissions for that
            // user, including the otherwise-racy "no pending rows" case.
            if (Schema::hasTable('users')) {
                User::query()->lockForUpdate()->findOrFail($user->id);
            }
            if (!$isSuperadmin) {
                $summary = $this->submissionSummary($user, true);
                abort_if($summary['pending_submission'] !== null, 422, 'Ya tienes una solicitud pendiente. Espera su aprobación o rechazo antes de enviar otra.');
                abort_if(!$summary['can_submit'], 422, 'Ya alcanzaste el máximo de 3 solicitudes de cancha este mes.');
            }

            $submission = FieldSubmission::create([
                'user_id' => $user->id,
                'status' => 'pending',
                'submission_type' => $data['submission_type'],
                'nombre' => trim((string) $data['nombre']),
                'direccion' => $data['direccion'] ?? null,
                'x' => $data['x'] ?? null,
                'y' => $data['y'] ?? null,
                'celular' => $data['celular'] ?? null,
                'wsp' => (bool) ($data['wsp'] ?? false),
                'id_distrito' => $data['id_distrito'] ?? null,
                'descripcion' => $data['descripcion'] ?? null,
                'precio_desde' => $data['precio_desde'] ?? null,
                'source_type' => $data['source_type'] ?? 'gps',
                'existing_polideportivo_id' => $data['existing_polideportivo_id'] ?? null,
                'cancha_nombre' => $data['cancha_nombre'] ?? null,
                'cancha_equiposvs' => $data['cancha_equiposvs'] ?? null,
                'cancha_tipo_superficie' => $data['cancha_tipo_superficie'] ?? null,
                'cancha_anchom2' => $data['cancha_anchom2'] ?? null,
                'cancha_largom2' => $data['cancha_largom2'] ?? null,
                'metadata_json' => [
                    'existing_polideportivo_id' => $data['existing_polideportivo_id'] ?? null,
                    'create_default_cancha' => (bool) ($data['create_default_cancha'] ?? true),
                    'canchas' => $data['canchas'] ?? [],
                ],
            ]);

            foreach (($data['photos'] ?? []) as $index => $photoUrl) {
                FieldSubmissionPhoto::create([
                    'field_submission_id' => $submission->id,
                    'photo_url' => $photoUrl,
                    'asset_type' => 'court',
                    'sort_order' => $index,
                    'status' => 'active',
                ]);
            }
            $this->storePhotos($submission, $request->file('photo_files', []), 'court', $user->id);
            $this->storePhotos($submission, $request->file('venue_photo_files', []), 'venue', $user->id);
            $this->storePhotos($submission, $request->file('court_photo_files', []), 'court', $user->id);

            return $submission;
        });

        // A superadmin contributes through the same audited pipeline as every
        // other user, but their verified content is published immediately.
        if ($isSuperadmin) {
            $this->approvalService->decide($submission, $user, 'approve', 'Publicación directa de superadmin.');
            $submission->refresh();
        }

        $this->eventService->track(
            'field_submission_created',
            (int) $user->id,
            null,
            null,
            [
                'submission_id' => (int) $submission->id,
                'photos_count' => (int) $submission->photos()->count(),
            ]
        );

        if (app()->environment('local')) {
            Log::debug('Field submission created.', [
                'submission_id' => (int) $submission->id,
                'submission_type' => $submission->submission_type,
                'existing_polideportivo_id' => $submission->existing_polideportivo_id,
            ]);
        }

        return response()->json([
            'message' => $isSuperadmin
                ? 'Cancha publicada y aprobada automáticamente.'
                : 'Solicitud de cancha enviada.',
            'submission' => $submission->load('photos'),
            'summary' => $this->submissionSummary($user),
        ], 201);
    }

    /** @return array{monthly_used:int,monthly_limit:?int,pending_submission:?array<string,mixed>,can_submit:bool,is_unlimited:bool} */
    private function submissionSummary(User $user, bool $lock = false): array
    {
        $isSuperadmin = $this->isSuperadmin($user);
        $userId = (int) $user->id;
        $start = now()->startOfMonth();
        $end = now()->endOfMonth();
        $base = FieldSubmission::query()->where('user_id', $userId);
        if ($lock) {
            $base->lockForUpdate();
        }
        $monthlyUsed = (clone $base)->whereBetween('created_at', [$start, $end])->count();
        $pending = (clone $base)->where('status', 'pending')->latest('id')->first();

        return [
            'monthly_used' => $monthlyUsed,
            'monthly_limit' => $isSuperadmin ? null : 3,
            'pending_submission' => $pending ? [
                'id' => (int) $pending->id,
                'nombre' => (string) $pending->nombre,
                'submission_type' => (string) $pending->submission_type,
                'created_at' => optional($pending->created_at)->toISOString(),
                'status' => (string) $pending->status,
            ] : null,
            'can_submit' => $isSuperadmin || ($pending === null && $monthlyUsed < 3),
            'is_unlimited' => $isSuperadmin,
        ];
    }

    private function isSuperadmin(User $user): bool
    {
        return Schema::hasTable('perfil')
            && Schema::hasTable('user_perfil')
            && $user->canPerformCriticalAdminActions();
    }

    /** @param array<int,\Illuminate\Http\UploadedFile> $photos */
    private function storePhotos(FieldSubmission $submission, array $photos, string $assetType, int $userId): void
    {
        $lastOrder = $submission->photos()
            ->where('asset_type', $assetType)
            ->max('sort_order');
        $offset = $lastOrder === null ? 0 : ((int) $lastOrder + 1);

        foreach ($photos as $index => $photo) {
            $path = $photo->store('field-submissions/' . $userId, 'public');
            FieldSubmissionPhoto::create([
                'field_submission_id' => $submission->id,
                'photo_url' => Storage::disk('public')->url($path),
                'asset_type' => $assetType,
                'sort_order' => $offset + $index,
                'status' => 'active',
            ]);
        }
    }
}
