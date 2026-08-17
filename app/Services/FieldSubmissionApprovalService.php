<?php

namespace App\Services;

use App\Models\Cancha;
use App\Models\CanchaPhoto;
use App\Models\FieldSubmission;
use App\Models\Polideportivo;
use App\Models\PolideportivoPhoto;
use App\Models\User;
use App\Services\PushNotificationService;
use Illuminate\Support\Facades\DB;

class FieldSubmissionApprovalService
{
    public function __construct(private readonly PushNotificationService $pushNotifications)
    {
    }

    /** @return array{message:string,approved_polideportivo_id?:int,approved_cancha_id?:int} */
    public function decide(FieldSubmission $submission, User $auth, string $action, ?string $note): array
    {
        abort_if($submission->status !== 'pending', 422, 'La solicitud ya fue resuelta.');
        if ($action === 'reject') {
            $submission->update(['status' => 'rejected', 'reviewed_by_user_id' => $auth->id, 'reviewed_at' => now(), 'resolution_note' => $note]);
            $result = ['message' => 'Solicitud rechazada.'];
            $this->notifyDecision($submission->fresh(), false);
            return $result;
        }

        $result = DB::transaction(function () use ($submission, $auth, $note) {
            $venuePhotos = $submission->photos()
                ->where('status', 'active')->where('asset_type', 'venue')
                ->orderBy('sort_order')->pluck('photo_url')->all();
            // Existing, pre-gallery submissions have no asset type. They are
            // court photos by default, preserving the former behaviour.
            $courtPhotos = $submission->photos()
                ->where('status', 'active')->where('asset_type', 'court')
                ->orderBy('sort_order')->pluck('photo_url')->all();
            if ($submission->submission_type === 'existing_polideportivo') {
                $field = Polideportivo::query()
                    ->lockForUpdate()
                    ->find($submission->existing_polideportivo_id);
                abort_if(!$field, 422, 'El polideportivo seleccionado ya no existe. Rechaza la solicitud o pide una nueva ubicación.');
            } else {
                $field = Polideportivo::create([
                    'nombre' => $submission->nombre,
                    'direccion' => $submission->direccion,
                    'x' => $submission->x, 'y' => $submission->y,
                    'celular' => $submission->celular, 'wsp' => $submission->wsp ? '1' : '0',
                    'id_distrito' => $submission->id_distrito, 'descripcion' => $submission->descripcion,
                    // The submitter is the owner/contributor of the data;
                    // the reviewer is still recorded separately on the audit.
                    'id_user_create' => $submission->user_id, 'precio_desde' => $submission->precio_desde,
                    'precio_desde_num' => is_numeric($submission->precio_desde) ? $submission->precio_desde : null,
                    'url_foto' => $venuePhotos[0] ?? null,
                ]);
                $this->attachVenuePhotos($field, $venuePhotos);
            }
            // Legacy submissions did not contain a court. Keep their approval path intact.
            if (empty($submission->cancha_nombre) || empty($submission->cancha_equiposvs) || empty($submission->cancha_tipo_superficie)) {
                $submission->update([
                    'status' => 'approved', 'reviewed_by_user_id' => $auth->id, 'reviewed_at' => now(),
                    'approved_polideportivo_id' => $field->id, 'resolution_note' => $note,
                ]);

                return ['message' => 'Solicitud aprobada.', 'approved_polideportivo_id' => (int) $field->id];
            }

            $capacity = (string) $submission->cancha_equiposvs;
            $cancha = Cancha::create([
                'id_polideportivo' => $field->id, 'nombre' => $submission->cancha_nombre,
                'equiposvs' => $capacity, 'tipo_superficie' => $submission->cancha_tipo_superficie,
                'formato_vs' => in_array($capacity, ['6', '7', '9'], true) ? $capacity . 'v' . $capacity : null,
                'anchom2' => $submission->cancha_anchom2, 'largom2' => $submission->cancha_largom2,
                'url_foto' => $courtPhotos[0] ?? null,
            ]);
            $this->attachCourtPhotos($cancha, $courtPhotos);
            $submission->update([
                'status' => 'approved', 'reviewed_by_user_id' => $auth->id, 'reviewed_at' => now(),
                'approved_polideportivo_id' => $field->id, 'approved_cancha_id' => $cancha->id,
                'resolution_note' => $note,
            ]);
            return ['message' => 'Solicitud aprobada.', 'approved_polideportivo_id' => (int) $field->id, 'approved_cancha_id' => (int) $cancha->id];
        });
        $this->notifyDecision($submission->fresh(), true);
        return $result;
    }

    private function notifyDecision(FieldSubmission $submission, bool $approved): void
    {
        $fieldId = (int) ($submission->approved_polideportivo_id ?? 0);
        $courtId = (int) ($submission->approved_cancha_id ?? 0);
        $name = trim((string) $submission->nombre) ?: 'tu cancha';
        $this->pushNotifications->createForUser((int) $submission->user_id, [
            'type' => $approved ? 'field_submission_approved' : 'field_submission_rejected',
            'title' => $approved ? 'Solicitud aprobada' : 'Solicitud rechazada',
            'body' => $approved
                ? "Tu aporte \"{$name}\" ya está disponible en Fulbii."
                : "Tu solicitud \"{$name}\" fue rechazada.",
            'data_json' => [
                'target_type' => $approved && $fieldId > 0 ? 'field' : 'field_submission',
                'target_id' => (string) ($approved && $fieldId > 0 ? $fieldId : $submission->id),
                'field_submission_id' => (string) $submission->id,
                'field_id' => (string) $fieldId,
                'cancha_id' => (string) $courtId,
            ],
        ]);
    }

    /** @param array<int,string> $photos */
    private function attachVenuePhotos(Polideportivo $field, array $photos): void
    {
        foreach ($photos as $index => $photoUrl) {
            PolideportivoPhoto::create([
                'polideportivo_id' => $field->id,
                'photo_url' => $photoUrl,
                'sort_order' => $index,
            ]);
        }
    }

    /** @param array<int,string> $photos */
    private function attachCourtPhotos(Cancha $cancha, array $photos): void
    {
        foreach ($photos as $index => $photoUrl) {
            CanchaPhoto::create([
                'cancha_id' => $cancha->id,
                'photo_url' => $photoUrl,
                'sort_order' => $index,
            ]);
        }
    }
}
