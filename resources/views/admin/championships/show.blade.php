@extends('layouts.app')

@section('content')
<div class="container">
  <h3 class="mb-3">{{ $championship->name }}</h3>
  @include('admin.partials.nav')
  @if(session('ok')) <div class="alert alert-success">{{ session('ok') }}</div> @endif
  <div class="row g-3">
    <div class="col-lg-5"><div class="card card-body h-100">
      <div class="text-muted">{{ $championship->status }} · {{ $championship->visibility }}</div>
      <p class="mt-2">{{ $championship->description ?: 'Sin descripción.' }}</p>
      <dl class="row mb-0"><dt class="col-7">Formato</dt><dd class="col-5">{{ $championship->format === 'knockout' ? 'Llaves' : ($championship->format === 'hybrid' ? 'Liga + playoffs' : 'Liga') }}{{ $championship->format !== 'knockout' ? ($championship->double_round_robin ? ' (ida y vuelta)' : ' (una vuelta)') : '' }}</dd><dt class="col-7">Equipos</dt><dd class="col-5">{{ $championship->teams_count }}/{{ $championship->max_teams }}</dd><dt class="col-7">Puntos</dt><dd class="col-5">{{ $championship->points_win }}-{{ $championship->points_draw }}-{{ $championship->points_loss }}</dd><dt class="col-7">Sede principal</dt><dd class="col-5">{{ $championship->venue?->nombre ?: 'Por partido' }}</dd></dl>
      <div class="mt-3 d-flex gap-2 flex-wrap">
        @if($canManageSettings && $championship->status === 'draft')
          <form method="post" action="{{ route('admin.championships.publish', $championship) }}">@csrf<input type="hidden" name="status" value="registration"><button class="btn btn-outline-success">Abrir inscripciones</button></form>
        @endif
        @if($canManageSettings && in_array($championship->status, ['draft', 'registration'], true))
          <form method="post" action="{{ route('admin.championships.publish', $championship) }}">@csrf<input type="hidden" name="status" value="published"><button class="btn btn-success">Publicar campeonato</button></form>
        @endif
      </div>
    </div></div>
    <div class="col-lg-7"><div class="card card-body h-100">
      <h5>Equipos</h5>
      @forelse($championship->teams as $team)
        <div class="border-bottom py-2">
          <div class="d-flex justify-content-between"><span class="fw-semibold">{{ $team->name }}</span><small>{{ $team->captain?->nick ?: 'Sin capitán' }}</small></div>
          <div class="small text-muted mt-1">{{ $team->members->where('status', 'approved')->count() }} aprobados · {{ $team->members->where('status', 'invited')->count() }} invitaciones</div>
          @if($team->members->isNotEmpty())<div class="small mt-1">@foreach($team->members as $member)<span class="me-2">{{ '@'.($member->user?->nick ?: $member->user?->name ?: $member->user_id) }} <span class="text-muted">({{ $member->status }})</span></span>@endforeach</div>@endif
          @if($canManageRosters)
            <form method="post" action="{{ route('admin.championships.teams.members.invite', $team) }}" class="row g-2 mt-2">
              @csrf
              <div class="col-md-8"><input required name="nick" class="form-control form-control-sm" placeholder="Nickname del jugador"></div>
              <div class="col-md-4"><button class="btn btn-sm btn-outline-primary w-100">Invitar jugador</button></div>
            </form>
          @endif
        </div>
      @empty<p class="text-muted">Añade equipos para iniciar el campeonato.</p>@endforelse
      @if($canManageFixture)
        <div class="mt-3 d-flex gap-2 flex-wrap"><form method="post" action="{{ route('admin.championships.fixture.generate', $championship) }}">@csrf<button class="btn btn-outline-primary" {{ $championship->teams_count < 2 ? 'disabled' : '' }}>Generar fixture</button></form></div>
      @endif
    </div></div>
  </div>
  @if($canManageAdmins)
  <div class="card card-body mt-3">
    <h5>Gestores</h5>
    @forelse($championship->admins as $admin)<div class="d-flex justify-content-between border-bottom py-2"><span>{{ $admin->user?->nick ?: $admin->user?->name ?: 'Usuario '.$admin->user_id }}</span><small>{{ $admin->role }}</small></div>@empty<p class="text-muted">Sin gestores adicionales.</p>@endforelse
    <form method="post" action="{{ route('admin.championships.admins.store', $championship) }}" class="row g-2 mt-2">
      @csrf
      <div class="col-md-4"><input required name="user_id" type="number" min="1" class="form-control" placeholder="ID del usuario gestor"></div>
      <div class="col-md-6 d-flex gap-2 flex-wrap align-items-center small">
        @foreach(['manage_teams' => 'Plantillas', 'manage_rosters' => 'Invitaciones', 'manage_fixture' => 'Fixture', 'manage_match_results' => 'Actas'] as $permission => $label)
          <label><input type="checkbox" name="permissions[{{ $permission }}]" value="1" checked> {{ $label }}</label>
        @endforeach
      </div>
      <div class="col-md-2"><button class="btn btn-outline-primary w-100">Añadir</button></div>
    </form>
  </div>
  @endif
  @if($canManageTeams)
  <div class="card card-body mt-3">
    <h5>Añadir equipo</h5>
    <form method="post" action="{{ route('admin.championships.teams.store', $championship) }}" class="row g-2">
      @csrf
      <div class="col-md-5"><input required name="name" class="form-control" placeholder="Nombre del equipo"></div>
      <div class="col-md-2"><input name="color" class="form-control" placeholder="Color"></div>
      <div class="col-md-3"><input name="captain_user_id" type="number" min="1" class="form-control" placeholder="ID capitán (opcional)"></div>
      <div class="col-md-2"><button class="btn btn-primary w-100">Añadir</button></div>
    </form>
    <small class="text-muted mt-2">El capitán debe estar registrado; luego podrá invitar jugadores desde la app o API.</small>
  </div>
  @endif
  <div class="card card-body mt-3"><h5>Jornadas y partidos</h5>
    @forelse($championship->matchdays as $day)
      <div class="mb-3">
        <div class="d-flex justify-content-between align-items-center"><strong>{{ $day->name }}</strong><small class="text-muted">{{ $day->starts_at?->format('d/m H:i') ?: 'Horario pendiente' }}{{ $day->ends_at ? ' – '.$day->ends_at->format('H:i') : '' }}</small></div>
        @if($canManageFixture)
        <form method="post" action="{{ route('admin.championships.matchdays.schedule', $day) }}" class="row g-2 mt-2">
          @csrf
          <div class="col-md-3"><input required type="date" name="match_date" value="{{ $day->match_date?->format('Y-m-d') }}" class="form-control" aria-label="Fecha de jornada"></div>
          <div class="col-md-3"><input required type="datetime-local" name="starts_at" value="{{ $day->starts_at?->format('Y-m-d\\TH:i') }}" class="form-control" aria-label="Inicio de jornada"></div>
          <div class="col-md-3"><input required type="datetime-local" name="ends_at" value="{{ $day->ends_at?->format('Y-m-d\\TH:i') }}" class="form-control" aria-label="Fin de jornada"></div>
          <div class="col-md-3"><button class="btn btn-outline-secondary w-100">Guardar horario de fecha</button></div>
        </form>
        @endif
        <div class="row g-2 mt-1">
          @foreach($day->matches as $match)
            <div class="col-12"><div class="border rounded p-2">
              <div class="d-flex justify-content-between"><span><strong>{{ $match->homeTeam?->name }}</strong> vs <strong>{{ $match->awayTeam?->name }}</strong></span><small>{{ $match->status }}</small></div>
              <small class="text-muted">{{ $match->starts_at?->format('d/m H:i') ?: 'Horario pendiente' }} · {{ $match->field_id ? 'Cancha asignada' : 'Cancha pendiente' }}{{ $match->pichanga_id ? ' · Pichanga #'.$match->pichanga_id : '' }}</small>
              @if($canManageFixture)
              <form method="post" action="{{ route('admin.championships.matches.schedule', $match) }}" class="row g-2 mt-2">
                @csrf
                <div class="col-md-3"><select required name="field_id" class="form-select"><option value="">Sede</option>@foreach($venues as $venue)<option value="{{ $venue->id }}" @selected($match->field_id == $venue->id)>{{ $venue->nombre }}</option>@endforeach</select></div>
                <div class="col-md-3"><select required name="cancha_id" class="form-select"><option value="">Cancha</option>@foreach($venues as $venue)<optgroup label="{{ $venue->nombre }}">@foreach($venue->canchas as $court)<option value="{{ $court->id }}" @selected($match->cancha_id == $court->id)>{{ $court->nombre }}</option>@endforeach</optgroup>@endforeach</select></div>
                <div class="col-md-2"><input required type="datetime-local" name="starts_at" value="{{ $match->starts_at?->format('Y-m-d\\TH:i') }}" class="form-control"></div>
                <div class="col-md-2"><input required type="datetime-local" name="ends_at" value="{{ $match->ends_at?->format('Y-m-d\\TH:i') }}" class="form-control"></div>
                <div class="col-md-1"><input required type="number" name="duration_minutes" min="15" max="240" value="{{ $match->duration_minutes ?: 60 }}" class="form-control" title="Minutos"></div>
                <div class="col-md-1"><button class="btn btn-outline-primary w-100" title="Programar">✓</button></div>
              </form>
              @endif
              @if($canManageResults)
              <form method="post" action="{{ route('admin.championships.matches.result', $match) }}" class="row g-2 mt-2">
                @csrf
                <div class="col-md-2"><input required type="number" name="home_score" min="0" max="99" value="{{ $match->home_score ?? 0 }}" class="form-control" aria-label="Goles local"></div>
                <div class="col-md-2"><input required type="number" name="away_score" min="0" max="99" value="{{ $match->away_score ?? 0 }}" class="form-control" aria-label="Goles visitante"></div>
                <div class="col-md-3"><button class="btn btn-outline-success">Guardar resultado</button></div>
                <div class="col-12"><textarea name="events_json" rows="2" class="form-control form-control-sm" placeholder='Eventos opcionales JSON: [{"event_type":"goal","player_user_id":123,"championship_team_id":4,"minute":12,"secondary_player_user_id":456}]'></textarea><small class="text-muted">Los eventos se guardan en el acta y alimentan goles, asistencias y tarjetas.</small></div>
              </form>
              @endif
            </div></div>
          @endforeach
        </div>
      </div>
    @empty<p class="text-muted mb-0">El fixture todavía no fue generado.</p>@endforelse
  </div>
</div>
@endsection
