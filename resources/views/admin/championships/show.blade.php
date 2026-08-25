@extends('layouts.app')

@section('content')
@php
  $statusLabels = ['draft' => 'Borrador', 'registration' => 'Inscripciones abiertas', 'published' => 'Publicado', 'completed' => 'Finalizado'];
  $formatLabels = ['league' => 'Liga', 'knockout' => 'Llaves', 'hybrid' => 'Liga + playoffs'];
  $formatLabel = $formatLabels[$championship->format] ?? ucfirst((string) $championship->format);
  $statusLabel = $statusLabels[$championship->status] ?? ucfirst((string) $championship->status);
  $statusClass = in_array($championship->status, ['published', 'completed'], true) ? 'admin-status--success' : (in_array($championship->status, ['registration'], true) ? 'admin-status--warning' : 'admin-status--muted');
  $approvedMembers = $championship->teams->sum(fn ($team) => $team->members->where('status', 'approved')->count());
  $pendingInvites = $championship->teams->sum(fn ($team) => $team->members->where('status', 'invited')->count());
  $allMatches = $championship->matchdays->flatMap(fn ($day) => $day->matches);
  $scheduledMatches = $allMatches->filter(fn ($match) => $match->starts_at && $match->field_id)->count();
  $playedMatches = $allMatches->filter(fn ($match) => $match->status === 'finished' || ($match->home_score !== null && $match->away_score !== null))->count();
