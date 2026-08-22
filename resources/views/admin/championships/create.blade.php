@extends('layouts.app')

@section('content')
<div class="container">
  <h3 class="mb-3">Crear campeonato</h3>
  @include('admin.partials.nav')
  @if($errors->any())
    <div class="alert alert-danger"><strong>Revisa el formulario.</strong><ul class="mb-0">@foreach($errors->all() as $error)<li>{{ $error }}</li>@endforeach</ul></div>
  @endif
  <form method="post" action="{{ route('admin.championships.store') }}" class="card card-body" id="championship-create-form">
    @csrf
    <div class="row g-3">
      <div class="col-md-8"><label class="form-label">Nombre</label><input required name="name" value="{{ old('name') }}" class="form-control"></div>
      <div class="col-md-4"><label class="form-label">Visibilidad</label><select name="visibility" class="form-select"><option value="public">Público</option><option value="private" @selected(old('visibility') === 'private')>Privado</option><option value="link" @selected(old('visibility') === 'link')>Solo con enlace</option></select></div>
      <div class="col-12">
        <div class="d-flex justify-content-between align-items-center mb-1"><label class="form-label mb-0">Grupos asociados</label><button type="button" class="btn btn-outline-primary btn-sm" data-bs-toggle="modal" data-bs-target="#groups-modal">Añadir grupos</button></div>
        <div id="selected-groups" class="d-flex flex-wrap gap-2 p-2 border rounded bg-light"><span class="text-muted small" id="groups-empty">Selecciona uno o varios grupos para notificar a sus integrantes.</span></div>
        <div id="group-inputs"></div>
      </div>
      <div class="col-md-4"><label class="form-label">Formato</label><select name="format" class="form-select"><option value="league">Liga por puntos</option><option value="knockout">Llaves de eliminación</option><option value="hybrid">Liga + playoffs (base)</option></select></div>
      <div class="col-12"><label class="form-label">Descripción</label><textarea name="description" rows="3" class="form-control">{{ old('description') }}</textarea></div>
      <div class="col-md-3"><label class="form-label">Puntos victoria</label><input type="number" min="0" max="100" name="points_win" value="{{ old('points_win', 3) }}" class="form-control"></div>
      <div class="col-md-3"><label class="form-label">Puntos empate</label><input type="number" min="0" max="100" name="points_draw" value="{{ old('points_draw', 1) }}" class="form-control"></div>
      <div class="col-md-3"><label class="form-label">Puntos derrota</label><input type="number" min="0" max="100" name="points_loss" value="{{ old('points_loss', 0) }}" class="form-control"></div>
      <div class="col-md-3"><label class="form-label">Máx. equipos</label><input type="number" min="2" max="32" name="max_teams" value="{{ old('max_teams', 8) }}" class="form-control"></div>
      <div class="col-md-4"><label class="form-label">Jugadores por partido</label><input type="number" min="5" max="11" name="players_per_team" value="{{ old('players_per_team', 7) }}" class="form-control"></div>
      <div class="col-md-8"><label class="form-label">Sede principal (opcional)</label><select name="field_id" class="form-select"><option value="">Elegir sede al programar cada partido</option>@foreach($venues as $venue)<option value="{{ $venue->id }}" @selected(old('field_id') == $venue->id)>{{ $venue->nombre }}{{ $venue->direccion ? ' · '.$venue->direccion : '' }}</option>@endforeach</select><div class="form-text">Cada partido podrá usar una cancha concreta de esta sede o de otra.</div></div>
      <div class="col-md-8 d-flex align-items-end"><div class="form-check"><input class="form-check-input" type="checkbox" name="double_round_robin" value="1" id="double_round_robin"><label class="form-check-label" for="double_round_robin">Ida y vuelta</label></div></div>
    </div>
    <div class="mt-4 d-flex gap-2"><button class="btn btn-primary">Crear borrador</button><a href="{{ route('admin.championships.index') }}" class="btn btn-outline-secondary">Cancelar</a></div>
  </form>
</div>

