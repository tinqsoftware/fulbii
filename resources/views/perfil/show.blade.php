@extends('fulbii')
@section('title','Mi perfil · Fulbii')

@section('content')
<div class="container" style="max-width:1100px; padding:16px 16px 90px;">
  @if(session('ok'))
    <div class="alert alert-success">{{ session('ok') }}</div>
  @endif
  @if($errors->any())
    <div class="alert alert-danger">
      @foreach($errors->all() as $e) <div>{{ $e }}</div> @endforeach
    </div>
  @endif

  {{-- Header perfil --}}
  <div class="card shadow-sm mb-3">
    <div class="card-body d-flex flex-wrap align-items-center gap-3">
      @php
        $nick = $u->nick ?? ('user'.$u->id);
        $ini = strtoupper(substr($nick, 0, 1));
      @endphp
      <div class="flex-fill">
        <div class="d-flex flex-wrap align-items-center gap-2">
          <h2 class="m-0 fw-800" style="font-size:22px">{{ $u->name }}</h2>
          <span class="badge bg-success-subtle text-success fw-600"><?php echo "@".$nick?></span>
        </div>
        <div class="text-muted">{{ $u->email }}</div>
      </div>
      <div class="d-flex flex-wrap gap-2">
        <button class="btn btn-outline-success btn-sm" data-bs-toggle="modal" data-bs-target="#modalNick"><i class="ti-pencil"></i> Editar nick</button>
        <button class="btn btn-outline-secondary btn-sm" data-bs-toggle="modal" data-bs-target="#modalEmail"><i class="ti-email"></i> Editar correo</button>
        <button class="btn btn-outline-dark btn-sm" data-bs-toggle="modal" data-bs-target="#modalPass"><i class="ti-key"></i> Editar contraseña</button>
        <form action="{{ route('logout') }}" method="POST" class="d-inline"> @csrf
          <button class="btn btn-danger btn-sm"><i class="ti-shift-right"></i> Cerrar sesión</button>
        </form>
      </div>
    </div>
  </div>

  {{-- Datos personales (nombre editable) + Clubs --}}
  <div class="row g-3 mb-3">
    <div class="col-12 col-lg-6">
      <div class="card shadow-sm h-100">
        <div class="card-body">
          <h5 class="fw-700 mb-3">Datos personales</h5>
          <form method="POST" action="{{ route('mi-perfil.update') }}">
            @csrf
            <div class="mb-3">
              <label class="form-label small fw-600">Nombre completo</label>
              <input class="form-control" name="name" value="{{ $u->name }}" required>
            </div>
            <!-- El correo se edita en su propio modal -->
            <input type="hidden" name="email" value="{{ $u->email }}">
            <button class="btn btn-success">Guardar cambios</button>
          </form>
        </div>
      </div>
    </div>
    <div class="col-12 col-lg-6">
      <div class="card shadow-sm h-100">
        <div class="card-body">
          <h5 class="fw-700 mb-3">Mis clubs</h5>
          @if($clubs->isEmpty())
            <div class="text-muted small">Aún no perteneces a ningún club.</div>
          @else
            <ul class="list-unstyled m-0">
            @foreach($clubs as $c)
              <li class="mb-2">
                <a href="{{ route('clubs.show',$c) }}" class="d-flex align-items-center text-decoration-none">
                  <span class="club-dot me-2"></span>
                  <span class="fw-600">{{ $c->nombre }}</span>
                  <span class="text-muted small ms-2">{{ $c->descripcion }}</span>
                </a>
              </li>
            @endforeach
            </ul>
          @endif
        </div>
      </div>
    </div>
  </div>

  {{-- Promedios en barras (global) --}}
  <div class="card shadow-sm mb-3">
    <div class="card-body">
      <h5 class="fw-700 mb-2">Mi promedio global</h5>
      <div class="text-muted small mb-2">Basado en {{ $global['votos'] ?? 0 }} votos.</div>

      @php
        $metrics = [
          ['label' => 'Físico', 'key' => 'fisico'],
          ['label' => 'Arquero', 'key' => 'arquero'],
          ['label' => 'Delantero', 'key' => 'delantero'],
          ['label' => 'Mediocampo', 'key' => 'mediocampo'],
          ['label' => 'Defensa', 'key' => 'defensa'],
        ];
      @endphp

      <div class="row g-3">
      @foreach($metrics as $m)
        @php
          $val = $global[$m['key']] ?? null;
          $pct = $val !== null ? max(0,min(100,($val/5)*100)) : 0;
        @endphp
        <div class="col-12 col-md-6">
          <div class="d-flex justify-content-between small">
            <span>{{ $m['label'] }}</span>
            <span>{{ $val !== null ? number_format($val,1) : '—' }}</span>
          </div>
          <div class="meter"><div class="fill" style="width: {{ $pct }}%"></div></div>
        </div>
      @endforeach
      </div>

      <hr>
      <div class="d-flex justify-content-between">
        <div class="fw-700">Promedio total</div>
        <div class="fw-800">{{ $global['promedio'] !== null ? number_format($global['promedio'],1) : '—' }}</div>
      </div>
    </div>
  </div>

  {{-- Calificaciones (tabs) --}}
  <div class="card shadow-sm">
    <div class="card-body">
      <ul class="nav nav-pills mb-3" id="pills-tab" role="tablist">
        <li class="nav-item" role="presentation">
          <button class="nav-link active" id="pills-publicas-tab" data-bs-toggle="pill" data-bs-target="#pills-publicas" type="button" role="tab">Calificaciones recibidas</button>
        </li>
      </ul>
      <div class="tab-content">
        <div class="tab-pane fade show active" id="pills-publicas" role="tabpanel" style="background-color:white !important; color:black !important;">
          @if(!$miAuto)
            <button type="button" class="btn btn-success btn-sm mb-3" data-open-auto>
              <i class="ti-plus"></i> Añade tu calificación
            </button>
          @endif
          @if($recibidasPublicas->isEmpty())
            <div class="text-muted small">Aún no tienes calificaciones.</div>
          @else
            @foreach($recibidasPublicas as $c)
              <div class="border rounded p-2 mb-2 small">
                <div class="d-flex justify-content-between">
                  <div>
                    @if($c->user_calificador_id !== $u->id) @else
                      <button type="button"
                              class="btn btn-outline-primary btn-sm mt-1"
                              data-open-auto
                              data-id="{{ $c->id }}"
                              data-fisico="{{ $c->fisico }}"
                              data-arquero="{{ $c->arquero }}"
                              data-delantero="{{ $c->delantero }}"
                              data-mediocampo="{{ $c->mediocampo }}"
                              data-defensa="{{ $c->defensa }}">
                        <i class="ti-pencil"></i> Editar mi calificación
                      </button>
                    @endif
                  </div>
                  <div class="text-muted">{{ $c->created_at?->format('d/m/Y') }}</div>
                </div>
                <div>Fís: {{ $c->fisico }} · Arq: {{ $c->arquero }} · Del: {{ $c->delantero }} · Med: {{ $c->mediocampo }} · Def: {{ $c->defensa }}</div>
                
              </div>
            @endforeach
          @endif
        </div>

      </div>
    </div>
  </div>
