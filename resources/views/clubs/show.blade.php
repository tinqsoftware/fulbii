@extends('fulbii')
@section('title', $club->nombre.' · Club · Fulbii')

@section('content')
@php
  // mapa rápido de promedios por user_id
  $promPorUser = collect($promedios ?? [])->keyBy('user_id');
  function promedio_total($p){
      if(!$p) return null;
      $vals = array_filter([
        $p->fisico_prom ?? null,
        $p->arquero_prom ?? null,
        $p->delantero_prom ?? null,
        $p->mediocampo_prom ?? null,
        $p->defensa_prom ?? null,
      ], fn($v) => $v !== null);
      if(count($vals) === 0) return null;
      return array_sum($vals)/count($vals);
  }
@endphp

<div class="container" style="max-width:1100px; padding:16px 16px 90px;">

  {{-- ENCABEZADO --}}
  <div class="d-flex flex-wrap justify-content-between align-items-start mb-3">
    <div class="pe-3 d-flex align-items-center gap-3">
      @if($club->logo_url)
        <img src="{{ asset('storage/'.$club->logo_url) }}" alt="Logo" class="club-hero-logo">
      @else
        <span class="club-hero-logo club-hero-logo--placeholder">{{ strtoupper(substr($club->nombre,0,1)) }}</span>
      @endif
      <div>
        <h1 class="fw-700" style="font-size:28px; margin:0;">{{ $club->nombre }}</h1>
        <div class="text-muted" style="font-size:13px">{{ $club->descripcion }}</div>
        <div class="mt-1">
          @if($miRol)<span class="badge bg-success-subtle text-success fw-600">{{ strtoupper($miRol) }}</span>@endif
        </div>
      </div>
    </div>

    <div class="d-flex gap-2 mt-2">
      @if($isSuper || $isAdmin)
        <a href="{{ route('clubs.edit',$club) }}" class="btn btn-outline-primary btn-sm">Editar</a>
      @endif
      <a href="{{ route('clubs.index') }}" class="btn btn-outline-secondary btn-sm">Volver</a>
    </div>
  </div>


  {{-- MIEMBROS + ACCIONES --}}
  <div class="d-flex flex-wrap justify-content-between align-items-center mb-2">
    <div class="d-flex align-items-center gap-2">
      <h5 class="fw-700 m-0">Miembros</h5>

      {{-- Toggle Cards / Lista (en móvil siempre cards) --}}
      <div class="btn-group ms-2 d-none d-lg-inline-flex" role="group" aria-label="vista-miembros">
        <button class="btn btn-outline-success btn-sm" data-view="cards" id="btn-view-cards">Cards</button>
        <button class="btn btn-outline-success btn-sm" data-view="list" id="btn-view-list">Lista</button>
      </div>
    </div>

    @if($isSuper || $isAdmin)
      <button type="button" class="btn btn-success btn-sm" id="btn-add-member">
        <i class="ti-plus"></i> Agregar
      </button>
    @endif
  </div>

  {{-- VISTA CARDS (default / móvil) --}}
  <div id="cards-view" class="row row-cols-2 row-cols-md-3 g-3">
    @foreach($miembros as $m)
      @php
        $u = $m->user;
        $p = $promPorUser->get($m->user_id);
        $avg = promedio_total($p);
        $pos = $p->posicion_sugerida ?? '—';
        $nick = $u->nick ?? 'user'.$u->id;
        $ini = strtoupper(substr($nick, 0, 1));
      @endphp
      <div class="col">
        <div class="card shadow-sm h-100 member-card" data-open-jugador
             data-user-id="{{ $u->id }}"
             data-nick="{{ '@'.$nick }}"
             data-name="{{ $u->name ?? '' }}"
             data-pos="{{ $pos }}"
             data-votos="{{ $p->votos ?? 0 }}"
             data-fisico="{{ $p->fisico_prom ?? '' }}"
             data-arquero="{{ $p->arquero_prom ?? '' }}"
             data-delantero="{{ $p->delantero_prom ?? '' }}"
             data-mediocampo="{{ $p->mediocampo_prom ?? '' }}"
             data-defensa="{{ $p->defensa_prom ?? '' }}"
             data-avg="{{ $avg ? number_format($avg,1) : '—' }}"
        >
          <div class="card-body d-flex align-items-center p-2">
            <div class="flex-fill" >
              <div class="avatar me-3">{{ $ini }}</div>
              <div class="fw-600" style="font-size:11px">{{ '@'.$nick }}</div>
            </div>
            <div class="flex-fill">
              
              <div class="fw-600" style="line-height: 1.2; font-size:14px;">{{ $u->name }}</div>
              <div class="text-muted" style="font-size:11px;"><span class="text-success fw-600" style="font-size:12px; color: #23b05f !important;">{{ $pos }}</span></div>
              <div style="font-size:11px">Promedio: <span class="badge badge-pill badge-success" style=" font-size: 16px;"> <b>{{ $avg ? number_format($avg,1) : '—' }}</b></span></div>
              <div style="font-size:11px">Votos: <b>{{ $p->votos ?? 0 }}</b></div>
            </div>
          </div>
        </div>
      </div>
    @endforeach
  </div>

  {{-- VISTA LISTA (solo desktop; conmutada) --}}
  <div id="list-view" class="table-responsive d-none mt-3">
    <table class="table align-middle">
      <thead>
        <tr>
          <th>Pichanguero</th>
          <th>Posición</th>
          <th>Promedio</th>
          <th class="text-center">Rol</th>
          <th class="text-end">Acciones</th>
        </tr>
      </thead>
      <tbody>
      @foreach($miembros as $m)
        @php
          $u = $m->user;
          $p = $promPorUser->get($m->user_id);
          $avg = promedio_total($p);
          $pos = $p->posicion_sugerida ?? '—';
          $nick = $u->nick ?? 'user'.$u->id;
        @endphp
        <tr data-open-jugador
            data-user-id="{{ $u->id }}"
            data-nick="{{ '@'.$nick }}"
            data-name="{{ $u->name ?? '' }}"
            data-pos="{{ $pos }}"
            data-votos="{{ $p->votos ?? 0 }}"
            data-fisico="{{ $p->fisico_prom ?? '' }}"
            data-arquero="{{ $p->arquero_prom ?? '' }}"
            data-delantero="{{ $p->delantero_prom ?? '' }}"
            data-mediocampo="{{ $p->mediocampo_prom ?? '' }}"
            data-defensa="{{ $p->defensa_prom ?? '' }}"
            data-avg="{{ $avg ? number_format($avg,1) : '—' }}"
            style="cursor:pointer"
        >
          <td>{{ '@'.$nick }} — {{ $u->name ?? '—' }}</td>
          <td>{{ $pos }}</td>
          <td>{{ $avg ? number_format($avg,1) : '—' }}</td>
          <td class="text-center">
            <span class="badge {{ $m->rol==='admin' ? 'bg-success' : 'bg-secondary' }}">
              {{ strtoupper($m->rol) }}
            </span>
          </td>
          <td class="text-end">
            @if($isSuper || $isAdmin)
              @if($m->rol!=='admin')
                <form action="{{ route('clubs.miembros.set-admin',[$club,$m->user_id]) }}" method="POST" class="d-inline">
                  @csrf
                  <button class="btn btn-outline-primary btn-sm">Hacer admin</button>
                </form>
              @endif
              <form action="{{ route('clubs.miembros.remover',[$club,$m->user_id]) }}" method="POST"
                    class="d-inline" onsubmit="return confirm('¿Quitar del club?')">
                @csrf @method('DELETE')
                <button class="btn btn-outline-danger btn-sm">Quitar</button>
              </form>
            @endif
          </td>
        </tr>
      @endforeach
      </tbody>
    </table>
  </div>
