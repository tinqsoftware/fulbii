@extends('fulbii')
@section('title','Ingresar · Fulbii')

@section('content')
<div class="auth-shell py-3 py-lg-5">
  <!-- decor blobs -->
  <div class="blob blob-a"></div>
  <div class="blob blob-b"></div>

  <div class="auth-grid">
    <!-- Lado visual / copy (solo desktop) -->
    <aside class="auth-hero d-none d-lg-flex order-lg-1">
      <div class="hero-copy">
        <h2 class="hero-title">
          Inicia sesión y arma tu <span>pichanga</span> con estilo
        </h2>
        <p class="hero-sub">Explora clubes, califica jugadores y organiza partidos.</p>

        <div class="phrase-ticker" id="tickerDesk">
          <div class="ticker-track">
            <span class="tk-item">"La pelota no se mancha." - Diego Armando Maradona</span>
            <span class="tk-item">"El fútbol es lo más importante de las cosas menos importantes." - Arrigo Sacchi</span>
            <span class="tk-item">"A medida que uno va ganando cosas, uno se hamburguesa." - Carlos Tevez</span>
            <span class="tk-item">"Juegan al fútbol como yo quiero que se juegue al fútbol." - Johan Cruyff</span>
            <span class="tk-item">"No se gana una copa del mundo con once jugadores, se gana con 23." - Marcello Lippi</span>
            <span class="tk-item">"El fútbol es sencillo, pero es difícil jugarlo sencillo." - Johan Cruyff</span>
            <span class="tk-item">"Es imposible hacer una lista de los 100 mejores jugadores del mundo sin incluir a Pelé." - Pelé</span>
            <span class="tk-item">"El fútbol es como el ajedrez, pero sin dados" - Lukas Podolski</span>
            <span class="tk-item">"El balón es el mismo en todas partes, pero el fútbol es diferente." - René Higuita</span>
            <span class="tk-item">"Un hombre solo no puede ganar un partido." - Pelé</span>
            <span class="tk-item">"El fútbol es alegría, alegría de la gente." - Ronaldinho</span>
            <span class="tk-item">"Si no crees en ti mismo, nadie lo hará." - Cristiano Ronaldo</span>
            <span class="tk-item">"Nací para ser futbolista, y no me arrepiento de ello." - Lionel Messi</span>
            <span class="tk-item">"Vi al arquero adelantado y se la tiré por arriba, fue un gol de odontología" - Nelson Pedetti</span>
            <span class="tk-item">"No puedes ganar nada sin trabajo en equipo." - Zinedine Zidane</span>
            <span class="tk-item">"El fútbol no es solo un deporte, es pasión y sentimientos." - Alfredo Di Stéfano</span>
            <span class="tk-item">"Como todo equipo africano, Jamaica será un rival difícil" - Edinson Cavani</span>
            <span class="tk-item">"En el fútbol, todo es posible mientras tengas la voluntad de hacerlo." - Johan Cruyff</span>
            <span class="tk-item">"Cada día me levanto pensando en cómo superarme a mí mismo." - Cristiano Ronaldo</span>
            <span class="tk-item">"Prefiero perder un buen partido que ganar un mal partido." - Pep Guardiola</span>
            <span class="tk-item">"No sé si soy un entrenador conservador, solo sé que no soy un estúpido." - José Mourinho</span>
            <span class="tk-item">"Cuando un árbitro se equivoca, no es un error, es un robo." - Diego Simeone</span>
            <span class="tk-item">"El fútbol no se juega solo con los pies, se juega con la cabeza." - Zinedine Zidane</span>
            <span class="tk-item">"Si quieres ganar algo, compra un delantero. Si quieres ganar todo, compra un mediocampista." - Pep Guardiola</span>
            <span class="tk-item">"El fútbol no tiene memoria." - Jorge Sampaoli</span>
            <span class="tk-item">"El VAR está matando la emoción del fútbol." - José Mourinho</span>
          </div>
        </div>
      </div>
    </aside>

    <!-- Card de login -->
    <section class="auth-card order-1 order-lg-2">
      <div class="glass card shadow-none border-0">
        <div class="card-body p-4 p-md-5">

          <!-- Marca + frases (visible en móvil) -->
          <div class="hero-copy-mobile d-lg-none mb-1">
            <h2 class="hero-title">Inicia sesión y arma tu <span>pichanga</span> con estilo</h2>
            <p class="hero-sub">Explora clubes, califica jugadores y organiza partidos ⚽.</p>
          </div>

          <form method="POST" action="{{ route('login') }}" autocomplete="on" novalidate>
            @csrf

            <div class="mb-3">
              <label for="email" class="form-label small fw-600">Correo electrónico</label>
              <div class="input-group fancy-input">
                <span class="input-group-text"><i class="ti-email"></i></span>
                <input id="email" type="email" name="email" value="{{ old('email') }}" required autofocus
                       class="form-control @error('email') is-invalid @enderror" placeholder="tucorreo@ejemplo.com">
              </div>
              @error('email')
                <div class="invalid-feedback d-block">{{ $message }}</div>
              @enderror
            </div>

            <div class="mb-2">
              <label for="password" class="form-label small fw-600">Contraseña</label>
              <div class="input-group fancy-input">
                <span class="input-group-text"><i class="ti-lock"></i></span>
                <input id="password" type="password" name="password" required
                       class="form-control @error('password') is-invalid @enderror" placeholder="••••••••">
                <button class="btn btn-outline-secondary toggle-pass" type="button" aria-label="Mostrar / ocultar contraseña">
                  <i class="ti-eye"></i>
                </button>
              </div>
              @error('password')
                <div class="invalid-feedback d-block">{{ $message }}</div>
              @enderror
            </div>

            <div class="d-flex justify-content-between align-items-center mb-4 small">
              <a class="link-underline" href="https://wa.me/51953761235?text=que%20tal%20como%20est%C3%A1s%20olvide%20mi%20contrase%C3%B1a%20en%20fulbii" target="_blank" rel="noopener">¿Olvidaste tu contraseña?</a>
            </div>

            <div class="d-grid gap-2">
              <button type="submit" class="btn btn-success btn-lg btn-cta">
                <span>Entrar</span>
                <i class="ti-arrow-right ms-1"></i>
              </button>
            </div>

            <div class="text-center mt-3 small text-muted">
              ¿No tienes cuenta?
              <a href="{{ route('register') }}" class="fw-600">Crear cuenta</a>
            </div>

            {{-- Social (opcional, solo si existen las rutas) --}}
            @if(Route::has('auth.google.redirect') || Route::has('auth.apple.redirect'))
              <div class="separator my-4"><span>o continúa con</span></div>
              <div class="d-grid gap-2">
                @if(Route::has('auth.google.redirect'))
                  <a href="{{ route('auth.google.redirect') }}" class="btn btn-light border">
                    <i class="ti-google me-2"></i> Google
                  </a>
                @endif
                @if(Route::has('auth.apple.redirect'))
                  <a href="{{ route('auth.apple.redirect') }}" class="btn btn-dark">
                    <i class="ti-apple me-2"></i> Apple
                  </a>
                @endif
              </div>
            @endif
          </form>
           <div class="phrase-ticker d-lg-none mb-3" id="tickerMobile">
            <div class="ticker-track">
                <span class="tk-item">"La pelota no se mancha." - Diego Armando Maradona</span>
                <span class="tk-item">"El fútbol es lo más importante de las cosas menos importantes." - Arrigo Sacchi</span>
                <span class="tk-item">"A medida que uno va ganando cosas, uno se hamburguesa." - Carlos Tevez</span>
                <span class="tk-item">"Juegan al fútbol como yo quiero que se juegue al fútbol." - Johan Cruyff</span>
                <span class="tk-item">"No se gana una copa del mundo con once jugadores, se gana con 23." - Marcello Lippi</span>
                <span class="tk-item">"El fútbol es sencillo, pero es difícil jugarlo sencillo." - Johan Cruyff</span>
                <span class="tk-item">"Es imposible hacer una lista de los 100 mejores jugadores del mundo sin incluir a Pelé." - Pelé</span>
                <span class="tk-item">"El fútbol es como el ajedrez, pero sin dados" - Lukas Podolski</span>
                <span class="tk-item">"El balón es el mismo en todas partes, pero el fútbol es diferente." - René Higuita</span>
                <span class="tk-item">"Un hombre solo no puede ganar un partido." - Pelé</span>
                <span class="tk-item">"El fútbol es alegría, alegría de la gente." - Ronaldinho</span>
                <span class="tk-item">"Si no crees en ti mismo, nadie lo hará." - Cristiano Ronaldo</span>
                <span class="tk-item">"Nací para ser futbolista, y no me arrepiento de ello." - Lionel Messi</span>
                <span class="tk-item">"Vi al arquero adelantado y se la tiré por arriba, fue un gol de odontología" - Nelson Pedetti</span>
                <span class="tk-item">"No puedes ganar nada sin trabajo en equipo." - Zinedine Zidane</span>
                <span class="tk-item">"El fútbol no es solo un deporte, es pasión y sentimientos." - Alfredo Di Stéfano</span>
                <span class="tk-item">"Como todo equipo africano, Jamaica será un rival difícil" - Edinson Cavani</span>
                <span class="tk-item">"En el fútbol, todo es posible mientras tengas la voluntad de hacerlo." - Johan Cruyff</span>
                <span class="tk-item">"Cada día me levanto pensando en cómo superarme a mí mismo." - Cristiano Ronaldo</span>
                <span class="tk-item">"Prefiero perder un buen partido que ganar un mal partido." - Pep Guardiola</span>
                <span class="tk-item">"No sé si soy un entrenador conservador, solo sé que no soy un estúpido." - José Mourinho</span>
                <span class="tk-item">"Cuando un árbitro se equivoca, no es un error, es un robo." - Diego Simeone</span>
                <span class="tk-item">"El fútbol no se juega solo con los pies, se juega con la cabeza." - Zinedine Zidane</span>
                <span class="tk-item">"Si quieres ganar algo, compra un delantero. Si quieres ganar todo, compra un mediocampista." - Pep Guardiola</span>
                <span class="tk-item">"El fútbol no tiene memoria." - Jorge Sampaoli</span>
                <span class="tk-item">"El VAR está matando la emoción del fútbol." - José Mourinho</span>
            </div>
          </div>
        </div>
      </div>
    </section>
  </div>