</div>

{{-- Modals --}}
<div class="modal fade" id="modalNick" tabindex="-1" aria-hidden="true">
  <div class="modal-dialog modal-dialog-centered">
    <form class="modal-content" method="POST" action="{{ route('mi-perfil.nick') }}" id="formNick">
      @csrf
      <div class="modal-header">
        <h5 class="modal-title">Editar nick</h5>
        <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Cerrar"></button>
      </div>
      <div class="modal-body">
        <label class="form-label small">Nuevo nick</label>
        <div class="input-group">
          <span class="input-group-text">@</span>
          <input type="text" class="form-control" id="newNick" name="nick" placeholder="tunay" required>
        </div>
        <div id="nickHelp" class="form-text">Usa 3–20 caracteres (letras, números, - o _).</div>
      </div>
      <div class="modal-footer">
        <button type="button" class="btn btn-light" data-bs-dismiss="modal">Cancelar</button>
        <button class="btn btn-success" id="btnNickSave" disabled>Guardar</button>
      </div>
    </form>
  </div>
</div>

<div class="modal fade" id="modalEmail" tabindex="-1" aria-hidden="true">
  <div class="modal-dialog modal-dialog-centered">
    <form class="modal-content" method="POST" action="{{ route('mi-perfil.email') }}" id="formEmail">
      @csrf
      <div class="modal-header">
        <h5 class="modal-title">Editar correo</h5>
        <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Cerrar"></button>
      </div>
      <div class="modal-body">
        <label class="form-label small">Nuevo correo</label>
        <input type="email" class="form-control mb-2" id="email1" placeholder="tucorreo@ejemplo.com" required>
        <label class="form-label small">Confirma tu correo</label>
        <input type="email" class="form-control" id="email2" name="email" required>
        <div id="emailHelp" class="form-text"></div>
      </div>
      <div class="modal-footer">
        <button type="button" class="btn btn-light" data-bs-dismiss="modal">Cancelar</button>
        <button class="btn btn-success" id="btnEmailSave" disabled>Guardar</button>
      </div>
    </form>
  </div>
</div>

