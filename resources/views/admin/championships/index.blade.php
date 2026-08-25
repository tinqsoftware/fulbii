@extends('layouts.app')

@section('content')
<div class="container">
  <div class="admin-page-title"><div><p class="admin-eyebrow">Competición</p><h1>Campeonatos</h1><p class="admin-page-subtitle">Crea, publica y administra ligas desde un solo lugar.</p></div>@if(Auth::user()?->canPerformCriticalAdminActions())<a href="{{ route('admin.championships.create') }}" class="btn btn-primary">Crear campeonato</a>@endif</div>
  @include('admin.partials.nav')
  @if(session('ok')) <div class="alert alert-success">{{ session('ok') }}</div> @endif
  <div class="admin-table-wrap"><div class="table-responsive"><table class="table align-middle mb-0">
    <thead><tr><th>Nombre</th><th>Estado</th><th>Visibilidad</th><th>Equipos</th><th></th></tr></thead>
    <tbody>
      @forelse($items as $item)
        <tr>
          <td><strong>{{ $item->name }}</strong><br><small class="text-muted">{{ $item->creator?->nick ?: $item->creator?->name }}</small></td>
          <td><span class="badge admin-status {{ in_array($item->status, ['published','completed'], true) ? 'admin-status--success' : ($item->status === 'registration' ? 'admin-status--warning' : 'admin-status--muted') }}">{{ ['draft'=>'Borrador','registration'=>'Inscripciones','published'=>'Publicado','completed'=>'Finalizado'][$item->status] ?? ucfirst($item->status) }}</span></td><td>{{ $item->visibility === 'public' ? 'Público' : ($item->visibility === 'private' ? 'Privado' : 'Solo con enlace') }}</td><td><strong>{{ $item->teams_count }}</strong></td>
          <td><a class="btn btn-sm btn-outline-primary" href="{{ route('admin.championships.show', $item) }}">Gestionar</a></td>
        </tr>
      @empty
        <tr><td colspan="5"><div class="admin-empty"><div class="admin-empty-icon">🏆</div><strong>Aún no hay campeonatos</strong><div>Cuando crees uno aparecerá aquí para gestionarlo.</div></div></td></tr>
      @endforelse
    </tbody>
  </table></div></div>
  <div class="mt-3">{{ $items->links() }}</div>
</div>
@endsection