@endphp
<div class="container admin-championship-page">
  <div class="admin-page-title">
    <div>
      <p class="admin-eyebrow">Gestión de campeonato</p>
      <h1>{{ $championship->name }}</h1>
      <p class="admin-page-subtitle">{{ $formatLabel }}{{ $championship->format !== 'knockout' ? ($championship->double_round_robin ? ' · Ida y vuelta' : ' · Una vuelta') : '' }} · {{ $championship->visibility === 'public' ? 'Público' : ($championship->visibility === 'private' ? 'Privado' : 'Solo con enlace') }}</p>
    </div>
    <span class="badge admin-status {{ $statusClass }}">{{ $statusLabel }}</span>
  </div>
  @include('admin.partials.nav')
  @if(session('ok')) <div class="alert alert-success">{{ session('ok') }}</div> @endif
  @if($errors->any()) <div class="alert alert-danger"><ul class="mb-0">@foreach($errors->all() as $error)<li>{{ $error }}</li>@endforeach</ul></div> @endif
  <nav class="admin-section-nav" aria-label="Secciones del campeonato">
    <a href="#resumen">Resumen</a><a href="#equipos">Equipos</a><a href="#fixture">Fixture</a>
    @if($canManageAdmins)<a href="#gestores">Gestores</a>@endif
  </nav>
  <div class="admin-kpi-grid mb-3" aria-label="Indicadores del campeonato">
    <div class="admin-kpi"><div class="admin-kpi-label">Equipos registrados</div><div class="admin-kpi-value">{{ $championship->teams_count }}<span class="fs-6 text-muted fw-normal"> / {{ $championship->max_teams }}</span></div></div>
    <div class="admin-kpi"><div class="admin-kpi-label">Miembros aprobados</div><div class="admin-kpi-value">{{ $approvedMembers }}</div></div>
    <div class="admin-kpi"><div class="admin-kpi-label">Invitaciones pendientes</div><div class="admin-kpi-value">{{ $pendingInvites }}</div></div>
    <div class="admin-kpi"><div class="admin-kpi-label">Jornadas · partidos</div><div class="admin-kpi-value">{{ $championship->matchdays->count() }}<span class="fs-6 text-muted fw-normal"> · {{ $allMatches->count() }}</span></div></div>
    <div class="admin-kpi"><div class="admin-kpi-label">Programados</div><div class="admin-kpi-value">{{ $scheduledMatches }}</div></div>
    <div class="admin-kpi"><div class="admin-kpi-label">Resultados registrados</div><div class="admin-kpi-value">{{ $playedMatches }}</div></div>
  </div>
  <div class="row g-3">
    <div class="col-lg-5" id="resumen"><div class="card card-body h-100">
      <div class="d-flex justify-content-between align-items-start gap-2 mb-2"><div><p class="admin-eyebrow mb-1">Resumen</p><h2 class="h5 mb-0">Configuración</h2></div><span class="badge admin-status {{ $statusClass }}">{{ $statusLabel }}</span></div>
      <p class="mt-2">{{ $championship->description ?: 'Sin descripción.' }}</p>
      <div class="mb-2"><div class="d-flex justify-content-between align-items-center"><strong>Grupos asociados</strong>@if($canManageSettings && in_array($championship->status, ['draft', 'registration'], true))<button type="button" class="btn btn-sm btn-outline-primary" data-bs-toggle="modal" data-bs-target="#groups-edit-modal">Editar grupos</button>@endif</div><div class="d-flex flex-wrap gap-2 mt-1">
        @forelse($championship->clubs as $club)
          <span class="badge rounded-pill text-bg-light border d-inline-flex align-items-center gap-1">@if($club->logo_url)<img src="{{ $club->logo_url }}" alt="" width="22" height="22" class="rounded-circle" style="object-fit:cover">@else<span>⚽</span>@endif {{ $club->nombre }}</span>
        @empty <span class="small text-muted">Sin grupos asociados.</span> @endforelse
      </div></div>
      <dl class="row mb-0"><dt class="col-7">Formato</dt><dd class="col-5">{{ $championship->format === 'knockout' ? 'Llaves' : ($championship->format === 'hybrid' ? 'Liga + playoffs' : 'Liga') }}{{ $championship->format !== 'knockout' ? ($championship->double_round_robin ? ' (ida y vuelta)' : ' (una vuelta)') : '' }}</dd><dt class="col-7">Equipos</dt><dd class="col-5">{{ $championship->teams_count }}/{{ $championship->max_teams }}</dd><dt class="col-7">Puntos</dt><dd class="col-5">{{ $championship->points_win }}-{{ $championship->points_draw }}-{{ $championship->points_loss }}</dd><dt class="col-7">Sede principal</dt><dd class="col-5">{{ $championship->venue?->nombre ?: 'Por partido' }}</dd></dl>
      <div class="mt-3 d-flex gap-2 flex-wrap">
        @if($canManageSettings && $championship->status === 'draft')
          <form method="post" action="{{ route('admin.championships.publish', $championship) }}">@csrf<input type="hidden" name="status" value="registration"><button class="btn btn-outline-success">Abrir inscripciones</button></form>
        @endif
        @if($canManageSettings && in_array($championship->status, ['draft', 'registration'], true))
          <form method="post" action="{{ route('admin.championships.publish', $championship) }}">@csrf<input type="hidden" name="status" value="published"><button class="btn btn-success" {{ $championship->teams_count < 2 || !$championship->matches()->exists() ? 'disabled' : '' }}>Publicar campeonato</button></form>
          @if($championship->teams_count < 2)<span class="small text-muted align-self-center">Añade al menos 2 equipos para publicar.</span>@elseif(!$championship->matches()->exists())<span class="small text-muted align-self-center">Genera el fixture para publicar.</span>@endif
        @endif
        @if($canManageSettings)
          <button type="button" class="btn btn-outline-danger ms-auto" data-bs-toggle="modal" data-bs-target="#delete-championship-modal">Eliminar campeonato</button>
        @endif
      </div>
    </div></div>
    <div class="col-lg-7" id="equipos"><div class="card card-body h-100">
      <div class="d-flex justify-content-between align-items-start gap-2 mb-3"><div><p class="admin-eyebrow mb-1">Plantillas</p><h2 class="h5 mb-0">Equipos e invitaciones</h2></div><span class="badge text-bg-light border">{{ $championship->teams_count }} equipos</span></div>
      @forelse($championship->teams as $team)
        <article class="admin-team-card mb-3">
          <div class="team-head"><div><div class="d-flex align-items-center gap-2"><span class="admin-avatar" aria-hidden="true">{{ mb_strtoupper(mb_substr($team->name, 0, 1)) }}</span><strong>{{ $team->name }}</strong></div><div class="small text-muted mt-2">{{ $team->members->where('status', 'approved')->count() }} aprobados · {{ $team->members->where('status', 'invited')->count() }} invitaciones pendientes</div></div><div class="text-end"><small class="d-block text-muted">Capitán</small><strong>{{ $team->captain?->nick ?: 'Sin capitán' }}</strong>@if($canManageTeams && $team->captain_change_allowed)<button type="button" class="btn btn-sm btn-outline-secondary d-block mt-2" data-bs-toggle="modal" data-bs-target="#users-modal" data-user-mode="captain" data-team-id="{{ $team->id }}">Cambiar capitán</button><form method="post" action="{{ route('admin.championships.teams.captain', $team) }}" id="captain-form-{{ $team->id }}" class="d-none">@csrf<input type="hidden" name="user_id" id="captain-team-user-{{ $team->id }}"></form>@endif</div></div>
          <div class="team-body">
          @if($team->members->isNotEmpty())<div class="mb-2">@foreach($team->members as $member)<div class="admin-member-row"><span class="d-flex align-items-center gap-2"><span class="admin-avatar" aria-hidden="true">{{ mb_strtoupper(mb_substr($member->user?->nick ?: $member->user?->name ?: '?', 0, 1)) }}</span><span>{{ '@'.($member->user?->nick ?: $member->user?->name ?: $member->user_id) }}</span></span><span class="badge admin-status {{ $member->status === 'approved' ? 'admin-status--success' : 'admin-status--warning' }}">{{ $member->status === 'approved' ? 'Aprobado' : 'Invitado' }}</span></div>@endforeach</div>@else<div class="admin-empty py-3"><div class="admin-empty-icon">👥</div><div>Aún no hay jugadores en este equipo.</div></div>@endif
          @if($canManageRosters)
            <form method="post" action="{{ route('admin.championships.teams.members.invite', $team) }}" class="row g-2 mt-2">
              @csrf
              <div class="col-md-8"><input required name="nick" class="form-control form-control-sm" placeholder="Nickname del jugador"></div>
              <div class="col-md-4"><button class="btn btn-sm btn-outline-primary w-100">Invitar jugador</button></div>
            </form>
            <div class="form-text">La persona recibirá una invitación y debe aceptarla para quedar aprobada.</div>
          @endif
          </div>
        </article>
      @empty<p class="text-muted">Añade equipos para iniciar el campeonato.</p>@endforelse
      @if($canManageFixture)
        <div class="mt-3 d-flex gap-2 flex-wrap"><form method="post" action="{{ route('admin.championships.fixture.generate', $championship) }}">@csrf<button class="btn btn-outline-primary" {{ $championship->teams_count < 2 ? 'disabled' : '' }}>Generar fixture</button></form></div>
      @endif
    </div></div>
  </div>
  @if($canManageAdmins)
  <div class="card card-body mt-3" id="gestores">
    <div class="d-flex justify-content-between align-items-start gap-2 mb-3"><div><p class="admin-eyebrow mb-1">Permisos</p><h2 class="h5 mb-0">Gestores del campeonato</h2></div><span class="small text-muted">Acceso por función</span></div>
    @forelse($championship->admins as $admin)<div class="d-flex justify-content-between align-items-center border-bottom py-2"><span>{{ $admin->user?->nick ?: $admin->user?->name ?: 'Usuario '.$admin->user_id }}</span><span class="d-flex gap-2 align-items-center"><small>{{ $admin->role }}</small>@if($admin->role !== 'owner')<form method="post" action="{{ route('admin.championships.admins.destroy', [$championship, $admin]) }}">@csrf @method('DELETE')<button class="btn btn-sm btn-outline-danger">Retirar</button></form>@endif</span></div>@empty<p class="text-muted">Sin gestores adicionales.</p>@endforelse
    <form method="post" action="{{ route('admin.championships.admins.store', $championship) }}" class="row g-2 mt-2" id="admins-form">
      @csrf
      <div class="col-md-4"><button type="button" class="btn btn-outline-secondary w-100" data-bs-toggle="modal" data-bs-target="#users-modal" data-user-mode="admins">Seleccionar gestores</button><div id="selected-admins" class="d-flex flex-wrap gap-1 mt-2"></div><div id="admin-inputs"></div></div>
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
    <div class="d-flex justify-content-between align-items-start gap-2 mb-3"><div><p class="admin-eyebrow mb-1">Configuración</p><h2 class="h5 mb-0">Añadir equipo</h2></div><span class="small text-muted">El capitán se asigna directamente</span></div>
    <form method="post" action="{{ route('admin.championships.teams.store', $championship) }}" class="row g-2" id="team-form">
      @csrf
      <div class="col-md-5"><input required name="name" class="form-control" placeholder="Nombre del equipo"></div>
      <div class="col-md-2"><input name="color" class="form-control" placeholder="Color"></div>
      <div class="col-md-3"><button type="button" class="btn btn-outline-secondary w-100" data-bs-toggle="modal" data-bs-target="#users-modal" data-user-mode="captain">Elegir capitán</button><div id="selected-captain" class="small text-muted mt-1">Sin capitán</div><input type="hidden" name="captain_user_id" id="captain-user-id"></div>
      <div class="col-md-2"><button class="btn btn-primary w-100">Añadir</button></div>
    </form>
    <small class="text-muted mt-2">El capitán debe estar registrado; luego podrá invitar jugadores desde la app o API.</small>
  </div>
  @endif
  <div class="card card-body mt-3" id="fixture"><div class="d-flex justify-content-between align-items-start gap-2 mb-3"><div><p class="admin-eyebrow mb-1">Competición</p><h2 class="h5 mb-0">Fixture, horarios y resultados</h2><p class="admin-page-subtitle mb-0">Programa cada jornada y registra el acta del partido.</p></div><span class="badge text-bg-light border">{{ $allMatches->count() }} partidos</span></div>
    @forelse($championship->matchdays as $day)
      <details class="admin-matchday mb-3" @if($loop->first) open @endif>
        <summary><span><strong>{{ $day->name }}</strong><small class="d-block text-muted mt-1">{{ $day->matches->count() }} partido{{ $day->matches->count() === 1 ? '' : 's' }}</small></span><span class="text-end"><span class="badge {{ $day->starts_at ? 'admin-status admin-status--success' : 'admin-status admin-status--warning' }}">{{ $day->starts_at ? 'Horario confirmado' : 'Horario pendiente' }}</span><small class="d-block text-muted mt-1">{{ $day->starts_at?->format('d/m H:i') ?: 'Por definir' }}{{ $day->ends_at ? ' – '.$day->ends_at->format('H:i') : '' }}</small></span></summary>
        <div class="px-3 pb-3">
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
            <div class="col-12"><div class="admin-match">
              <div class="d-flex justify-content-between align-items-start gap-2"><span><strong>{{ $match->homeTeam?->name }}</strong><span class="text-muted mx-1">vs</span><strong>{{ $match->awayTeam?->name }}</strong></span><span class="badge admin-status {{ $match->status === 'finished' ? 'admin-status--success' : 'admin-status--muted' }}">{{ $match->status === 'finished' ? 'Finalizado' : ucfirst($match->status ?: 'Programado') }}</span></div>
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
              @php
                $eventTeams = collect([$match->homeTeam, $match->awayTeam])->filter();
                $eventTeamOptions = $eventTeams->map(fn ($team) => ['id' => (int) $team->id, 'name' => $team->name])->values()->all();
                $eventMembers = $eventTeams->mapWithKeys(fn ($team) => [(string) $team->id => $team->members->where('status', 'approved')->map(fn ($member) => ['id' => (int) $member->user_id, 'nick' => $member->user?->nick, 'name' => $member->user?->name, 'avatar_url' => $member->user?->avatar_url])->values()->all()])->all();
                $eventSeed = $match->events->map(fn ($event) => ['event_type' => $event->event_type, 'championship_team_id' => $event->championship_team_id, 'player_user_id' => $event->player_user_id, 'secondary_player_user_id' => $event->secondary_player_user_id, 'minute' => $event->minute])->values()->all();
              @endphp
              <form method="post" action="{{ route('admin.championships.matches.result', $match) }}" class="row g-2 mt-2 admin-result-form" data-result-form>
                @csrf
                <div class="col-12"><div class="admin-result-scorebar"><div><span class="admin-eyebrow mb-1">Acta del partido</span><strong>{{ $match->homeTeam?->name }} <span class="text-muted">vs</span> {{ $match->awayTeam?->name }}</strong></div><div class="admin-score-fields"><label>Local<input required type="number" name="home_score" min="0" max="99" value="{{ $match->home_score ?? 0 }}" class="form-control admin-score-input" aria-label="Goles local"></label><span class="admin-score-separator">–</span><label>Visitante<input required type="number" name="away_score" min="0" max="99" value="{{ $match->away_score ?? 0 }}" class="form-control admin-score-input" aria-label="Goles visitante"></label></div></div></div>
                <div class="col-12">
                  <div class="admin-events-editor" data-events-editor data-event-seed="{!! e(json_encode($eventSeed, JSON_UNESCAPED_UNICODE)) !!}" data-event-teams="{!! e(json_encode($eventTeamOptions, JSON_UNESCAPED_UNICODE)) !!}" data-event-members="{!! e(json_encode($eventMembers, JSON_UNESCAPED_UNICODE)) !!}">
                    <div class="admin-events-header"><div><h4 class="h6 mb-1">Eventos del partido</h4><p class="small text-muted mb-0">Registra goles, tarjetas y cambios sin escribir código.</p></div><div class="admin-event-summary" data-events-summary aria-live="polite"></div></div>
                    <div class="admin-events-list" data-events-list></div>
                    <div class="admin-events-empty" data-events-empty><span class="admin-empty-icon">⚽</span><strong>Aún no hay eventos</strong><span>Agrega el primer evento del acta.</span></div>
                    <div class="d-flex flex-wrap align-items-center gap-2 mt-3"><button type="button" class="btn btn-sm btn-outline-primary" data-add-event>+ Agregar evento</button><span class="small text-muted">Los jugadores disponibles son los miembros aprobados de ambos equipos.</span></div>
                    <input type="hidden" name="events_json" value="[]" data-events-json>
                    <details class="admin-events-advanced mt-3"><summary>Opciones avanzadas <span class="small text-muted">(solo para casos especiales)</span></summary><div class="pt-3"><p class="small text-muted">El editor visual genera este JSON automáticamente. Puedes revisarlo o editarlo y luego aplicar los cambios.</p><textarea class="form-control admin-json-editor" rows="6" data-json-editor readonly aria-label="JSON avanzado de eventos"></textarea><div class="d-flex flex-wrap gap-2 mt-2"><button type="button" class="btn btn-sm btn-outline-secondary" data-toggle-json>Editar JSON</button><button type="button" class="btn btn-sm btn-primary d-none" data-apply-json>Aplicar JSON</button></div><div class="small text-danger mt-2 d-none" data-json-error role="alert"></div></div></details>
                    <div class="small text-danger mt-2 d-none" data-events-error role="alert"></div>
                  </div>
                </div>
                <div class="col-12 d-flex justify-content-end"><button class="btn btn-success" type="submit">Guardar resultado y acta</button></div>
              </form>
              @endif
            </div></div>
          @endforeach
        </div>
      </details>
    @empty<p class="text-muted mb-0">El fixture todavía no fue generado.</p>@endforelse
  </div>
