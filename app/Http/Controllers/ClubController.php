<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\{Club, ClubUser, User, Calificacion, VwClubJugadorPromediosPublicos};
use Illuminate\Support\Facades\Storage;

class ClubController extends Controller
{
    // Helpers rápidos (sin middleware/policies)
    private function me() {
        return auth()->user(); // puede ser null
    }
    private function needAuth() {
        return auth()->user() ?? abort(401);
    }
    private function isSuper(): bool {
        return (bool) optional(auth()->user())->is_superadmin;
    }
    private function isClubAdmin(Club $club): bool {
        $u = auth()->user();
        if (!$u) return false;
        return ClubUser::where('club_id', $club->id)
            ->where('user_id', $u->id)
            ->where('rol', 'admin')
            ->exists();
    }
    private function isMember(Club $club): bool {
        $u = auth()->user();
        if (!$u) return false;
        return ClubUser::where('club_id', $club->id)
            ->where('user_id', $u->id)
            ->exists();
    }
    private function miRol(?Club $club = null): ?string {
        $u = auth()->user();
        if (!$u || !$club) return null;
        if ($this->isSuper()) return 'superadmin';
        if ($this->isClubAdmin($club)) return 'admin';
        if ($this->isMember($club)) return 'miembro';
        return null;
    }

    public function index()
    {
        $u   = auth()->user(); // puede ser null
        // Invitado: default 'all'. Logueado: 'mine' (o 'all' si es super)
        $tab = request('tab', $u ? ($this->isSuper() ? 'all' : 'mine') : 'search');
        if (!$u && $tab === 'mine') $tab = 'all'; // forzar a 'all' si es invitado
        $q   = trim(request('q', ''));

        $base = Club::query()
            ->when($tab === 'mine' && $u, function($q2) use ($u) {
                $q2->whereIn('id', ClubUser::where('user_id', $u->id)->pluck('club_id'));
            })
            ->when($tab === 'search' && $q !== '', function($q2) use ($q) {
                $q2->where(function($w) use ($q) {
                    $w->where('nombre', 'like', "%{$q}%")
                    ->orWhere('slug', 'like', "%{$q}%");
                });
            })
            // 👇 evitamos ambigüedad calificando la columna del pivote
            ->withCount(['miembros' => function($qq) {
                $qq->where('club_user.estado', 1);
            }])
            ->orderBy('nombre');

        $clubs = $base->get();

        // Solo si hay usuario, anotamos rol
        if ($u) {
            $roles = ClubUser::where('user_id', $u->id)->pluck('rol', 'club_id');
            $clubs->transform(function($c) use ($roles) {
                $c->miRol = (auth()->user() && auth()->user()->is_superadmin)
                    ? 'superadmin'
                    : ($roles[$c->id] ?? null);
                return $c;
            });
        }

        return view('clubs.index', compact('clubs','tab','q'));
    }



    public function create()
    {
        abort_unless($this->isSuper(), 403);
        return view('clubs.create');
    }

    public function store(Request $r)
    {
        abort_unless($this->isSuper(), 403);
        $data = $r->validate([
            'nombre' => 'required|string|max:150',
            'slug'   => 'required|string|max:160|unique:clubs,slug',
            'descripcion' => 'nullable|string',
            'logo' => 'nullable|image|max:2048',
        ]);
        $path = null;
        if ($r->hasFile('logo')) {
            $path = $r->file('logo')->store('clubs', 'public'); // e.g., storage/app/public/clubs/xxx.jpg
        }
        $data['created_by'] = $this->me()->id;
        if ($path) {
            $data['logo_url'] = $path;
        }
        $club = Club::create($data);

        // el creador se vuelve admin del club:
        ClubUser::firstOrCreate(['club_id'=>$club->id,'user_id'=>$this->me()->id], ['rol'=>'admin','estado'=>1]);

        return redirect()->route('clubs.show', $club)->with('ok','Club creado');
    }

    public function show(Club $club)
    {
        $isSuper  = $this->isSuper();
        $isAdmin  = $this->isClubAdmin($club);
        $isMember = $this->isMember($club);
        $miRol    = $this->miRol($club);

        $promedios = VwClubJugadorPromediosPublicos::where('club_id',$club->id)->get();
        $miembros  = ClubUser::with('user')->where('club_id',$club->id)->orderByDesc('rol')->get();

        return view('clubs.show', compact('club','promedios','miembros','isSuper','isAdmin','isMember','miRol'));
    }

    public function edit(Club $club)
    {
        abort_unless($this->isSuper() || $this->isClubAdmin($club), 403);
        return view('clubs.edit', compact('club'));
    }

    public function update(Request $r, Club $club)
    {
        abort_unless($this->isSuper() || $this->isClubAdmin($club), 403);
        $data = $r->validate([
            'nombre' => 'required|string|max:150',
            'descripcion' => 'nullable|string',
            'logo' => 'nullable|image|max:2048',
        ]);
        if ($r->hasFile('logo')) {
            $newPath = $r->file('logo')->store('clubs', 'public');
            if (!empty($club->logo_url)) {
                Storage::disk('public')->delete($club->logo_url);
            }
            $data['logo_url'] = $newPath;
        }
        $club->update($data);
        return back()->with('ok','Club actualizado');
    }

    public function destroy(Club $club)
    {
        abort_unless($this->isSuper(), 403);
        $club->delete();
        return redirect()->route('clubs.index')->with('ok','Club eliminado');
    }

    // ---- miembros ----
    public function miembros(Club $club)
    {
        abort_unless($this->isSuper() || $this->isClubAdmin($club), 403);
        $miembros = ClubUser::with('user')->where('club_id',$club->id)->get();
        return view('clubs.miembros', compact('club','miembros'));
    }

    public function agregarMiembro(Request $r, Club $club)
    {
        abort_unless($this->isSuper() || $this->isClubAdmin($club), 403);
        $data = $r->validate([
            'user_id' => 'required|exists:users,id',
            'rol'     => 'nullable|in:admin,miembro'
        ]);
        ClubUser::updateOrCreate(
            ['club_id'=>$club->id,'user_id'=>$data['user_id']],
            ['rol'=>$data['rol'] ?? 'miembro','estado'=>1]
        );
        return back()->with('ok','Miembro agregado');
    }

    public function removerMiembro(Club $club, User $user)
    {
        abort_unless($this->isSuper() || $this->isClubAdmin($club), 403);
        ClubUser::where('club_id',$club->id)->where('user_id',$user->id)->delete();
        return back()->with('ok','Miembro removido');
    }

    public function setAdmin(Club $club, User $user)
    {
        abort_unless($this->isSuper() || $this->isClubAdmin($club), 403);
        ClubUser::where('club_id',$club->id)->where('user_id',$user->id)->update(['rol'=>'admin']);
        return back()->with('ok','Ahora es admin del club');
    }
}