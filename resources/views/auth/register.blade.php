
@extends('fulbii')
@section('title','Crear cuenta · Fulbii')

@section('content')
<div class="auth-shell">
  <div class="blob blob-a"></div>
  <div class="blob blob-b"></div>

  <div class="auth-grid">
    <section class="auth-card">
      <div class="glass card shadow-none border-0">
        <div class="card-body p-4 p-md-5">

          <h3 class="fw-800 mb-1">Crea tu cuenta</h3>
          <p class="text-muted mb-4">Únete y empieza a pichanguear ⚽</p>

          <form id="register-form" method="POST" action="{{ route('register') }}" autocomplete="on" novalidate>
            @csrf

            <div class="row g-3">
              <div class="col-12 col-md-6">
                <label for="name" class="form-label small fw-600">Nombre y apellido</label>
                <input id="name" type="text" name="name" value="{{ old('name') }}" required
                  class="form-control @error('name') is-invalid @enderror" placeholder="Ej: Enrique Ricci">
                @error('name') <div class="invalid-feedback d-block">{{ $message }}</div> @enderror
              </div>

              <div class="col-12 col-md-6">
                <label for="nick" class="form-label small fw-600">Nickname</label>
                <div class="position-relative">
                  <input id="nick" type="text" name="nick" value="{{ old('nick') }}" required
                    class="form-control @error('nick') is-invalid @enderror"
                    placeholder="Es único y sin espacios" autocomplete="off" inputmode="latin-prose">
                  <span id="nick-status" class="nick-hint small"></span>
                </div>
                @error('nick') <div class="invalid-feedback d-block">{{ $message }}</div> @enderror
              </div>

              <div class="col-12">
                <label for="email" class="form-label small fw-600">Correo electrónico</label>
                <input id="email" type="email" name="email" value="{{ old('email') }}" required
                  class="form-control @error('email') is-invalid @enderror" placeholder="tucorreo@ejemplo.com">
                @error('email') <div class="invalid-feedback d-block">{{ $message }}</div> @enderror
              </div>

              <div class="col-12 col-md-6">
                <label for="password" class="form-label small fw-600">Contraseña</label>
                <input id="password" type="password" name="password" required
                  class="form-control @error('password') is-invalid @enderror" placeholder="Mínimo 8 caracteres">
                @error('password') <div class="invalid-feedback d-block">{{ $message }}</div> @enderror
              </div>

              <div class="col-12 col-md-6">
                <label for="password-confirm" class="form-label small fw-600">Confirmar contraseña</label>
                <input id="password-confirm" type="password" name="password_confirmation" required
                  class="form-control" placeholder="Repite tu contraseña">
              </div>
            </div>

            <div class="d-grid gap-2 mt-4">
              <button id="btn-submit" type="submit" class="btn btn-success btn-lg btn-cta" disabled>
                <span>Registrar</span>
                <i class="ti-check ms-1"></i>
              </button>
            </div>

            <div class="text-center mt-3 small text-muted">
              ¿Ya tienes cuenta?
              <a href="{{ route('login') }}" class="fw-600">Inicia sesión</a>
            </div>
          </form>

        </div>
      </div>
    </section>
  </div>
</div>

<div style="height:72px" class="d-lg-none"></div>
@endsection

