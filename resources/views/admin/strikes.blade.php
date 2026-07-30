@extends('layouts.app')

@section('content')
<div class="container">
  <h3 class="mb-3">Moderación · Strikes</h3>
  @include('admin.partials.nav')

  @if(session('ok'))
    <div class="alert alert-success">{{ session('ok') }}</div>
  @endif
  @if($errors->any())
    <div class="alert alert-danger">{{ $errors->first() }}</div>
  @endif

  <div class="card mb-3">
    <div class="card-header">Aplicar strike</div>
    <div class="card-body">
      <form method="POST" action="{{ route('admin.strikes.issue') }}" class="row g-2 align-items-end">
        @csrf
        <div class="col-md-2">
          <label class="form-label">User ID</label>
          <input type="number" name="user_id" class="form-control" min="1" required>
        </div>
        <div class="col-md-2">
          <label class="form-label">Report ID</label>
          <input type="number" name="report_id" class="form-control" min="1">
        </div>
        <div class="col-md-3">
          <label class="form-label">Reason code</label>
          <input type="text" name="reason_code" class="form-control" maxlength="60" required>
        </div>
        <div class="col-md-3">
          <label class="form-label">Descripción</label>
          <input type="text" name="description" class="form-control" maxlength="500">
        </div>
        <div class="col-md-1">
          <label class="form-label">Días</label>
          <input type="number" name="expires_days" class="form-control" min="1" max="365">
        </div>
        <div class="col-md-1 d-grid">
          <button class="btn btn-primary">Aplicar</button>
        </div>
      </form>
    </div>
  </div>

  <form method="GET" class="card mb-3">
    <div class="card-body row g-2 align-items-end">
      <div class="col-md-3">
        <label class="form-label">Estado</label>
        <select name="status" class="form-select">
          <option value="">Todos</option>
          @foreach(['active','revoked'] as $status)
            <option value="{{ $status }}" @selected(($filters['status'] ?? '') === $status)>{{ $status }}</option>
          @endforeach
        </select>
      </div>
      <div class="col-md-2">
        <label class="form-label">User ID</label>
        <input type="number" name="user_id" class="form-control" min="1" value="{{ $filters['user_id'] ?? '' }}">
      </div>
      <div class="col-md-5">
        <label class="form-label">Buscar</label>
        <input type="text" name="q" class="form-control" value="{{ $filters['q'] ?? '' }}" placeholder="nick, email, motivo">
      </div>
      <div class="col-md-2 d-grid">
        <button class="btn btn-primary">Filtrar</button>
      </div>
    </div>
  </form>

  <form method="POST" action="{{ route('admin.strikes.bulk-revoke') }}" class="card">
    @csrf
    <div class="card-header d-flex flex-wrap gap-2 align-items-end">
      <div class="flex-grow-1">
        <label class="form-label mb-0">Nota de revocación masiva</label>
        <input type="text" name="revoked_note" class="form-control form-control-sm" maxlength="255">
      </div>
      <div>
        <button class="btn btn-sm btn-outline-primary">Revocar seleccionados</button>
      </div>
    </div>
    <div class="table-responsive">
      <table class="table table-sm align-middle mb-0">
        <thead>
          <tr>
            <th style="width:36px;"><input type="checkbox" onclick="document.querySelectorAll('.strike-check').forEach(c=>c.checked=this.checked)"></th>
            <th>ID</th>
            <th>Estado</th>
            <th>Usuario</th>
            <th>Motivo</th>
            <th>Report</th>
            <th>Expira</th>
            <th style="width:280px;">Acción</th>
          </tr>
        </thead>
        <tbody>
          @forelse($items as $item)
            <tr>
              <td><input type="checkbox" class="strike-check" name="ids[]" value="{{ $item->id }}"></td>
              <td>#{{ $item->id }}</td>
              <td><span class="badge text-bg-secondary">{{ $item->status }}</span></td>
              <td>{{ $item->user->nick ?? $item->user->email ?? 'N/A' }}</td>
              <td>{{ $item->reason_code }}</td>
              <td>{{ $item->report_id ?: 'global' }}</td>
              <td>{{ optional($item->expires_at)->format('Y-m-d H:i') ?: 'N/A' }}</td>
              <td>
                @if($item->status === 'active')
                  <form method="POST" action="{{ route('admin.strikes.revoke', $item) }}" class="d-flex gap-1">
                    @csrf
                    <input type="text" name="revoked_note" class="form-control form-control-sm" placeholder="Nota revocación">
                    <button class="btn btn-sm btn-outline-danger">Revocar</button>
                  </form>
                @else
                  <span class="text-muted">Sin acción</span>
                @endif
              </td>
            </tr>
          @empty
            <tr><td colspan="8" class="text-center py-4 text-muted">Sin strikes.</td></tr>
          @endforelse
        </tbody>
      </table>
    </div>
    <div class="card-body py-2">{{ $items->links() }}</div>
  </form>
</div>
@endsection
