<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\{User, Perfil, ClubUser};

class UsuarioController extends Controller
{
    private function me(){ return auth()->user() ?? abort(401); }
    private function onlySuper(){ abort_unless($this->me()->is_superadmin, 403); }

    public function index()
    {
        $this->onlySuper();
        $users = User::orderBy('name')->get();
        return view('usuarios.index', compact('users'));
    }

    public function edit(User $usuario)
    {
        $this->onlySuper();
        $perfiles = Perfil::orderBy('nombre')->get();
        $perfilesUser = $usuario->perfiles()->pluck('perfil.id')->toArray();
        return view('usuarios.edit', compact('usuario','perfiles','perfilesUser'));
    }

    public function update(Request $r, User $usuario)
    {
        $this->onlySuper();

        $data = $r->validate([
            'name'  => 'required|string|max:255',
            'email' => 'required|email',
            'perfiles' => 'array'
        ]);
        $usuario->update($data);

        // sincronizar perfiles
        $usuario->perfiles()->sync($data['perfiles'] ?? []);
        return redirect()->route('usuarios.index')->with('ok','Usuario actualizado');
    }

    public function destroy(User $usuario)
    {
        $this->onlySuper();
        abort_if($usuario->id === $this->me()->id, 403);
        $usuario->delete();
        return back()->with('ok','Usuario eliminado');
    }

    public function search(Request $request)
    {
        abort_unless(auth()->check(), 401); // solo logueados (la UI solo la ven admin/super)

        $q = trim((string) $request->get('q', ''));
        if ($q === '') {
            return response()->json([]);
        }

        // Excluir usuarios que ya pertenecen al club (si se envía club_id)
        $excludeIds = [];
        if ($request->filled('club_id')) {
            $excludeIds = ClubUser::where('club_id', (int) $request->get('club_id'))
                ->pluck('user_id')
                ->all();
        }

        $users = User::query()
            ->select('id','nick','name','email')
            ->where(function ($w) use ($q) {
                $w->where('nick', 'like', "%{$q}%")
                ->orWhere('name', 'like', "%{$q}%")
                ->orWhere('email', 'like', "%{$q}%");
            })
            // excluye a los ya miembros del club actual
            ->when(!empty($excludeIds), function ($qq) use ($excludeIds) {
                $qq->whereNotIn('id', $excludeIds);
            })
            // prioriza coincidencias al inicio del nick
            ->orderByRaw("CASE WHEN nick LIKE ? THEN 0 ELSE 1 END", ["{$q}%"])
            ->orderBy('nick')
            ->limit(10)
            ->get();

        return response()->json(
            $users->map(function ($u) {
                return [
                    'id'    => $u->id,
                    'nick'  => $u->nick,
                    'name'  => $u->name,
                    'email' => $u->email,
                ];
            })
        );
    }
}