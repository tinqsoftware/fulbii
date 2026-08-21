<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\{Calificacion, VwClubJugadorPromediosTodo,VwClubJugadorPromediosPublicos};
use App\Services\CombinedSkillRatingService;

class MiPerfilController extends Controller
{
    private function me(){ return auth()->user() ?? abort(401); }

    public function show()
    {
        $u = $this->me();

        // Promedios por club (vista "todo")
        $promedios = VwClubJugadorPromediosTodo::where('user_id', $u->id)->get();
        $promedios_p = VwClubJugadorPromediosPublicos::where('user_id',$u->id)->first();

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

        // Fuente única para perfil, equipos y rankings: no se promedian los
        // cinco campos directamente. Físico potencia los dos perfiles.
        $global = app(CombinedSkillRatingService::class)->summaryForUser((int) $u->id);
        $global['promedio'] = $global['stars'];

        return view('perfil.show', compact('u','promedios','promedios_p','recibidasPublicas','ocultas','clubs','global','miAuto'));
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
        if ((bool) ($u->initial_self_rating_locked ?? false)) {
            return back()->withErrors(['rating' => 'La autocalificación inicial ya no se puede editar.']);
        }
        $validated = $r->validate([
            'id'         => 'nullable|integer',
            'fisico'     => 'required|numeric|min:0|max:5|decimal:0,1',
            'arquero'    => 'required|numeric|min:0|max:5|decimal:0,1',
            'delantero'  => 'required|numeric|min:0|max:5|decimal:0,1',
            'mediocampo' => 'required|numeric|min:0|max:5|decimal:0,1',
            'defensa'    => 'required|numeric|min:0|max:5|decimal:0,1',
            'comentario' => 'nullable|string|max:500',
        ]);

        // Si viene un ID válido y pertenece al usuario, actualizar esa; si no, usar (o crear) la fila global (club_id puede ser null)
        $cal = null;
        if (!empty($validated['id'])) {
            $cal = Calificacion::where('id', $validated['id'])
                ->where('user_calificador_id', $u->id)
                ->where('user_calificado_id', $u->id)
                ->first();
        }
        if (!$cal) {
            // Fila "global" de autocalificación: club puede ser NULL si el usuario no pertenece a ninguno
            $clubId = $u->clubs()->first()?->id; // <- devuelve null si no hay club
            $cal = Calificacion::firstOrNew([
                'user_calificador_id' => $u->id,
                'user_calificado_id'  => $u->id,
                'club_id'             => $clubId,
            ]);
        }

        $cal->fisico     = $validated['fisico'];
        $cal->arquero    = $validated['arquero'];
        $cal->delantero  = $validated['delantero'];
        $cal->mediocampo = $validated['mediocampo'];
        $cal->defensa    = $validated['defensa'];
        $cal->comentario = $validated['comentario'] ?? null;
        $cal->es_autocalificacion = true;
        $wasNew = !$cal->exists;
        $cal->save();
        if (\Illuminate\Schema\Schema::hasColumn('users', 'initial_self_rating_locked')) {
            $u->initial_self_rating_locked = true;
            $u->save();
        }

        return back()->with('ok', $wasNew ? 'Autocalificación registrada' : 'Autocalificación actualizada');
    }


    public function nickavailable(Request $request)
    {
        $raw  = (string) $request->query('nick', '');

        // Normaliza: recorta, quita '@' inicial y elimina espacios visibles/ocultos
        $nick = ltrim(trim($raw), '@');
        // Elimina espacios comunes y zero‑width: NBSP, ZWSP, ZWNJ, ZWJ, WJ, BOM
        $nick = preg_replace('/[\s\x{00A0}\x{200B}\x{200C}\x{200D}\x{2060}\x{FEFF}]+/u', '', $nick);


        $exists = \App\Models\User::where('nick', $nick)->exists();

        return response()->json([
            'valid'     => true,
            'available' => !$exists
        ]);
    }

}