<div class="modal fade" id="modalPass" tabindex="-1" aria-hidden="true">
  <div class="modal-dialog modal-dialog-centered">
    <form class="modal-content" method="POST" action="{{ route('mi-perfil.password') }}" id="formPass">
      @csrf
      <div class="modal-header">
        <h5 class="modal-title">Editar contraseña</h5>
        <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Cerrar"></button>
      </div>
      <div class="modal-body">
        <label class="form-label small">Nueva contraseña</label>
        <input type="password" class="form-control mb-2" id="pass1" name="password" minlength="8" required>
        <label class="form-label small">Confirma tu contraseña</label>
        <input type="password" class="form-control" id="pass2" name="password_confirmation" minlength="8" required>
        <div id="passHelp" class="form-text"></div>
      </div>
      <div class="modal-footer">
        <button type="button" class="btn btn-light" data-bs-dismiss="modal">Cancelar</button>
        <button class="btn btn-success" id="btnPassSave" disabled>Guardar</button>
      </div>
    </form>
  </div>
 </div>

<div class="modal fade" id="modalAuto" tabindex="-1" aria-hidden="true">
  <div class="modal-dialog modal-dialog-centered">
    <form class="modal-content" method="POST" action="{{ route('mi-perfil.autocalificacion') }}" id="formAuto">
      @csrf
      <input type="hidden" name="id" id="auto-id">
      <div class="modal-header">
        <h5 class="modal-title">Mi calificación</h5>
        <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Cerrar"></button>
      </div>
      <div class="modal-body">
        <div class="row g-3">
          @foreach(['fisico'=>'Físico','arquero'=>'Arquero','delantero'=>'Delantero','mediocampo'=>'Mediocampo','defensa'=>'Defensa'] as $k=>$label)
            <div class="col-12">
              <label class="form-label small d-block">{{ $label }}</label>
              <div class="rate-group">
                @for($i=1;$i<=5;$i++)
                  <input type="radio" class="btn-check" name="{{ $k }}" id="auto-{{ $k }}-{{ $i }}" value="{{ $i }}" required>
                  <label class="btn btn-outline-success btn-sm" for="auto-{{ $k }}-{{ $i }}">{{ $i }}</label>
                @endfor
              </div>
            </div>
          @endforeach
        </div>
      </div>
      <div class="modal-footer">
        <button type="button" class="btn btn-light" data-bs-dismiss="modal">Cancelar</button>
        <button class="btn btn-success">Guardar</button>
      </div>
    </form>
  </div>
</div>

@endsection