</div>

{{-- MODAL: AGREGAR MIEMBRO --}}
<div class="modal fade" id="modalAddMember" tabindex="-1" aria-hidden="true">
  <div class="modal-dialog modal-dialog-centered">
    <div class="modal-content">
      <form method="POST" action="{{ route('clubs.miembros.agregar',$club) }}" id="form-add-member">
        @csrf
        <div class="modal-header">
          <h5 class="modal-title">Agregar miembro</h5>
          <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Cerrar"></button>
        </div>
        <div class="modal-body">
          <div class="mb-3 ac-wrap" data-ac>
            <label class="form-label">Buscar pichanguero</label>
            <input type="text" id="ac-input" class="form-control" autocomplete="off"
                   placeholder="Escribe nick, nombre o email">
            <input type="hidden" name="user_id" id="ac-user-id">
            <div class="ac-list" id="ac-list" hidden></div>
          </div>
          <div class="mb-2">
            <label class="form-label">Rol en el club</label>
            <select name="rol" class="form-select" id="ac-rol">
              <option value="miembro">Miembro</option>
              <option value="admin">Admin</option>
            </select>
          </div>
          <div class="text-muted" style="font-size:12px">Solo administradores y superadmins pueden agregar miembros.</div>
        </div>
        <div class="modal-footer">
          <button type="button" class="btn btn-light" data-bs-dismiss="modal">Cancelar</button>
          <button class="btn btn-success" id="ac-submit" disabled>Agregar</button>
        </div>
      </form>
    </div>
  </div>
