@extends('layouts.app')

@section('content')
<div class="container">
  <h3 class="mb-3">Moderación · Solicitudes de Canchas</h3>
  @include('admin.partials.nav')

  @if(session('ok'))
    <div class="alert alert-success">{{ session('ok') }}</div>
  @endif
  @if($errors->any())
    <div class="alert alert-danger">{{ $errors->first() }}</div>
  @endif

  <form method="GET" class="card mb-3">
    <div class="card-body row g-2 align-items-end">
      <div class="col-md-3">
        <label class="form-label">Estado</label>
        <select name="status" class="form-select">
          <option value="">Todos</option>
          @foreach(['pending','approved','rejected'] as $status)
            <option value="{{ $status }}" @selected(($filters['status'] ?? '') === $status)>{{ $status }}</option>
          @endforeach
        </select>
      </div>
      <div class="col-md-7">
        <label class="form-label">Buscar</label>
        <input type="text" name="q" value="{{ $filters['q'] ?? '' }}" class="form-control" placeholder="nombre, dirección, usuario">
      </div>
      <div class="col-md-2 d-grid">
        <button class="btn btn-primary">Filtrar</button>
      </div>
    </div>
  </form>

  <form id="bulk-field-submissions-form" method="POST" action="{{ route('admin.field-submissions.bulk-decision') }}" class="card mb-0">
    @csrf
    <div class="card-header d-flex flex-wrap gap-2 align-items-end">
      <div>
        <label class="form-label mb-0">Acción masiva</label>
        <select name="action" class="form-select form-select-sm">
          <option value="approve">approve</option>
          <option value="reject">reject</option>
        </select>
      </div>
      <div class="flex-grow-1">
        <label class="form-label mb-0">Nota</label>
        <input type="text" name="resolution_note" class="form-control form-control-sm" maxlength="255">
      </div>
      <div>
        <button class="btn btn-sm btn-outline-primary">Aplicar a seleccionadas</button>
      </div>
    </div>
  </form>
  <div class="card border-top-0">
    <div class="table-responsive">
      <table class="table table-sm align-middle mb-0">
        <thead>
          <tr>
            <th style="width:36px;"><input type="checkbox" onclick="document.querySelectorAll('.submission-check').forEach(c=>c.checked=this.checked)"></th>
            <th>ID</th>
            <th>Estado</th>
            <th>Aporte</th>
            <th>Solicita</th>
            <th>Ubicación</th>
            <th>Fotos</th>
            <th style="width:300px;">Acción</th>
          </tr>
        </thead>
        <tbody>
          @forelse($items as $item)
            <tr>
              <td><input type="checkbox" class="submission-check" form="bulk-field-submissions-form" name="ids[]" value="{{ $item->id }}"></td>
              <td>#{{ $item->id }}</td>
              <td><span class="badge text-bg-secondary">{{ $item->status }}</span></td>
              <td>
                @if($item->submission_type === 'existing_polideportivo')
                  <span class="badge text-bg-info">Nueva cancha en polideportivo existente</span>
                  <div class="fw-semibold mt-1">{{ $item->existingPolideportivo?->nombre ?? $item->nombre }}</div>
                  <small class="text-muted d-block">
                    Destino #{{ $item->existing_polideportivo_id }}
                    @if($item->existingPolideportivo)
                      · {{ $item->existingPolideportivo->canchas_count }} canchas registradas
                    @endif
                  </small>
                @else
                  <span class="badge text-bg-primary">Polideportivo nuevo</span>
                  <div class="fw-semibold mt-1">{{ $item->nombre }}</div>
                @endif
                @if($item->cancha_nombre)
                  <div class="mt-2 border-start border-3 border-success ps-2">
                    <div class="fw-semibold">Cancha: {{ $item->cancha_nombre }}</div>
                    <small class="text-muted">
                      {{ $item->cancha_equiposvs ? $item->cancha_equiposvs . 'v' . $item->cancha_equiposvs : 'Formato sin indicar' }}
                      @if($item->cancha_tipo_superficie) · {{ $item->cancha_tipo_superficie }} @endif
                      @if($item->cancha_anchom2 && $item->cancha_largom2) · {{ $item->cancha_anchom2 }} × {{ $item->cancha_largom2 }} m @endif
                    </small>
                  </div>
                @endif
              </td>
              <td>{{ $item->user->nick ?? $item->user->email ?? 'N/A' }}</td>
              <td>
                <div>{{ $item->direccion ?: ($item->existingPolideportivo?->direccion ?? 'N/A') }}</div>
                @if($item->celular)
                  <small class="text-muted d-block">Celular: {{ $item->celular }}{{ $item->wsp ? ' · WhatsApp' : '' }}</small>
                @endif
                @if($item->precio_desde)
                  <small class="text-muted d-block">Precio desde: S/ {{ $item->precio_desde }}</small>
                @endif
              </td>
              <td>
                @php
                  $venuePhotos = $item->photos->where('asset_type', 'venue');
                  $courtPhotos = $item->photos->where('asset_type', 'court');
                @endphp
                @if($venuePhotos->isNotEmpty())
                  <div><small class="text-muted">Polideportivo ({{ $venuePhotos->count() }}):</small> <a href="{{ $venuePhotos->first()->photo_url }}" target="_blank" rel="noopener">ver</a></div>
                @endif
                @if($courtPhotos->isNotEmpty())
                  <div><small class="text-muted">Cancha ({{ $courtPhotos->count() }}):</small> <a href="{{ $courtPhotos->first()->photo_url }}" target="_blank" rel="noopener">ver</a></div>
                @endif
                @if($item->photos->isEmpty()) <small class="text-muted">Sin fotos</small> @endif
              </td>
              <td>
                <form method="POST" action="{{ route('admin.field-submissions.decide', $item) }}" class="d-flex gap-1">
                  @csrf
                  @if($item->status === 'pending')
                    <select name="existing_polideportivo_id" class="form-select form-select-sm" style="max-width:220px" title="Corregir destino antes de aprobar">
                      <option value="">Mantener como polideportivo nuevo</option>
                      @foreach($correctionPolideportivos as $polideportivo)
                        <option value="{{ $polideportivo->id }}" @selected($item->existing_polideportivo_id === $polideportivo->id)>
                          #{{ $polideportivo->id }} · {{ $polideportivo->nombre }}
                        </option>
                      @endforeach
                    </select>
                  @endif
                  <select name="action" class="form-select form-select-sm" style="max-width:120px">
                    <option value="approve">approve</option>
                    <option value="reject">reject</option>
                  </select>
                  <input type="text" name="resolution_note" class="form-control form-control-sm" placeholder="Nota" maxlength="255">
                  <button class="btn btn-sm btn-outline-success">Guardar</button>
                </form>
              </td>
            </tr>
          @empty
            <tr><td colspan="8" class="text-center py-4 text-muted">Sin solicitudes.</td></tr>
          @endforelse
        </tbody>
      </table>
    </div>
    <div class="card-body py-2">{{ $items->links() }}</div>
  </div>
</div>
@endsection
