@extends('layouts.app')

@section('content')
<div class="container">
  <h3 class="mb-3">Campeonatos</h3>
  @include('admin.partials.nav')
  @if(session('ok')) <div class="alert alert-success">{{ session('ok') }}</div> @endif
  <div class="d-flex justify-content-between align-items-center mb-3">
    <p class="text-muted mb-0">Liga por puntos · primera entrega</p>
    @if(Auth::user()?->canPerformCriticalAdminActions())
      <a href="{{ route('admin.championships.create') }}" class="btn btn-primary">Crear campeonato</a>
    @endif
  </div>
  <div class="card"><div class="table-responsive"><table class="table align-middle mb-0">
    <thead><tr><th>Nombre</th><th>Estado</th><th>Visibilidad</th><th>Equipos</th><th></th></tr></thead>
    <tbody>
      @forelse($items as $item)
        <tr>
          <td><strong>{{ $item->name }}</strong><br><small class="text-muted">{{ $item->creator?->nick ?: $item->creator?->name }}</small></td>
          <td>{{ $item->status }}</td><td>{{ $item->visibility }}</td><td>{{ $item->teams_count }}</td>
          <td><a class="btn btn-sm btn-outline-primary" href="{{ route('admin.championships.show', $item) }}">Gestionar</a></td>
        </tr>
      @empty
        <tr><td colspan="5" class="text-muted">Todavía no hay campeonatos.</td></tr>
      @endforelse
    </tbody>
  </table></div></div>
  <div class="mt-3">{{ $items->links() }}</div>
</div>
@endsection