@push('styles')
<style>
  :root{ --ful-green:#1a7a43; --ful-mint:#e9f8ee; --ink:#0f172a; }
  .auth-shell{ min-height:calc(100dvh - 56px); display:grid; place-items:center; position:relative; overflow:hidden;
    background: radial-gradient(600px 400px at -10% -20%, var(--ful-mint) 0%, transparent 60%),
               radial-gradient(600px 400px at 110% 120%, var(--ful-mint) 0%, transparent 60%),
               linear-gradient(180deg,#ffffff,#f7faf8); }
  .blob{ position:absolute; filter:blur(40px); opacity:.35; z-index:0; animation: floaty 12s ease-in-out infinite; }
  .blob-a{ width:380px; height:380px; background:#88e2b2; top:-60px; left:-60px; }
  .blob-b{ width:320px; height:320px; background:#b9f0d1; bottom:-60px; right:-40px; animation-delay:-5s; }
  @keyframes floaty{ 0%,100%{ transform:translateY(0) } 50%{ transform:translateY(12px) } }
  .auth-grid{ width:min(780px, 100% - 32px); display:grid; z-index:1; }
  .glass{ position:relative; border-radius:20px; background:rgba(255,255,255,.9);
    backdrop-filter: blur(10px); border:1px solid rgba(15,23,42,.06);
    box-shadow:0 10px 30px rgba(16,24,40,.12); }
  .glass::before{ content:""; position:absolute; inset:0; padding:1px; border-radius:20px;
    background: linear-gradient(140deg, #dff7ea, rgba(26,122,67,.15) 35%, rgba(26,122,67,.0) 60%, rgba(26,122,67,.20));
    -webkit-mask: linear-gradient(#000 0 0) content-box, linear-gradient(#000 0 0);
    -webkit-mask-composite: xor; mask-composite: exclude; pointer-events:none; }
  /* Nick status */
  #nick.is-valid{ border-color:#15803d !important; box-shadow:0 0 0 .2rem rgba(21,128,61,.15); }
  #nick.is-invalid{ border-color:#dc2626 !important; box-shadow:0 0 0 .2rem rgba(220,38,38,.12); }
  .nick-hint{ position:absolute; right:10px; top:50%; transform:translateY(-50%); font-weight:700; }
  .nick-hint.ok{ color:#15803d; }
  .nick-hint.bad{ color:#dc2626; }
  .btn-cta{ display:inline-flex; align-items:center; justify-content:center; gap:6px; font-weight:800; letter-spacing:.2px;
    box-shadow:0 12px 30px rgba(26,122,67,.28); transition: transform .08s ease; }
  .btn-cta:disabled{ opacity:.6; box-shadow:none; }
</style>
@endpush

@push('scripts')
<script>
(function(){
  const NICK_URL = "{{ route('nick.available') }}";
  const f = document.getElementById('register-form');
  const btn = document.getElementById('btn-submit');
  const nameI = document.getElementById('name');
  const emailI = document.getElementById('email');
  const nickI = document.getElementById('nick');
  const passI = document.getElementById('password');
  const pass2I = document.getElementById('password-confirm');
  const hint = document.getElementById('nick-status');

  let nickOK = false, t = null;

  function validateFilled(){
    const base = !!nameI.value.trim() && !!emailI.value.trim() && !!nickI.value.trim()
                && !!passI.value && passI.value === pass2I.value && passI.value.length >= 8;
    btn.disabled = !(base && nickOK);
  }

  function setNickState(state, msg){
    nickI.classList.remove('is-valid','is-invalid');
    hint.classList.remove('ok','bad');
    if(state === 'ok'){
      nickI.classList.add('is-valid'); hint.classList.add('ok'); hint.textContent = '✓ disponible';
      nickOK = true;
    }else if(state === 'bad'){
      nickI.classList.add('is-invalid'); hint.classList.add('bad'); hint.textContent = msg || 'No disponible';
      nickOK = false;
    }else{
      hint.textContent = '';
      nickOK = false;
    }
    validateFilled();
  }

  async function checkNick(){
    let raw = nickI.value.trim();
    // Quita '@' si el usuario lo escribe y elimina espacios internos
    raw = raw.replace(/^@+/, '').replace(/\s+/g, '');
    nickI.value = raw;
    if(raw.length < 3){ setNickState('bad','Mín. 3 caracteres'); return; }
    try{
      const res = await fetch(NICK_URL + '?nick=' + encodeURIComponent(raw), { headers:{ 'X-Requested-With':'XMLHttpRequest' }});
      if(!res.ok){ setNickState('bad','Error'); return; }
      const data = await res.json();
      if(data.valid && data.available){ setNickState('ok'); }
      else{
        setNickState('bad', data.message || 'No disponible');
      }
    }catch(e){ setNickState('bad','Sin conexión'); }
  }

  nickI.addEventListener('input', ()=>{
    setNickState('neutral');
    clearTimeout(t);
    t = setTimeout(checkNick, 400);
  });

  [nameI,emailI,passI,pass2I].forEach(el => el.addEventListener('input', validateFilled));

  // Primera evaluación por si vienen valores viejos
  validateFilled();
})();
</script>
@endpush
