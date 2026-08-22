<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\{Club, ClubUser, Calificacion, User};
use Illuminate\Support\Facades\DB;
use Carbon\Carbon;

class CalificacionController extends Controller
{
    private function me() { return auth()->user() ?? abort(401); }
    private function esMiembro(Club $club, $userId)
    {
        return ClubUser::where('club_id',$club->id)->where('user_id',$userId)->exists();
    }

    public function store(Request $r, Club $club)
    {
        $u = $this->me();

        abort_unless($this->esMiembro($club, $u->id), 403);

        $data = $r->validate([
            'user_calificado_id' => 'required|exists:users,id',
            'fisico'     => 'required|numeric|min:0|max:5|decimal:0,1',
            'arquero'    => 'required|numeric|min:0|max:5|decimal:0,1',
            'delantero'  => 'required|numeric|min:0|max:5|decimal:0,1',
            'mediocampo' => 'required|numeric|min:0|max:5|decimal:0,1',
            'defensa'    => 'required|numeric|min:0|max:5|decimal:0,1',
            'comentario' => 'nullable|string|max:500',
        ]);

        // el calificado también debe ser miembro del club
        abort_unless($this->esMiembro($club, $data['user_calificado_id']), 403);

        // regla: una calificación libre por semana ISO por par (calificador -> calificado) en este club
        [$weekStart, $weekEnd] = $this->currentIsoWeekBounds();
        $yaExiste = Calificacion::where('club_id', $club->id)
            ->where('user_calificador_id', $u->id)
            ->where('user_calificado_id', $data['user_calificado_id'])
            ->whereBetween('created_at', [$weekStart, $weekEnd])
            ->exists();
        if ($yaExiste) {
            return response('Ya calificaste esta semana a este pichanguero.', 422);
        }

        // Regla adicional: la autocalificación se identifica por la igualdad de
        // los IDs y solo puede registrarse una vez por usuario.
        $esSelf = ($u->id == $data['user_calificado_id']);
        if ($esSelf) {
            $selfExists = Calificacion::where('user_calificador_id', $u->id)
                ->whereColumn('user_calificador_id', 'user_calificado_id')
                ->exists();
            if ($selfExists) {
                return response('Ya registraste tu autocalificación.', 422);
            }
        }

        Calificacion::create([
            'club_id'             => $club->id,
            'user_calificador_id' => $u->id,
            'user_calificado_id'  => $data['user_calificado_id'],
            'fisico'     => $data['fisico'],
            'arquero'    => $data['arquero'],
            'delantero'  => $data['delantero'],
            'mediocampo' => $data['mediocampo'],
            'defensa'    => $data['defensa'],
            'comentario' => $data['comentario'] ?? null,
        ]);

        return back()->with('ok','Calificación registrada');
    }

    public function destroy(Calificacion $calificacion)
    {
        $u = $this->me();
        abort_unless($u->is_superadmin || $u->id === $calificacion->user_calificador_id, 403);
        $calificacion->delete();
        return back()->with('ok','Calificación eliminada');
    }

    public function silenciar(Calificacion $calificacion)
    {
        $u = $this->me();
        abort_unless($u->is_superadmin, 403);
        $calificacion->update(['silenciada_por_admin_at' => now()]);
        return back()->with('ok','Calificación silenciada');
    }

    public function history(Club $club, User $user)
    {
        // Últimas 20 calificaciones públicas de este jugador en el club
        $items = Calificacion::publicas()
            ->delClub($club->id)
            ->where('user_calificado_id', $user->id)
            ->with(['calificador:id,name,nick'])
            ->latest('created_at')
            ->take(20)
            ->get([
                'id','club_id','user_calificador_id','user_calificado_id',
                'fisico','arquero','delantero','mediocampo','defensa','comentario','created_at'
            ]);

        return response()->json($items);
    }

    public function canRate(Club $club, User $user)
    {
        $u = auth()->user();
        if (!$u) {
            return response()->json(['allow' => false, 'reason' => 'auth']); // invitado
        }

        // Ambos deben pertenecer al club
        $miCalif = \App\Models\ClubUser::where('club_id',$club->id)->where('user_id',$u->id)->exists();
        $miCali2 = \App\Models\ClubUser::where('club_id',$club->id)->where('user_id',$user->id)->exists();
        if (!$miCalif || !$miCali2) {
            return response()->json(['allow' => false, 'reason' => 'no-member']);
        }

        // Autocalificación: permitir solo si aún no existe una previa (lifetime en el club)
        if ($u->id === $user->id) {
            $selfExists = Calificacion::where('club_id', $club->id)
                ->where('user_calificador_id', $u->id)
                ->whereColumn('user_calificador_id', 'user_calificado_id')
                ->exists();
            if ($selfExists) {
                return response()->json(['allow' => false, 'reason' => 'self-exists']);
            }
            return response()->json(['allow' => true]);
        }

        // Otros: solo 1 por semana ISO
        [$weekStart, $weekEnd] = $this->currentIsoWeekBounds();
        $yaHoy = Calificacion::where('club_id', $club->id)
            ->where('user_calificador_id', $u->id)
            ->where('user_calificado_id', $user->id)
            ->whereBetween('created_at', [$weekStart, $weekEnd])
            ->exists();

        if ($yaHoy) {
            return response()->json(['allow' => false, 'reason' => 'already-this-week']);
        }
        return response()->json(['allow' => true]);
    }

    /**
     * @return array{0:\Carbon\Carbon,1:\Carbon\Carbon}
     */
    private function currentIsoWeekBounds(): array
    {
        $now = Carbon::now();
        $start = $now->copy()->startOfWeek(Carbon::MONDAY)->startOfDay();
        $end = $now->copy()->endOfWeek(Carbon::SUNDAY)->endOfDay();

        return [$start, $end];
    }

}