</div>

{{-- MODAL: DETALLE JUGADOR + CALIFICAR --}}
<div class="modal fade" id="modalJugador" tabindex="-1" aria-hidden="true">
  <div class="modal-dialog modal-dialog-centered modal-lg modal-dialog-scrollable">
    <div class="modal-content">
      <div class="modal-header">
        <h5 class="modal-title" id="jug-title">@nick</h5>
        @auth
          <a href="{{ route('mi-perfil.show') }}" id="btn-manage-self" class="btn btn-outline-primary btn-sm me-2" style="display:none">Gestionar</a>
        @endauth
        <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Cerrar"></button>
      </div>
      <div class="modal-body">
        <div class="row g-3">
          <div class="col-12 col-md-4">
            <div class="p-3 border rounded row">
              <div id="jug-name" class="fw-600 mb-2">—</div>
              <div class="text-muted col-5" style="font-size:14px">Posición sugerida</div>
              <div id="jug-pos" class="fw-600 text-success mb-2 col-7" style="font-size:19px; color: #23b05f !important;">—</div>
              <div class="text-muted col-5" style="font-size:14px">Votos</div>
              <div id="jug-votos" class="mb-2 col-7">0</div>
              <div class="text-muted col-5" style="font-size:14px">Promedio total</div>
              <div class="fw-800 col-7"><span class="badge badge-pill badge-success" style=" font-size: 16px;"> <b id="jug-avg">-</b></span></div>
              <hr>

              <div class="metric">
                <div class="d-flex justify-content-between small"><span>Físico</span><span id="jug-f-val">0.0</span></div>
                <div class="meter"><div id="jug-f-bar" class="fill"></div></div>
              </div>
              <div class="metric">
                <div class="d-flex justify-content-between small"><span>Arquero</span><span id="jug-a-val">0.0</span></div>
                <div class="meter"><div id="jug-a-bar" class="fill"></div></div>
              </div>
              <div class="metric">
                <div class="d-flex justify-content-between small"><span>Delantero</span><span id="jug-d-val">0.0</span></div>
                <div class="meter"><div id="jug-d-bar" class="fill"></div></div>
              </div>
              <div class="metric">
                <div class="d-flex justify-content-between small"><span>Mediocampo</span><span id="jug-m-val">0.0</span></div>
                <div class="meter"><div id="jug-m-bar" class="fill"></div></div>
              </div>
              <div class="metric">
                <div class="d-flex justify-content-between small"><span>Defensa</span><span id="jug-def-val">0.0</span></div>
                <div class="meter"><div id="jug-def-bar" class="fill"></div></div>
              </div>
            </div>
          </div>
          <div class="col-12 col-md-8">
          @if($isMember)
            <div id="cant-rate-msg" class="alert alert-light border d-none"></div>
            <form id="form-calificar" method="POST" action="{{ route('clubs.calificar',$club) }}" class="p-3 border rounded">
              @csrf
              <input type="hidden" name="user_calificado_id" id="cal-user-id">

              <div class="row g-3">
                {{-- Grupo radio bonito (1..5) usando btn-check --}}
                <div class="col-12 col-sm-6">
                  <label class="form-label small d-block">Físico</label>
                  <div class="rate-group">
                    @for($i=1;$i<=5;$i++)
                      <input type="radio" class="btn-check" name="fisico" id="rg-f-{{ $i }}" value="{{ $i }}" required>
                      <label class="btn btn-outline-success btn-sm" for="rg-f-{{ $i }}">{{ $i }}</label>
                    @endfor
                  </div>
                </div>

                <div class="col-12 col-sm-6">
                  <label class="form-label small d-block">Arquero</label>
                  <div class="rate-group">
                    @for($i=1;$i<=5;$i++)
                      <input type="radio" class="btn-check" name="arquero" id="rg-a-{{ $i }}" value="{{ $i }}" required>
                      <label class="btn btn-outline-success btn-sm" for="rg-a-{{ $i }}">{{ $i }}</label>
                    @endfor
                  </div>
                </div>

                <div class="col-12 col-sm-6">
                  <label class="form-label small d-block">Delantero</label>
                  <div class="rate-group">
                    @for($i=1;$i<=5;$i++)
                      <input type="radio" class="btn-check" name="delantero" id="rg-d-{{ $i }}" value="{{ $i }}" required>
                      <label class="btn btn-outline-success btn-sm" for="rg-d-{{ $i }}">{{ $i }}</label>
                    @endfor
                  </div>
                </div>

                <div class="col-12 col-sm-6">
                  <label class="form-label small d-block">Mediocampo</label>
                  <div class="rate-group">
                    @for($i=1;$i<=5;$i++)
                      <input type="radio" class="btn-check" name="mediocampo" id="rg-m-{{ $i }}" value="{{ $i }}" required>
                      <label class="btn btn-outline-success btn-sm" for="rg-m-{{ $i }}">{{ $i }}</label>
                    @endfor
                  </div>
                </div>

                <div class="col-12 col-sm-6">
                  <label class="form-label small d-block">Defensa</label>
                  <div class="rate-group">
                    @for($i=1;$i<=5;$i++)
                      <input type="radio" class="btn-check" name="defensa" id="rg-def-{{ $i }}" value="{{ $i }}" required>
                      <label class="btn btn-outline-success btn-sm" for="rg-def-{{ $i }}">{{ $i }}</label>
                    @endfor
                  </div>
                </div>
              </div>

              <div class="text-muted small mt-2">* Solo una calificación por día por pichanguero (el backend valida esta regla).</div>
              <div class="mt-3 d-flex justify-content-end">
                <button class="btn btn-success">Guardar calificación</button>
              </div>
            </form>
          @else
            <div class="alert alert-light border mt-2">
              Debes <a href="{{ route('login') }}">Iniciar sesión</a> y pertenecer a este club para calificar.
            </div>
          @endif
          </div>
        </div>

        <hr>
        <div id="historial" class="mt-2"></div>
      </div>
    </div>
  </div>
