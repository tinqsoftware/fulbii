@extends('layouts.app')

@section('content')
<div class="container">
  <div class="admin-page-title"><div><p class="admin-eyebrow">Centro de control</p><h1>Backoffice operativo</h1><p class="admin-page-subtitle">Supervisa la salud de Fulbii y atiende las tareas que requieren acción.</p></div><a class="btn btn-primary" href="{{ route('admin.championships.index') }}">Ver campeonatos</a></div>
  @include('admin.partials.nav')

  @if(session('ok'))
    <div class="alert alert-success">{{ session('ok') }}</div>
  @endif

  <div class="admin-kpi-grid mb-3">
    <div class="admin-kpi"><div class="admin-kpi-label">Reportes pendientes</div><div class="admin-kpi-value">{{ $stats['pending_reports'] }}</div></div>
    <div class="admin-kpi"><div class="admin-kpi-label">Grupos sin admin</div><div class="admin-kpi-value">{{ $stats['groups_without_admin'] }}</div></div>
    <div class="admin-kpi"><div class="admin-kpi-label">Retos sin coordinador</div><div class="admin-kpi-value">{{ $stats['challenges_needing_coordinator'] }}</div></div>
    <div class="admin-kpi"><div class="admin-kpi-label">Canchas pendientes</div><div class="admin-kpi-value">{{ $stats['pending_field_submissions'] }}</div></div>
    <div class="admin-kpi"><div class="admin-kpi-label">Strikes activos</div><div class="admin-kpi-value">{{ $stats['active_strikes'] }}</div></div>
    <div class="admin-kpi"><div class="admin-kpi-label">Jobs pendientes</div><div class="admin-kpi-value">{{ $stats['jobs_pending'] }}</div></div>
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