</div>

<div class="modal fade" id="users-modal" tabindex="-1" aria-labelledby="users-modal-label" aria-hidden="true">
  <div class="modal-dialog modal-dialog-scrollable"><div class="modal-content">
    <div class="modal-header"><h5 class="modal-title" id="users-modal-label">Buscar usuario</h5><button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Cerrar"></button></div>
    <div class="modal-body"><p class="small text-muted" id="users-modal-help">Busca por nickname. Puedes seleccionar varios gestores.</p><input id="user-search" class="form-control mb-3" placeholder="@nickname" autocomplete="off"><div id="user-results" class="vstack gap-2"><div class="small text-muted">Escribe para buscar.</div></div></div>
    <div class="modal-footer"><button type="button" class="btn btn-primary" data-bs-dismiss="modal">Aplicar selección</button></div>
  </div></div>
</div>

<div class="modal fade" id="groups-edit-modal" tabindex="-1" aria-labelledby="groups-edit-label" aria-hidden="true">
  <div class="modal-dialog modal-dialog-scrollable"><div class="modal-content"><form method="post" action="{{ route('admin.championships.groups.update', $championship) }}" id="groups-edit-form">
    @csrf @method('PUT')
    <div class="modal-header"><h5 class="modal-title" id="groups-edit-label">Editar grupos asociados</h5><button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Cerrar"></button></div>
    <div class="modal-body"><input id="group-edit-search" class="form-control mb-3" placeholder="Buscar grupo..." autocomplete="off"><div id="group-edit-results" class="vstack gap-2"><div class="small text-muted">Escribe para buscar.</div></div><div id="group-edit-inputs"></div></div>
    <div class="modal-footer"><span class="small text-muted me-auto" id="group-edit-count">{{ $championship->clubs->count() }} seleccionados</span><button class="btn btn-primary">Guardar grupos</button></div>
  </form></div></div>
