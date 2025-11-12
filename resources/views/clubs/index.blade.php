@extends('fulbii')
@section('title','Clubs · Fulbii')

@section('content')
<div class="container" style="max-width:1200px; padding:16px 16px 90px;">
  <div class="d-flex align-items-center justify-content-between mb-3">
    <h1 class="fw-700" style="font-size:22px; margin:0;">Clubs</h1>

    {{-- Tabs simples --}}
    <div class="btn-group" role="group" aria-label="tabs">
      @php $tab = $tab ?? request('tab','all'); @endphp

        @auth
          <a href="{{ route('clubs.index',['tab'=>'mine']) }}"
            class="btn {{ $tab==='mine' ? 'btn-success text-white' : 'btn-outline-success' }}">Mis clubs</a>

          <a href="{{ route('clubs.index',['tab'=>'search','q'=>request('q')]) }}"
            class="btn {{ $tab==='search' ? 'btn-success text-white' : 'btn-outline-success' }}">Todos</a>
        @endauth
    </div>
  </div>

  {{-- Buscador (solo visible en la pestaña Buscar) --}}
  @if(($tab ?? '') === 'search')
    <form method="GET" action="{{ route('clubs.index') }}" class="mb-3 d-flex" role="search">
      <input type="hidden" name="tab" value="search">
      <input type="text" name="q" value="{{ $q ?? '' }}" class="form-control me-2" placeholder="Buscar por nombre…">
      <button class="btn btn-success">Buscar</button>
    </form>
  @endif

  {{-- Grid de cards --}}
  @if($clubs->isEmpty())
    <div class="text-center text-muted py-5">
      @if(($tab ?? '') === 'mine')
        Aún no perteneces a ningún club.
      @elseif(($tab ?? '') === 'search')
        No hay resultados para <b>{{ $q }}</b>.
      @else
        No hay clubs creados.
      @endif
    </div>
  @else
    <div class="row row-cols-1 row-cols-md-2 row-cols-lg-3 g-3">
      @foreach($clubs as $c)
        <div class="col">
          <div class="card shadow-sm h-100 overflow-hidden">
            <div class="club-card-cover">
              @if($c->logo_url)
                <img src="{{ asset('storage/'.$c->logo_url) }}" alt="Logo {{ $c->nombre }}">
              @else
                <div class="club-card-cover--placeholder">{{ strtoupper(substr($c->nombre,0,1)) }}</div>
              @endif
            </div>
            <div class="card-body">
              <div class="d-flex justify-content-between align-items-start">
                <div class="d-flex align-items-center gap-2">
                  <div class="fw-700" style="font-size:18px">{{ $c->nombre }}</div>
                </div>
                {{-- badge de rol del usuario en este club --}}
                @if($c->miRol)
                  <span class="badge bg-success-subtle text-success fw-600">{{ strtoupper($c->miRol) }}</span>
                @endif
              </div>

              <div class="mt-2 text-muted" style="font-size:12px">
                <i class="ti-user"></i> {{ $c->miembros_count ?? 0 }} pichangueros
              </div>

              <div class="d-flex gap-2 mt-3">
                <a href="{{ route('clubs.show',$c) }}" class="btn btn-outline-secondary btn-sm">
                  Entrar
                </a>

                {{-- CTA según permisos --}}
                @auth
                  @php $yo = auth()->user(); @endphp

                  {{-- Superadmin puede editar/eliminar --}}
                  @if(!empty($yo->is_superadmin) && $yo->is_superadmin)
                    <a href="{{ route('clubs.edit',$c) }}" class="btn btn-outline-primary btn-sm">Editar</a>
                    <form action="{{ route('clubs.destroy',$c) }}" method="POST" onsubmit="return confirm('¿Eliminar club?')" class="d-inline">
                      @csrf @method('DELETE')
                      <button class="btn btn-outline-danger btn-sm">Eliminar</button>
                    </form>

                  {{-- //adun falta desarrollar más esta parte de la plataforma ==> Admin del club: gestionar miembros --}}
                  @elseif($c->miRol === 'admiin')
                    <a href="{{ route('clubs.miembros',$c) }}" class="btn btn-outline-primary btn-sm">Gestionar</a>

                  {{-- No miembro: unirse rápido --}}
                  @elseif(!$c->miRol)
                    <form action="{{ route('clubs.miembros.agregar', $c) }}" method="POST">
                        @csrf
                        <input type="hidden" name="user_id" value="{{ auth()->id() }}">
                        <button class="btn btn-success btn-sm">Unirme</button>
                    </form>

                  {{-- Miembro: opción salir --}}
                  @elseif($c->miRol === 'miembro')
                    <form action="{{ route('clubs.miembros.remover',[$c,auth()->id()]) }}" method="POST"
                          onsubmit="return confirm('¿Salir del club?')">
                      @csrf @method('DELETE')
                      <button class="btn btn-outline-danger btn-sm">Salir</button>
                    </form>
                  @endif
                @endauth
              </div>
            </div>
          </div>
        </div>
      @endforeach
    </div>
  @endif
</div>

{{-- FAB para crear club (solo superadmin) --}}
@auth
  @if(auth()->user()->is_superadmin ?? false)
    <a href="{{ route('clubs.create') }}" class="fab" aria-label="Crear club">
      <i class="ti-plus ico"></i> Crear club
    </a>
  @endif
@endauth

<style>
  .club-card-cover{ height:160px; background:#f3f4f6; display:flex; align-items:center; justify-content:center; }
  .club-card-cover img{ width:100%; height:100%; object-fit:cover; }
  .club-card-cover--placeholder{ width:100%; height:100%; display:grid; place-items:center; font-weight:800; font-size:48px; color:#1a7a43; background:#e9f8ee; border-bottom:1px solid #e5e7eb; }
  @media(min-width:992px){ .club-card-cover{ height:180px; } }
</style>
@endsection