</div>

<style>
  .club-hero-logo{ width:96px; height:96px; border-radius:20px; object-fit:cover; background:#e9f8ee; border:2px solid #5fb48b; box-shadow:0 10px 24px rgba(16,24,40,.10); }
  .club-hero-logo--placeholder{ display:grid; place-items:center; font-weight:800; color:#1a7a43; }
  @media(min-width:992px){ .club-hero-logo{ width:120px; height:120px; } }
  /* Autocomplete y UI */
  .ac-wrap{ position:relative; }
  .ac-list{
    position:absolute; top:100%; left:0; right:0;
    background:#fff; border:1px solid #e5e7eb; border-radius:8px;
    box-shadow:0 10px 30px rgba(0,0,0,.08);
    max-height:240px; overflow:auto; z-index:1056; /* sobre modal */
  }
  .ac-item{ padding:8px 10px; display:flex; gap:10px; align-items:center; cursor:pointer; }
  .ac-item:hover{ background:#f3f4f6; }
  .ac-nick{ font-weight:700; color:#1a7a43; }
  .ac-name{ font-size:12px; color:#6b7280; }
  .avatar{
    width:42px; height:42px; border-radius:50%;
    display:grid; place-items:center; font-weight:800; color:#1a7a43;
    background:#e9f8ee; border:2px solid #5fb48b;
  }
  .member-card:hover{ box-shadow:0 10px 30px rgba(16,24,40,.10); }
  .rate-group{ display:flex; gap:6px; flex-wrap:wrap; }
  .rate-group .btn{ min-width:36px; padding:4px 8px; }

  .metric{ margin-bottom:10px; }
  .meter{
    height:8px; background:#eef2f7; border-radius:999px; overflow:hidden;
    box-shadow: inset 0 0 0 1px #e5e7eb;
  }
  .meter .fill{
    height:100%; width:0%; background:#1a7a43; transition:width .35s ease;
  }

  @media (max-width: 991px){
    .modal-dialog.modal-dialog-scrollable{ height: 90vh; }
  }
  .modal-dialog.modal-dialog-scrollable .modal-body{
    overflow-y:auto;
    -webkit-overflow-scrolling:touch;
    max-height:75vh;
  }
</style>
@endsection

@push('scripts')
{{-- Bootstrap (si tu layout ya lo incluye, puedes quitar esta línea) --}}
<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js"></script>
<script>
(function(){
  const CSRF = '{{ csrf_token() }}';
  const ME_ID = {{ auth()->id() ?? 'null' }};
  const historyBase = "{{ route('clubs.calificaciones.history', [$club, 0]) }}"; // replace trailing /0 with /:uid
  const canRateBase = "{{ route('clubs.can-rate', [$club, 0]) }}"; // reemplazar /0 por /:uid
  const isMobile = window.matchMedia('(max-width: 991px)'); // <992 => cards
  const viewKey = 'clubMembersView:{{ $club->id }}';
  const $cards = document.getElementById('cards-view');
  const $list  = document.getElementById('list-view');
  const btnCards = document.getElementById('btn-view-cards');
  const btnList  = document.getElementById('btn-view-list');

  function applyView(v){
    if(isMobile.matches){ // móvil: forzar cards
      $cards.classList.remove('d-none');
      $list.classList.add('d-none');
      btnCards?.classList.add('btn-success','text-white');
      btnList?.classList.remove('btn-success','text-white');
      return;
    }
    if(v === 'list'){
      $cards.classList.add('d-none');
      $list.classList.remove('d-none');
      btnList?.classList.add('btn-success','text-white');
      btnCards?.classList.remove('btn-success','text-white');
    }else{
      $cards.classList.remove('d-none');
      $list.classList.add('d-none');
      btnCards?.classList.add('btn-success','text-white');
      btnList?.classList.remove('btn-success','text-white');
    }
  }

  // init view
  let cur = localStorage.getItem(viewKey) || 'cards';
  applyView(cur);
  isMobile.addEventListener('change', ()=> applyView(localStorage.getItem(viewKey) || 'cards'));
  btnCards?.addEventListener('click', ()=>{ localStorage.setItem(viewKey,'cards'); applyView('cards'); });
  btnList?.addEventListener('click', ()=>{ localStorage.setItem(viewKey,'list');  applyView('list'); });

  // Modal Agregar miembro
  const addBtn = document.getElementById('btn-add-member');
  const modalAdd = new bootstrap.Modal(document.getElementById('modalAddMember'));
  addBtn?.addEventListener('click', ()=> modalAdd.show());

  // Autocomplete para agregar
  const $in  = document.getElementById('ac-input');
  const $id  = document.getElementById('ac-user-id');
  const $btn = document.getElementById('ac-submit');
  const $lst = document.getElementById('ac-list');
  const fetchUrl = "{{ route('users.search') }}?club_id={{ $club->id }}";
  let controller = null;

  function clearList(){ if($lst){ $lst.innerHTML=''; $lst.hidden = true; } }
  function enableBtn(){ if($btn){ $btn.disabled = ($id.value===''); } }

  $in?.addEventListener('input', async (e)=>{
    const q = e.target.value.trim();
    $id.value = '';
    enableBtn();
    if (q.length < 2) { clearList(); return; }
    if (controller) controller.abort();
    controller = new AbortController();
    try{
      const res = await fetch(fetchUrl + '&q=' + encodeURIComponent(q), {
        signal: controller.signal,
        headers: { 'X-Requested-With': 'XMLHttpRequest' }
      });
      if(!res.ok) throw new Error('HTTP ' + res.status);
      const data = await res.json();
      renderAC(data);
    }catch(err){ if(err.name !== 'AbortError') console.warn(err); }
  });

  function renderAC(items){
    clearList();
    if(!Array.isArray(items) || items.length === 0) return;
    items.forEach(u=>{
      const row = document.createElement('div');
      row.className = 'ac-item';
      row.innerHTML = `
        <div class="ac-nick">@${u.nick ?? '—'}</div>
        <div class="ac-name">${u.name ?? ''} · ${u.email ?? ''}</div>
      `;
      row.addEventListener('click', ()=>{
        $in.value = u.nick ? '@' + u.nick : (u.name || u.email || ('ID ' + u.id));
        $id.value = u.id;
        enableBtn();
        clearList();
      });
      $lst.appendChild(row);
    });
    $lst.hidden = false;
  }
  document.addEventListener('click', (e)=>{ if(!e.target.closest('[data-ac]')) clearList(); });

  // Envío del formulario de agregar (AJAX + reload)
  document.getElementById('form-add-member')?.addEventListener('submit', async (e)=>{
    e.preventDefault();
    const form = e.target;
    const fd = new FormData(form);
    const res = await fetch(form.action, {
      method:'POST',
      headers:{ 'X-CSRF-TOKEN': CSRF, 'X-Requested-With':'XMLHttpRequest' },
      body: fd
    });
    if(res.ok){
      bootstrap.Modal.getInstance(document.getElementById('modalAddMember'))?.hide();
      location.reload();
    }else{
      alert('No se pudo agregar. Verifica permisos o datos.');
    }
  });

  // Modal Jugador (detalle + calificar)
  const modalJugador = new bootstrap.Modal(document.getElementById('modalJugador'));
  function setText(id, val){ const el=document.getElementById(id); if(el) el.textContent = (val ?? '—'); }

  function openJugador(row){
    setText('jug-title', row.dataset.nick);
    setText('jug-name', row.dataset.name);
    setText('jug-pos',  row.dataset.pos);
    setText('jug-votos',row.dataset.votos);
    setText('jug-avg',  row.dataset.avg);
    function setMetric(code, val){
      val = Number(val || 0);
      const pct = Math.max(0, Math.min(100, (val/5)*100));
      const valEl = document.getElementById('jug-' + code + '-val');
      const barEl = document.getElementById('jug-' + code + '-bar');
      if(valEl) valEl.textContent = val.toFixed(1);
      if(barEl) barEl.style.width = pct + '%';
    }
    setMetric('f',   row.dataset.fisico);
    setMetric('a',   row.dataset.arquero);
    setMetric('d',   row.dataset.delantero);
    setMetric('m',   row.dataset.mediocampo);
    setMetric('def', row.dataset.defensa);
    const uid = row.dataset.userId;
    const idInput = document.getElementById('cal-user-id'); if(idInput) idInput.value = uid;

    checkCanRate(uid);

    // Mostrar/ocultar botón Gestionar
    const btnManage = document.getElementById('btn-manage-self');
    if(btnManage){
      if(ME_ID && Number(uid) === Number(ME_ID)) { btnManage.style.display = ''; }
      else { btnManage.style.display = 'none'; }
    }

    // Cargar historial
    loadHistorial(uid);

    modalJugador.show();
  }
  async function loadHistorial(uid){
    const box = document.getElementById('historial');
    if(!box) return;
    box.innerHTML = '<div class="text-muted small">Cargando historial…</div>';
    const url = historyBase.replace(/\/0$/, '/' + uid);
    try{
      const res = await fetch(url, { headers:{ 'X-Requested-With':'XMLHttpRequest' }});
      if(!res.ok){ box.innerHTML = '<div class="text-muted small">No se pudo cargar el historial.</div>'; return; }
      const data = await res.json();
      if(!Array.isArray(data) || data.length === 0){
        box.innerHTML = '<div class="text-muted small">Aún no hay calificaciones.</div>';
        return;
      }
      let html = '';
      data.forEach(it=>{
        const fecha = new Date(it.created_at).toLocaleDateString();
        const quien = (it.calificador?.nick ? '@'+it.calificador.nick+' · ' : '') + (it.calificador?.name || '');
        const det = `Físico: ${it.fisico} · Arq: ${it.arquero} · Del: ${it.delantero} · Med: ${it.mediocampo} · Def: ${it.defensa}`;
        html += `
          <div class="border rounded p-2 mb-2 small">
            <div class="d-flex justify-content-between">
              <div></div>
              <div class="text-muted">${fecha}</div>
            </div>
            <div>${det}</div>
            ${it.comentario ? `<div class="text-muted">${it.comentario}</div>` : ''}
          </div>
        `;
      });
      box.innerHTML = html;
    }catch(e){
      box.innerHTML = '<div class="text-muted small">No se pudo cargar el historial.</div>';
    }
  }

  function toggleRateUI(allow, reason){
    const form = document.getElementById('form-calificar');
    const msg  = document.getElementById('cant-rate-msg');
    const need = document.getElementById('need-login-msg');

    if (allow) {
      form?.classList.remove('d-none');
      msg?.classList.add('d-none');
      need?.classList.add('d-none');
      return;
    }

    let text = 'No puedes calificar en este momento.';
    if (reason === 'auth'){ text = 'Debes iniciar sesión para calificar.'; need?.classList.remove('d-none'); }
    else if (reason === 'no-member'){ text = 'Debes pertenecer a este club para calificar.'; }
    else if (reason === 'self-exists'){ text = 'Ya te calificaste pichanguero.'; }
    else if (reason === 'already-today'){ text = 'Ya calificaste hoy a este pichanguero.'; }

    form?.classList.add('d-none');
    if (msg){ msg.textContent = text; msg.classList.remove('d-none'); }
  }

  async function checkCanRate(uid){
    const url = canRateBase.replace(/\/0$/, '/' + uid);
    try{
      const res = await fetch(url, { headers:{ 'X-Requested-With':'XMLHttpRequest' }});
      if(!res.ok){ toggleRateUI(false, 'auth'); return; }
      const data = await res.json();
      toggleRateUI(!!data.allow, data.reason);
    }catch(e){
      toggleRateUI(false, 'auth');
    }
  }

  document.querySelectorAll('[data-open-jugador]').forEach(el=>{
    el.addEventListener('click', ()=> openJugador(el));
  });

  // Envío de calificación (con bloqueo suave por día en localStorage)
  document.getElementById('form-calificar')?.addEventListener('submit', async (e)=>{
    e.preventDefault();
    const form = e.target;
    const uid = document.getElementById('cal-user-id').value;
    const todayKey = 'rated:{{ $club->id }}:' + uid + ':' + (new Date()).toISOString().slice(0,10);

    const fd = new FormData(form);
    const res = await fetch(form.action, {
      method:'POST',
      headers:{ 'X-CSRF-TOKEN': CSRF, 'X-Requested-With':'XMLHttpRequest' },
      body: fd
    });
    if(res.ok){
      localStorage.setItem(todayKey, '1');
      bootstrap.Modal.getInstance(document.getElementById('modalJugador'))?.hide();
      location.reload();
    }else{
      const msg = await res.text();
      alert('No se pudo guardar la calificación.\n' + msg);
    }
  });
})();
</script>
@endpush