</div>

<div class="modal fade" id="delete-championship-modal" tabindex="-1" aria-labelledby="delete-championship-label" aria-hidden="true">
  <div class="modal-dialog"><div class="modal-content"><form method="post" action="{{ route('admin.championships.destroy', $championship) }}">
    @csrf @method('DELETE')
    <div class="modal-header"><h5 class="modal-title text-danger" id="delete-championship-label">Eliminar campeonato</h5><button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Cerrar"></button></div>
    <div class="modal-body"><p>Se eliminarán equipos, fixture, actas, estadísticas, pichangas vinculadas y notificaciones. Los grupos originales no se eliminarán.</p><label class="form-label">Escribe <strong>{{ $championship->name }}</strong> para confirmar</label><input required name="confirmation" class="form-control" autocomplete="off"></div>
    <div class="modal-footer"><button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancelar</button><button class="btn btn-danger">Eliminar definitivamente</button></div>
  </form></div></div>
</div>
@endsection

@push('scripts')
<script>
(() => {
  const modal = document.getElementById('users-modal');
  const search = document.getElementById('user-search');
  const results = document.getElementById('user-results');
  const endpoint = @json(route('admin.championships.users.search'));
  const managers = new Map();
  let mode = 'admins';
  let captain = null;
  let captainTargetTeamId = null;
  function renderSelection() {
    const box = document.getElementById('selected-admins'); const inputs = document.getElementById('admin-inputs');
    box.replaceChildren(); inputs.replaceChildren();
    managers.forEach((user) => { const chip = document.createElement('span'); chip.className = 'badge text-bg-primary'; chip.textContent = '@' + (user.nick || user.name); box.appendChild(chip); const input = document.createElement('input'); input.type='hidden'; input.name='user_ids[]'; input.value=user.id; inputs.appendChild(input); });
    const captainBox = document.getElementById('selected-captain'); if (captain) { captainBox.textContent = '@' + (captain.nick || captain.name); document.getElementById('captain-user-id').value = captain.id; } else { captainBox.textContent = 'Sin capitán'; document.getElementById('captain-user-id').value = ''; }
  }
  function render(items) { results.replaceChildren(); if (!items.length) { results.innerHTML='<div class="small text-muted">No encontramos usuarios.</div>'; return; } items.forEach((user) => { const row=document.createElement('button'); row.type='button'; row.className='btn btn-light border text-start d-flex align-items-center gap-2'; const selected=mode==='admins' ? managers.has(String(user.id)) : captain && String(captain.id)===String(user.id); row.innerHTML=`<span class="rounded-circle bg-secondary-subtle" style="width:36px;height:36px;display:grid;place-items:center;overflow:hidden">${user.avatar_url ? `<img src="${user.avatar_url}" alt="" class="w-100 h-100" style="object-fit:cover">` : '👤'}</span><span class="flex-grow-1"><strong>@${user.nick || user.name || ''}</strong><small class="d-block text-muted">${user.name || ''}</small></span><input class="form-check-input" type="checkbox" ${selected?'checked':''} tabindex="-1">`; row.addEventListener('click',()=>{ if(mode==='admins'){ const key=String(user.id); if(managers.has(key)) managers.delete(key); else managers.set(key,user); renderSelection(); render(items); return; } captain=user; if(captainTargetTeamId){ const input=document.getElementById('captain-team-user-'+captainTargetTeamId); const form=document.getElementById('captain-form-'+captainTargetTeamId); if(input && form){ input.value=user.id; form.submit(); return; } } bootstrap.Modal.getOrCreateInstance(modal).hide(); renderSelection(); render(items); }); results.appendChild(row); }); }
  modal.addEventListener('show.bs.modal', (event) => { mode=event.relatedTarget?.dataset.userMode || 'admins'; captainTargetTeamId=event.relatedTarget?.dataset.teamId || null; document.getElementById('users-modal-label').textContent=mode==='admins'?'Añadir gestores':'Elegir capitán'; document.getElementById('users-modal-help').textContent=mode==='admins'?'Busca por nickname y selecciona varios gestores.':'Busca por nickname y selecciona un capitán.'; search.value=''; results.innerHTML='<div class="small text-muted">Escribe para buscar.</div>'; });
  let timer; search.addEventListener('input',()=>{clearTimeout(timer); const q=search.value.trim(); if(q.length<2){results.innerHTML='<div class="small text-muted">Escribe al menos dos caracteres.</div>';return;} results.innerHTML='<div class="small text-muted">Buscando...</div>'; timer=setTimeout(()=>fetch(`${endpoint}?q=${encodeURIComponent(q)}`,{headers:{Accept:'application/json'}}).then(r=>r.ok?r.json():[]).then(render).catch(()=>{results.innerHTML='<div class="small text-danger">No se pudo buscar.</div>'; }),220);});
  renderSelection();
})();
</script>
<script>
(() => {
  const selected = new Map(@json($championship->clubs->mapWithKeys(fn ($club) => [(string) $club->id => ['id' => $club->id, 'name' => $club->nombre, 'logo_url' => $club->logo_url]])->all()));
  const search = document.getElementById('group-edit-search'); const results = document.getElementById('group-edit-results'); const inputs = document.getElementById('group-edit-inputs'); const count = document.getElementById('group-edit-count'); const endpoint = @json(route('admin.championships.groups.search'));
  function selectedInputs(){ inputs.replaceChildren(); selected.forEach((group)=>{ const input=document.createElement('input'); input.type='hidden'; input.name='club_ids[]'; input.value=group.id; inputs.appendChild(input); }); count.textContent=`${selected.size} seleccionado${selected.size===1?'':'s'}`; }
  function render(items){ results.replaceChildren(); if(!items.length){results.innerHTML='<div class="small text-muted">No encontramos grupos.</div>';return;} items.forEach((group)=>{const row=document.createElement('button');row.type='button';row.className='btn btn-light border text-start d-flex align-items-center gap-2';const key=String(group.id);row.innerHTML=`<span class="flex-grow-1"><strong>${group.name}</strong></span><input class="form-check-input" type="checkbox" ${selected.has(key)?'checked':''} tabindex="-1">`;row.addEventListener('click',()=>{if(selected.has(key))selected.delete(key);else selected.set(key,group);selectedInputs();render(items);});results.appendChild(row);});}
  let timer; search.addEventListener('input',()=>{clearTimeout(timer);const q=search.value.trim();if(q.length<2){results.innerHTML='<div class="small text-muted">Escribe al menos dos caracteres.</div>';return;}results.innerHTML='<div class="small text-muted">Buscando...</div>';timer=setTimeout(()=>fetch(`${endpoint}?q=${encodeURIComponent(q)}`,{headers:{Accept:'application/json'}}).then(r=>r.ok?r.json():[]).then(render).catch(()=>{results.innerHTML='<div class="small text-danger">No se pudo buscar.</div>'; }),220);}); selectedInputs();
})();
</script>
@endpush
