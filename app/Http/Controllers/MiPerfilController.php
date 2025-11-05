<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\{Calificacion, VwClubJugadorPromediosTodo};

class MiPerfilController extends Controller
{
    private function me(){ return auth()->user() ?? abort(401); }

    public function show()
    {
        $u = $this->me();

        // Promedios por club (vista "todo")
        $promedios = VwClubJugadorPromediosTodo::where('user_id', $u->id)->get();

        // Calificaciones separadas: públicas (no ocultas) y ocultas (solo visibles para el calificado)
        $recibidasPublicas = Calificacion::where('user_calificado_id', $u->id)
            ->whereNull('ocultada_por_calificado_at')
            ->latest()
            ->get();

        $ocultas = Calificacion::where('user_calificado_id', $u->id)
            ->whereNotNull('ocultada_por_calificado_at')
            ->latest()
            ->get();

        // Clubs a los que pertenece
        $clubs = $u->clubs()->select('clubs.id','clubs.nombre','clubs.descripcion')->get();

        // Mi autocalificación (si existe)
        $miAuto = Calificacion::where('user_calificado_id', $u->id)
            ->where('user_calificador_id', $u->id)
            ->latest()
            ->first();

        // Promedio global ponderado por votos_total si está disponible
        $sumVotes = 0;
        $acc = ['fisico' => 0, 'arquero' => 0, 'delantero' => 0, 'mediocampo' => 0, 'defensa' => 0];

        foreach ($promedios as $p) {
            $v = (int)($p->votos_total ?? 0);
            if ($v <= 0) { continue; }
            $sumVotes += $v;

            foreach ($acc as $k => $_) {
                $field = $k . '_prom_todo';
                if (isset($p->$field) && $p->$field !== null) {
                    $acc[$k] += (float)$p->$field * $v;
                }
            }
        }

        $global = ['votos' => $sumVotes];
        foreach ($acc as $k => $s) {
            $global[$k] = $sumVotes > 0 ? $s / $sumVotes : null;
        }

        // Promedio total simple entre las métricas presentes
        $vals = array_filter([
            $global['fisico'] ?? null,
            $global['arquero'] ?? null,
            $global['delantero'] ?? null,
            $global['mediocampo'] ?? null,
            $global['defensa'] ?? null,
        ], fn($vv) => $vv !== null);

        $global['promedio'] = count($vals) ? array_sum($vals) / count($vals) : null;

        return view('perfil.show', compact('u','promedios','recibidasPublicas','ocultas','clubs','global','miAuto'));
    }

    public function update(Request $r)
    {
        $u = $this->me();
        $data = $r->validate([
            'name'  => 'required|string|max:255',
            'email' => 'required|email',
        ]);
        $u->update($data);
        return back()->with('ok','Datos actualizados');
    }

    // oculta una calificación para el público del perfil del calificado
    public function ocultar(Calificacion $calificacion)
    {
        $u = $this->me();
        abort_unless($calificacion->user_calificado_id === $u->id, 403);
        $calificacion->update(['ocultada_por_calificado_at' => now()]);
        return back()->with('ok','Calificación ocultada en tu perfil');
    }
    public function autocalificacionUpsert(Request $r)
    {
        $u = $this->me();
        $validated = $r->validate([
            'id'         => 'nullable|integer',
            'fisico'     => 'required|integer|min:1|max:5',
            'arquero'    => 'required|integer|min:1|max:5',
            'delantero'  => 'required|integer|min:1|max:5',
            'mediocampo' => 'required|integer|min:1|max:5',
            'defensa'    => 'required|integer|min:1|max:5',
            'comentario' => 'nullable|string|max:500',
        ]);

        // Si viene un ID válido y pertenece al usuario, actualizar esa; si no, usar (o crear) la fila global (club_id null)
        $cal = null;
        if (!empty($validated['id'])) {
            $cal = Calificacion::where('id', $validated['id'])
                ->where('user_calificador_id', $u->id)
                ->where('user_calificado_id', $u->id)
                ->first();
        }
        if (!$cal) {

            $cal = Calificacion::firstOrNew([
                'user_calificador_id' => $u->id,
                'user_calificado_id'  => $u->id,
                'club_id'             => $u->clubs->first()->id,
            ]);
        }

        $cal->fisico     = $validated['fisico'];
        $cal->arquero    = $validated['arquero'];
        $cal->delantero  = $validated['delantero'];
        $cal->mediocampo = $validated['mediocampo'];
        $cal->defensa    = $validated['defensa'];
        $cal->comentario = $validated['comentario'] ?? null;
        $wasNew = !$cal->exists;
        $cal->save();

        return back()->with('ok', $wasNew ? 'Autocalificación registrada' : 'Autocalificación actualizada');
    }
}