@push('styles')
<style>
  .avatar-lg{
    width:64px; height:64px; border-radius:50%;
    display:grid; place-items:center; font-weight:800; color:#1a7a43;
    background:#e9f8ee; border:2px solid #5fb48b;
    font-size:24px;
  }
  .club-dot{ width:10px; height:10px; border-radius:50%; background:#1a7a43; display:inline-block }
  .meter{ height:10px; background:#eef2f7; border-radius:999px; overflow:hidden; box-shadow: inset 0 0 0 1px #e5e7eb; }
  .meter .fill{ height:100%; width:0%; background:#1a7a43; transition:width .35s ease; }
  .rate-group{ display:flex; gap:6px; flex-wrap:wrap; }
  .rate-group .btn{ min-width:36px; padding:4px 8px; }
</style>
@endpush

@push('scripts')
<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js"></script>
<script>
(function(){
  // --- Nick availability ---
  const nickInput = document.getElementById('newNick');
  const nickHelp  = document.getElementById('nickHelp');
  const btnNick   = document.getElementById('btnNickSave');
  let nickTimer = null;

  function setNickState(ok, msg){
    if(!nickInput) return;
    nickInput.classList.toggle('is-valid', !!ok);
    nickInput.classList.toggle('is-invalid', ok === false);
    btnNick.disabled = !ok;
    if(nickHelp) nickHelp.textContent = msg || (ok ? 'Disponible' : 'No disponible');
  }

  nickInput?.addEventListener('input', ()=>{
    const val = nickInput.value.trim();
    btnNick.disabled = true;
    nickInput.classList.remove('is-valid','is-invalid');
    if(nickTimer) clearTimeout(nickTimer);
    if(val.length < 3){ setNickState(false, 'Usa 3–20 caracteres (letras, números, - o _)'); return; }
    nickTimer = setTimeout(async ()=>{
      try{
        const res = await fetch(`{{ route('nick.available') }}?nick=${encodeURIComponent(val)}`, { headers:{'X-Requested-With':'XMLHttpRequest'} });
        const data = await res.json();
        setNickState(!!(data.valid && data.available), data.message || (data.available ? 'Disponible' : 'No disponible'));
      }catch(_){ setNickState(false, 'Error verificando disponibilidad'); }
    }, 300);
  });

  // Reset al abrir/cerrar modal
  document.getElementById('modalNick')?.addEventListener('shown.bs.modal', ()=>{ nickInput?.focus(); setNickState(false,'Usa 3–20 caracteres (letras, números, - o _)'); });
  document.getElementById('modalNick')?.addEventListener('hidden.bs.modal', ()=>{ if(nickInput){ nickInput.value=''; nickInput.classList.remove('is-valid','is-invalid'); } if(nickHelp){ nickHelp.textContent='Usa 3–20 caracteres (letras, números, - o _).'; } btnNick.disabled=true; });

  // --- Email double entry ---
  const e1 = document.getElementById('email1');
  const e2 = document.getElementById('email2');
  const btnEmail = document.getElementById('btnEmailSave');
  const emailHelp = document.getElementById('emailHelp');

  function validateEmail(){
    const v1 = e1.value.trim();
    const v2 = e2.value.trim();
    const same = v1 !== '' && v1 === v2;
    const looks = /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(v1);
    btnEmail.disabled = !(same && looks);
    emailHelp.textContent = same ? (looks ? 'Correcto' : 'Formato inválido') : 'Los correos no coinciden';
    e1.classList.toggle('is-valid', same && looks);
    e2.classList.toggle('is-valid', same && looks);
    e1.classList.toggle('is-invalid', !same || !looks);
    e2.classList.toggle('is-invalid', !same || !looks);
  }
  e1?.addEventListener('input', validateEmail);
  e2?.addEventListener('input', validateEmail);
  document.getElementById('modalEmail')?.addEventListener('hidden.bs.modal', ()=>{
    if(e1){ e1.value=''; e1.classList.remove('is-valid','is-invalid'); }
    if(e2){ e2.value=''; e2.classList.remove('is-valid','is-invalid'); }
    if(emailHelp) emailHelp.textContent='';
    btnEmail.disabled = true;
  });

  // --- Password double entry ---
  const p1 = document.getElementById('pass1');
  const p2 = document.getElementById('pass2');
  const btnPass = document.getElementById('btnPassSave');
  const passHelp = document.getElementById('passHelp');

  function validatePass(){
    const a = p1.value, b = p2.value;
    const long = a.length >= 8;
    const same = a !== '' && a === b;
    btnPass.disabled = !(long && same);
    passHelp.textContent = !long ? 'Mínimo 8 caracteres' : (same ? 'Coinciden' : 'No coinciden');
    p1.classList.toggle('is-valid', long && same);
    p2.classList.toggle('is-valid', long && same);
    p1.classList.toggle('is-invalid', !(long && same));
    p2.classList.toggle('is-invalid', !(long && same));
  }
  p1?.addEventListener('input', validatePass);
  p2?.addEventListener('input', validatePass);
  document.getElementById('modalPass')?.addEventListener('hidden.bs.modal', ()=>{
    if(p1){ p1.value=''; p1.classList.remove('is-valid','is-invalid'); }
    if(p2){ p2.value=''; p2.classList.remove('is-valid','is-invalid'); }
    if(passHelp) passHelp.textContent='';
    btnPass.disabled = true;
  });

  // --- Autocalificación (crear/editar) ---
  const autoModalEl = document.getElementById('modalAuto');
  const autoModal   = autoModalEl ? new bootstrap.Modal(autoModalEl) : null;
  function setRG(name, val){
    if(!autoModalEl) return;
    const r = autoModalEl.querySelectorAll(`input[name="${name}"]`);
    r.forEach(x => x.checked = (String(x.value) === String(val)));
  }
  function clearAuto(){
    if(!autoModalEl) return;
    ['fisico','arquero','delantero','mediocampo','defensa'].forEach(k => setRG(k, ''));
    const idH = autoModalEl.querySelector('#auto-id'); if(idH) idH.value = '';
    const tx  = autoModalEl.querySelector('#auto-coment'); if(tx) tx.value = '';
  }
  document.querySelectorAll('[data-open-auto]').forEach(btn=>{
    btn.addEventListener('click', ()=>{
      clearAuto();
      if(autoModalEl){
        const idH = autoModalEl.querySelector('#auto-id');
        const tx  = autoModalEl.querySelector('#auto-coment');
        if(idH) idH.value = btn.dataset.id || '';
        setRG('fisico',     btn.dataset.fisico     || '');
        setRG('arquero',    btn.dataset.arquero    || '');
        setRG('delantero',  btn.dataset.delantero  || '');
        setRG('mediocampo', btn.dataset.mediocampo || '');
        setRG('defensa',    btn.dataset.defensa    || '');
      }
      autoModal?.show();
    });
  });
})();
</script>
@endpush