@extends('layouts.app')

@section('content')
<div class="container">
  <h3 class="mb-3">Moderación · Reportes</h3>
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
          @foreach(['pending','reviewed','dismissed','actioned'] as $status)
            <option value="{{ $status }}" @selected(($filters['status'] ?? '') === $status)>{{ $status }}</option>
          @endforeach
        </select>
      </div>
      <div class="col-md-3">
        <label class="form-label">Tipo objetivo</label>
        <select name="target_type" class="form-select">
          <option value="">Todos</option>
          @foreach(['user','field','field_photo','group_pichanga'] as $type)
            <option value="{{ $type }}" @selected(($filters['target_type'] ?? '') === $type)>{{ $type }}</option>
          @endforeach
        </select>
      </div>
      <div class="col-md-4">
        <label class="form-label">Buscar</label>
        <input type="text" name="q" value="{{ $filters['q'] ?? '' }}" class="form-control" placeholder="nick, email, motivo, target id">
      </div>
      <div class="col-md-2 d-grid">
        <button class="btn btn-primary">Filtrar</button>
      </div>
    </div>
  </form>

  <form method="POST" action="{{ route('admin.reports.bulk-resolve') }}" class="card">
    @csrf
    <div class="card-header d-flex flex-wrap gap-2 align-items-end">
      <div>
        <label class="form-label mb-0">Resolución masiva</label>
        <select name="status" class="form-select form-select-sm">
          <option value="reviewed">reviewed</option>
          <option value="dismissed">dismissed</option>
          <option value="actioned">actioned</option>
        </select>
      </div>
      <div class="flex-grow-1">
        <label class="form-label mb-0">Nota</label>
        <input type="text" name="resolution_note" class="form-control form-control-sm" maxlength="255">
      </div>
      <div>
        <button class="btn btn-sm btn-outline-primary">Aplicar a seleccionados</button>
      </div>
    </div>
    <div class="table-responsive">
      <table class="table table-sm align-middle mb-0">
        <thead>
          <tr>
            <th style="width:36px;"><input type="checkbox" onclick="document.querySelectorAll('.report-check').forEach(c=>c.checked=this.checked)"></th>
            <th>ID</th>
            <th>Estado</th>
            <th>Objetivo</th>
            <th>Motivo</th>
            <th>Reporta</th>
            <th>Creado</th>
            <th style="width:280px;">Acción</th>
          </tr>
        </thead>
        <tbody>
          @forelse($items as $item)
            <tr>
              <td><input type="checkbox" class="report-check" name="ids[]" value="{{ $item->id }}"></td>
              <td>#{{ $item->id }}</td>
              <td><span class="badge text-bg-secondary">{{ $item->status }}</span></td>
              <td>{{ $item->target_type }}:{{ $item->target_id }}</td>
              <td>{{ $item->reason_code }}</td>
              <td>{{ $item->reporter->nick ?? $item->reporter->email ?? 'N/A' }}</td>
              <td>{{ optional($item->created_at)->format('Y-m-d H:i') }}</td>
              <td>
                <form method="POST" action="{{ route('admin.reports.resolve', $item) }}" class="d-flex gap-1">
                  @csrf
                  <select name="status" class="form-select form-select-sm" style="max-width:120px">
                    <option value="reviewed">reviewed</option>
                    <option value="dismissed">dismissed</option>
                    <option value="actioned">actioned</option>
                  </select>
                  <input type="text" name="resolution_note" class="form-control form-control-sm" placeholder="Nota" maxlength="255">
                  <button class="btn btn-sm btn-outline-success">Guardar</button>
                </form>
              </td>
            </tr>
          @empty
            <tr><td colspan="8" class="text-center py-4 text-muted">Sin reportes.</td></tr>
          @endforelse
        </tbody>
      </table>
    </div>
    <div class="card-body py-2">{{ $items->links() }}</div>
  </form>
</div>
@endsection