</div>

<!-- espacio inferior para no chocar con la tabbar en móvil -->
<div style="height:72px" class="d-lg-none"></div>
@endsection

@push('styles')
<style>
  :root{
    --ful-green:#1a7a43;
    --ful-mint:#e9f8ee;
    --ink:#0f172a;
  }

  /* Shell */
  .auth-shell{
    min-height:calc(100dvh - 56px);
    display:grid; place-items:center; position:relative; overflow:hidden;
    background:
      radial-gradient(600px 400px at -10% -20%, var(--ful-mint) 0%, transparent 60%),
      radial-gradient(600px 400px at 110% 120%, var(--ful-mint) 0%, transparent 60%),
      linear-gradient(180deg,#ffffff,#f7faf8);
  }
  .auth-shell::after{
    /* líneas sutiles tipo cancha */
    content:""; position:absolute; inset:-200px;
    background:
      repeating-linear-gradient(135deg, rgba(26,122,67,.06) 0 1px, transparent 1px 36px);
    pointer-events:none;
  }

  .blob{
    position:absolute; filter:blur(40px); opacity:.35; z-index:0;
    animation: floaty 12s ease-in-out infinite;
  }
  .blob-a{ width:380px; height:380px; background: #88e2b2; top: -60px; left: -60px; }
  .blob-b{ width:320px; height:320px; background: #b9f0d1; bottom: -60px; right: -40px; animation-delay: -5s; }

  @keyframes floaty {
    0%,100%{ transform: translateY(0) }
    50%{ transform: translateY(12px) }
  }

  /* Grid */
  .auth-grid{
    width:min(1120px, 100% - 32px);
    display:grid; gap:28px; align-items:center; z-index:1;
    grid-template-columns: 1fr;
  }
  @media(min-width:992px){
    .auth-grid{ grid-template-columns: 1.05fr .95fr; }
  }

  /* Hero */
  .auth-hero{
    min-height:480px; padding:32px; border-radius:20px;
    border:1px solid #e5e7eb; background:rgba(255,255,255,.75); backdrop-filter: blur(10px);
    box-shadow:0 20px 50px rgba(26,122,67,.10);
    position:relative; overflow:hidden;
  }
  .hero-copy{ max-width:560px }
  .auth-card{ display:flex; justify-content:center }
  .auth-card .card{ width:100%; max-width:520px; border-radius:20px }
  @media(max-width:991.98px){
    .auth-card .card{ margin-top:8px }
  }
  .brand-pill{
    display:inline-flex; gap:10px; align-items:center;
    padding:10px 14px; border-radius:999px; background:var(--ful-mint); color:var(--ful-green);
    font-weight:800; letter-spacing:.3px; box-shadow:0 10px 30px rgba(26,122,67,.12);
  }
  .brand-pill img{ height:26px }
  .hero-title{
    font-size:38px; line-height:1.05; font-weight:900; color:var(--ink); margin:12px 0 6px;
  }
  .hero-title span{ color:var(--ful-green) }
  .hero-sub{ color:#475569; margin-bottom:14px }

  /* Ticker (frases en carrusel horizontal continuo) */
  .phrase-ticker{
    position:relative; overflow:hidden; height:28px; max-width:350px;
    -webkit-mask-image: linear-gradient(90deg, transparent 0, #000 6%, #000 94%, transparent 100%);
            mask-image: linear-gradient(90deg, transparent 0, #000 6%, #000 94%, transparent 100%);
  }
  .phrase-ticker .ticker-track{
    display:flex; gap:24px; white-space:nowrap;
    animation: ticker var(--dur, 50s) linear infinite;
    will-change: transform; 
  }
  .tk-item{
    display:inline-block;
    color:#0f172a; font-weight:700; padding:4px 0;
  }
  @keyframes ticker{
    from{ transform: translateX(0) }
    to{ transform: translateX(calc(-1 * var(--w))) }
  }

  /* Títulos en móvil un poco más compactos */
  @media(max-width:991.98px){
    .hero-title{ font-size:28px; margin-bottom:6px }
  }

  /* Card */
  .glass{
    position:relative; border-radius:20px; background:rgba(255,255,255,.82);
    backdrop-filter: blur(10px); border:1px solid rgba(15,23,42,.06);
    box-shadow:0 10px 30px rgba(16,24,40,.12);
  }
  .glass::before{
    /* borde degradado sutil */
    content:""; position:absolute; inset:0; padding:1px; border-radius:20px;
    background: linear-gradient(140deg, #dff7ea, rgba(26,122,67,.15) 35%, rgba(26,122,67,.0) 60%, rgba(26,122,67,.20));
    -webkit-mask: linear-gradient(#000 0 0) content-box, linear-gradient(#000 0 0);
    -webkit-mask-composite: xor; mask-composite: exclude; pointer-events:none;
  }

  /* Inputs */
  .fancy-input .input-group-text{
    background:#fff; border-right:0; color:var(--ful-green); font-weight:700;
  }
  .fancy-input .form-control{
    border-left:0; padding-top:12px; padding-bottom:12px;
  }
  .fancy-input .form-control:focus{
    box-shadow:0 0 0 .2rem rgba(26,122,67,.12);
    border-color: rgba(26,122,67,.35);
  }
  .toggle-pass{ border-left:0 }
  .toggle-pass:hover{ background:var(--ful-mint); color:var(--ful-green) }

  .btn-cta{
    display:inline-flex; align-items:center; justify-content:center; gap:6px;
    font-weight:800; letter-spacing:.2px;
    box-shadow:0 12px 30px rgba(26,122,67,.28);
    transition: transform .08s ease;
  }
  .btn-cta:hover{ transform: translateY(-1px) }

  .separator{
    position:relative; text-align:center;
  }
  .separator span{
    background:rgba(255,255,255,.8); padding:0 8px; position:relative; z-index:1;
  }
  .separator::before{
    content:""; position:absolute; left:0; right:0; top:50%; height:1px; background:#e5e7eb;
  }

  .link-underline{ text-decoration: none; border-bottom:1px dashed #94a3b8; color:#475569 }
  .link-underline:hover{ color:var(--ful-green); border-bottom-color: var(--ful-green) }
</style>
@endpush

@push('scripts')
<script>
(function(){
  // Ticker de frases: duplica una sola vez y recalcula en resize/observer
  function initTicker(id){
    const root = document.getElementById(id);
    if(!root) return;
    const track = root.querySelector('.ticker-track');
    if(!track) return;

    if(!track.dataset.dup){
      track.innerHTML = track.innerHTML + track.innerHTML;
      track.dataset.dup = '1';
    }

    function recalc(){
      const halfWidth = track.scrollWidth / 2; // contenido original
      const pxPerSec = matchMedia('(max-width:350px)').matches ? 90 : 90;
      root.style.setProperty('--w', halfWidth + 'px');
      root.style.setProperty('--dur', (halfWidth / pxPerSec) + 's');
    }

    // recalcular en ready, resize y cuando cambie el tamaño del track
    if('ResizeObserver' in window){
      const ro = new ResizeObserver(()=>recalc());
      ro.observe(track);
    }
    window.addEventListener('resize', recalc);
    // esperar a que carguen fuentes/íconos
    window.addEventListener('load', recalc);
    recalc();
  }
  initTicker('tickerDesk');
  initTicker('tickerMobile');

  // Mostrar / ocultar password
  document.querySelectorAll('.toggle-pass').forEach(btn=>{
    btn.addEventListener('click', ()=>{
      const input = btn.parentElement.querySelector('input[type="password"], input[type="text"]');
      if(!input) return;
      const to = input.type === 'password' ? 'text' : 'password';
      input.type = to;
      btn.querySelector('i').className = to === 'password' ? 'ti-eye' : 'ti-eye-off';
    });
  });
})();
</script>
@endpush