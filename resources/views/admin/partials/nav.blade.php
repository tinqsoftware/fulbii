<div class="card mb-3">
  <div class="card-body py-2">
    <div class="d-flex flex-wrap gap-2">
      <a href="{{ route('admin.dashboard') }}" class="btn btn-sm {{ request()->routeIs('admin.dashboard') ? 'btn-primary' : 'btn-outline-primary' }}">Dashboard</a>
      <a href="{{ route('admin.reports.index') }}" class="btn btn-sm {{ request()->routeIs('admin.reports.*') ? 'btn-primary' : 'btn-outline-primary' }}">Reportes</a>
      <a href="{{ route('admin.field-submissions.index') }}" class="btn btn-sm {{ request()->routeIs('admin.field-submissions.*') ? 'btn-primary' : 'btn-outline-primary' }}">Solicitudes de canchas</a>
      @if(Auth::user()?->canPerformCriticalAdminActions())
        <a href="{{ route('admin.fields.index') }}" class="btn btn-sm {{ request()->routeIs('admin.fields.*') || request()->routeIs('admin.courts.*') ? 'btn-primary' : 'btn-outline-primary' }}">Canchas reales</a>
      @endif
      <a href="{{ route('admin.strikes.index') }}" class="btn btn-sm {{ request()->routeIs('admin.strikes.*') ? 'btn-primary' : 'btn-outline-primary' }}">Strikes</a>
      <a href="{{ route('admin.metrics.growth') }}" class="btn btn-sm {{ request()->routeIs('admin.metrics.*') ? 'btn-primary' : 'btn-outline-primary' }}">Métricas</a>
      <a href="{{ route('admin.ops.readiness') }}" class="btn btn-sm {{ request()->routeIs('admin.ops.*') ? 'btn-primary' : 'btn-outline-primary' }}">Ops Readiness</a>
      <a href="{{ route('admin.championships.index') }}" class="btn btn-sm {{ request()->routeIs('admin.championships.*') ? 'btn-primary' : 'btn-outline-primary' }}">Campeonatos</a>
    </div>
  </div>
</div>
