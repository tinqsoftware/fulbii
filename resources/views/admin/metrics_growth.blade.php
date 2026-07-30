@extends('layouts.app')

@section('content')
<div class="container">
  <h3 class="mb-3">Métricas Growth</h3>
  @include('admin.partials.nav')

  <form method="GET" class="card mb-3">
    <div class="card-body row g-2 align-items-end">
      <div class="col-md-4">
        <label class="form-label">Desde</label>
        <input type="date" name="from" class="form-control" value="{{ $from }}">
      </div>
      <div class="col-md-4">
        <label class="form-label">Hasta</label>
        <input type="date" name="to" class="form-control" value="{{ $to }}">
      </div>
      <div class="col-md-4 d-grid">
        <button class="btn btn-primary">Actualizar</button>
      </div>
    </div>
  </form>

  <div class="card mb-3">
    <div class="card-header">Totales</div>
    <div class="card-body">
      <div class="row g-2">
        @forelse(($growth['totals'] ?? []) as $k => $v)
          <div class="col-md-3">
            <div class="border rounded p-2 h-100">
              <div class="text-muted small">{{ $k }}</div>
              <div class="fs-5 fw-bold">{{ $v }}</div>
            </div>
          </div>
        @empty
          <div class="col-12 text-muted">No hay datos para el rango.</div>
        @endforelse
      </div>
    </div>
  </div>

  <div class="card">
    <div class="card-header">Serie diaria</div>
    <div class="table-responsive">
      <table class="table table-sm mb-0">
        <thead>
          <tr>
            <th>Día</th>
            <th>Join req</th>
            <th>Join ok</th>
            <th>Pichangas</th>
            <th>Confirmaciones</th>
            <th>Re-avisos</th>
            <th>Auto 48h</th>
            <th>Auto 24h</th>
          </tr>
        </thead>
        <tbody>
          @forelse(($growth['daily'] ?? []) as $row)
            <tr>
              <td>{{ $row['day'] }}</td>
              <td>{{ $row['club_join_request_created'] }}</td>
              <td>{{ $row['club_join_request_accepted'] }}</td>
              <td>{{ $row['pichanga_created'] }}</td>
              <td>{{ $row['pichanga_confirmed'] }}</td>
              <td>{{ $row['pichanga_renotify_sent'] }}</td>
              <td>{{ $row['pichanga_auto_48h_sent'] }}</td>
              <td>{{ $row['pichanga_auto_24h_sent'] }}</td>
            </tr>
          @empty
            <tr><td colspan="8" class="text-center py-3 text-muted">Sin datos.</td></tr>
          @endforelse
        </tbody>
      </table>
    </div>
  </div>
</div>
@endsection
