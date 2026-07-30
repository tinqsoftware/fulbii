@extends('layouts.app')

@section('content')
<div class="container">
  <h3 class="mb-3">Backoffice Operativo</h3>
  @include('admin.partials.nav')

  @if(session('ok'))
    <div class="alert alert-success">{{ session('ok') }}</div>
  @endif

  <div class="row g-3 mb-3">
    <div class="col-md-3">
      <div class="card h-100"><div class="card-body">
        <div class="text-muted">Reportes pendientes</div>
        <div class="fs-3 fw-bold">{{ $stats['pending_reports'] }}</div>
      </div></div>
    </div>
    <div class="col-md-3">
      <div class="card h-100"><div class="card-body">
        <div class="text-muted">Canchas pendientes</div>
        <div class="fs-3 fw-bold">{{ $stats['pending_field_submissions'] }}</div>
      </div></div>
    </div>
    <div class="col-md-3">
      <div class="card h-100"><div class="card-body">
        <div class="text-muted">Strikes activos</div>
        <div class="fs-3 fw-bold">{{ $stats['active_strikes'] }}</div>
      </div></div>
    </div>
    <div class="col-md-3">
      <div class="card h-100"><div class="card-body">
        <div class="text-muted">Jobs pendientes</div>
        <div class="fs-3 fw-bold">{{ $stats['jobs_pending'] }}</div>
      </div></div>
    </div>
  </div>

  <div class="row g-3">
    <div class="col-lg-6">
      <div class="card">
        <div class="card-header d-flex justify-content-between align-items-center">
          <span>Salud Operativa</span>
          <a href="{{ route('admin.ops.readiness') }}" class="btn btn-sm btn-outline-primary">Ver detalle</a>
        </div>
        <div class="card-body">
          <ul class="list-unstyled mb-0">
            <li><strong>Queue:</strong> {{ $readiness['queue_connection'] }}</li>
            <li><strong>Failed jobs:</strong> {{ $readiness['failed_jobs_count'] }}</li>
            <li><strong>Push driver:</strong> {{ $readiness['push_driver'] }}</li>
            <li><strong>Well-known OK:</strong> {{ $readiness['well_known_endpoints_ok'] ? 'Sí' : 'No' }}</li>
            <li><strong>Última ola auto:</strong> {{ $readiness['last_auto_wave_at'] ?? 'N/A' }}</li>
          </ul>
        </div>
      </div>
    </div>
    <div class="col-lg-6">
      <div class="card">
        <div class="card-header d-flex justify-content-between align-items-center">
          <span>Growth (últimos 7 días)</span>
          <a href="{{ route('admin.metrics.growth') }}" class="btn btn-sm btn-outline-primary">Ver reporte</a>
        </div>
        <div class="card-body">
          <ul class="list-unstyled mb-0">
            <li><strong>Join requests:</strong> {{ $growth['totals']['join_requests'] ?? 0 }}</li>
            <li><strong>Joins aceptados:</strong> {{ $growth['totals']['join_accepted'] ?? 0 }}</li>
            <li><strong>Pichangas creadas:</strong> {{ $growth['totals']['pichangas_created'] ?? 0 }}</li>
            <li><strong>Confirmaciones:</strong> {{ $growth['totals']['confirmations'] ?? 0 }}</li>
            <li><strong>Re-avisos:</strong> {{ $growth['totals']['renotify_sent'] ?? 0 }}</li>
          </ul>
        </div>
      </div>
    </div>
  </div>
</div>
@endsection