<div class="modal fade" id="groups-modal" tabindex="-1" aria-labelledby="groups-modal-label" aria-hidden="true">
  <div class="modal-dialog modal-dialog-scrollable"><div class="modal-content">
    <div class="modal-header"><h5 class="modal-title" id="groups-modal-label">Añadir grupos</h5><button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Cerrar"></button></div>
    <div class="modal-body">
      <p class="small text-muted">Busca por nombre y marca varios grupos. Las selecciones se conservan mientras buscas.</p>
      <input id="group-search" class="form-control mb-3" placeholder="Buscar grupo..." autocomplete="off">
      <div id="group-results" class="vstack gap-2"><div class="text-muted small">Escribe para buscar.</div></div>
    </div>
    <div class="modal-footer"><span class="small text-muted me-auto" id="group-selection-count">0 seleccionados</span><button type="button" class="btn btn-primary" data-bs-dismiss="modal">Listo</button></div>
  </div></div>
</div>
@endsection

@push('scripts')
<script>
(() => {
  const selected = new Map();
  const results = document.getElementById('group-results');
  const search = document.getElementById('group-search');
  const selectedBox = document.getElementById('selected-groups');
  const inputs = document.getElementById('group-inputs');
  const empty = document.getElementById('groups-empty');
  const count = document.getElementById('group-selection-count');
  const endpoint = @json(route('admin.championships.groups.search'));

  function renderSelected() {
    selectedBox.querySelectorAll('[data-selected-group]').forEach((el) => el.remove());
    inputs.replaceChildren();
    empty.classList.toggle('d-none', selected.size > 0);
    selected.forEach((group) => {
      const chip = document.createElement('span');
      chip.dataset.selectedGroup = group.id;
      chip.className = 'badge text-bg-success d-inline-flex align-items-center gap-1';
      chip.innerHTML = `${group.name} <button type="button" class="btn-close btn-close-white" aria-label="Quitar ${group.name}"></button>`;
      chip.querySelector('button').addEventListener('click', () => { selected.delete(String(group.id)); renderSelected(); renderResults(); });
      selectedBox.appendChild(chip);
      const input = document.createElement('input'); input.type = 'hidden'; input.name = 'club_ids[]'; input.value = group.id; inputs.appendChild(input);
    });
    count.textContent = `${selected.size} seleccionado${selected.size === 1 ? '' : 's'}`;
  }

  function renderResults(items) {
    results.replaceChildren();
    if (!items.length) { results.innerHTML = '<div class="text-muted small">No encontramos grupos.</div>'; return; }
    items.forEach((group) => {
      const row = document.createElement('button'); row.type = 'button'; row.className = 'btn btn-light border text-start d-flex align-items-center gap-2';
      const checked = selected.has(String(group.id));
      row.innerHTML = `<span class="rounded-circle bg-secondary-subtle p-1" style="width:36px;height:36px;display:grid;place-items:center">${group.logo_url ? `<img src="${group.logo_url}" alt="" class="rounded-circle w-100 h-100" style="object-fit:cover">` : '⚽'}</span><span class="flex-grow-1"><strong>${group.name}</strong><small class="d-block text-muted">${group.is_visible ? 'Grupo visible' : 'Grupo privado'}</small></span><span class="form-check"><input class="form-check-input" type="checkbox" ${checked ? 'checked' : ''} tabindex="-1"></span>`;
      row.addEventListener('click', () => { const key = String(group.id); if (selected.has(key)) selected.delete(key); else selected.set(key, group); renderSelected(); renderResults(items); });
      results.appendChild(row);
    });
  }

  let timer;
  search.addEventListener('input', () => {
    clearTimeout(timer); const q = search.value.trim();
    if (q.length < 2) { results.innerHTML = '<div class="text-muted small">Escribe al menos dos caracteres.</div>'; return; }
    results.innerHTML = '<div class="text-muted small">Buscando...</div>';
    timer = setTimeout(() => fetch(`${endpoint}?q=${encodeURIComponent(q)}`, {headers: {'Accept': 'application/json'}}).then((res) => res.ok ? res.json() : []).then(renderResults).catch(() => { results.innerHTML = '<div class="text-danger small">No se pudo buscar. Inténtalo nuevamente.</div>'; }), 220);
  });
  renderSelected();
})();
</script>
@endpush
