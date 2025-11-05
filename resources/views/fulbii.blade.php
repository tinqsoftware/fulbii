<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
  <title>@yield('title', 'Fulbii')</title>

  <link rel="icon" type="image/png" sizes="16x16" href="{{ url('assets/images/favicon.png') }}">
  <link rel="stylesheet" href="{{ url('assets/css/themify-icons.css') }}">
  <link rel="stylesheet" href="{{ url('assets/css/feather.css') }}">
  <link rel="stylesheet" href="{{ url('assets/css/style.css') }}">
  <link rel="stylesheet" href="{{ url('assets/css/emoji.css') }}">
  @hasSection('map')
    <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css">
  @endif

  <style>
    :root{ --header-h:56px; --tabbar-h:64px; --safe-bottom: env(safe-area-inset-bottom, 0px); }
    body{ min-height:100dvh; background:#fff }
    .wrapper{ min-height:100dvh; display:flex; flex-direction:column }

    /* Header */
    .nav-header{ position:sticky; top:0; z-index:20; background:rgba(255,255,255,.85); backdrop-filter:blur(8px); border-bottom:1px solid #eee }
    .nav-inner{ max-width:1280px; margin:0 auto; padding:0px 16px; display:flex; align-items:center; gap:16px }
    .brand{ display:flex; align-items:center; gap:8px; font-weight:700; font-size:20px; color:#0f172a; text-decoration:none }
    .brand img{ height:28px }
    .top-links{ margin-left:auto; display:none; gap:14px; align-items:center }
    .top-links a{ color:#0f172a; text-decoration:none; font-weight:600 }
    .avatar-pill{ background:#eef2f7; border-radius:20px; padding:6px 10px; font-weight:600 }

    /* Page */
    .page{ flex:1; position:relative }
    .page--with-map{ height:calc(100dvh - var(--header-h) - var(--tabbar-h) - var(--safe-bottom)) }
    #map{ position:absolute; inset:0; z-index:0 }

    /* Bottom sheet / cards */
    .sheet{ position:absolute; left:0; right:0; bottom:calc(var(--tabbar-h) + var(--safe-bottom)); padding:10px; z-index:10; display:flex; gap:10px; overflow:auto; -webkit-overflow-scrolling:touch }
    .sheet::before{ content:""; position:absolute; left:0; right:0; top:-24px; height:24px; background:linear-gradient(180deg,rgba(255,255,255,0) 0%, rgba(255,255,255,.9) 100%); pointer-events:none }
    .card-mini{ min-width:280px; background:#fff; border:1px solid #eaeaea; border-radius:12px; box-shadow:0 6px 20px rgba(16,24,40,.06) }
    .card-mini .body{ padding:12px 14px }
    .card-mini .title{ font-weight:800; line-height:1.1 }
    .price-marker .price-rect{ background:#e9f8ee; border:2px solid #5fb48b; color:#115e34; padding:3px 8px; border-radius:16px; font-weight:700 }
    .price-marker .active{ background:#1a7a43; color:#fff; border-color:#1a7a43 }
    .active-div{ outline:2px solid #1a7a43 }
    .tabbar .ico:before{font-size: 20px;}

    /* Tabbar */
    .tabbar{
      position:fixed; left:0; right:0; bottom:0;
      height:calc(var(--tabbar-h) + var(--safe-bottom));
      z-index:30; background:rgba(255,255,255,.92);
      backdrop-filter:blur(8px); border-top:1px solid #e5e7eb;
      display:flex; justify-content:space-around; align-items:center;
      padding:8px 8px calc(var(--safe-bottom) + 8px);
      box-shadow:0 -10px 30px rgba(0,0,0,.06);
    }
    .tabbar .item{ text-decoration:none; color:#64748b; font-size:12px; display:flex; flex-direction:column; align-items:center; gap:3px; padding:6px 10px; border-radius:12px; }
    .tabbar .item .ico{ width:20px; height:20px; }
    .tabbar .item.active{ color:#1a7a43; font-weight:700; background:#e9f8ee; box-shadow:0 4px 14px rgba(26,122,67,.15); }
    /* .tabbar a, .tabbar a .ico, .tabbar a.active rules removed as per safe-area refactor */

    /* FAB */
    .fab{ position:fixed; right:16px; bottom:calc(var(--tabbar-h) + var(--safe-bottom) + 12px); z-index:31; background:#1a7a43; color:#fff; text-decoration:none; font-weight:700; border-radius:999px; padding:12px 16px; box-shadow:0 10px 30px rgba(26,122,67,.35) }
    .fab .ico{ margin-right:6px }

    /* Desktop */
    @media(min-width:1024px){
      .top-links{ display:flex }
      .tabbar{ display:none }
      .page--with-map{ height:calc(100dvh - var(--header-h)) }
      .sheet{ bottom:16px }
      .fab{ bottom:24px }
    }
    @stack('styles')
  </style>
</head>
<body class="mont-font">
<div class="wrapper">
  <header class="nav-header">
    <div class="nav-inner">
      <a href="{{ route('home') }}" class="brand">
        <img src="{{ url('assets/images/favicon.png') }}" alt="Fulbii"> <span>Fulbii</span>
      </a>
      <nav class="top-links">
        <a href="{{ route('home') }}" class="{{ request()->routeIs('home') ? 'text-green-700' : '' }}">Inicio</a>
        <a href="{{ route('clubs.index') }}" class="{{ request()->routeIs('clubs.*') ? 'text-green-700' : '' }}">Clubs</a>
        <a href="{{ route('home') }}" class="{{ request()->routeIs('canchas.*') ? 'text-green-700' : '' }}">Canchas</a>
        <a href="{{ route('home') }}" class="{{ request()->routeIs('pichangas.*') ? 'text-green-700' : '' }}">Pichangas</a>
        @auth
          <a href="{{ route('mi-perfil.show') }}" class="{{ request()->routeIs('mi-perfil.*') ? 'text-green-700' : '' }}">Mi perfil</a>
          <form action="{{ route('logout') }}" method="POST" style="display:inline">@csrf
            <button type="submit" class="avatar-pill">Salir</button>
          </form>
        @endauth
        @guest
          <a href="{{ route('login') }}">Ingresar</a>
          <a href="{{ route('register') }}" class="avatar-pill">Crear cuenta</a>
        @endguest
      </nav>
    </div>
  </header>

  <main class="page @hasSection('map') page--with-map @endif">
    @yield('map')
    @hasSection('sheet')
      <div class="sheet">@yield('sheet')</div>
    @endif
    @yield('content')
  </main>


  <nav class="tabbar">
    <a href="{{ route('home') }}" class="item {{ request()->routeIs('home') ? 'active' : '' }}">
      <i class="ti-home ico"></i><span>Inicio</span>
    </a>
    <a href="{{ route('clubs.index') }}" class="item {{ request()->routeIs('clubs.*') ? 'active' : '' }}">
      <i class="ti-crown ico"></i><span>Clubs</span>
    </a>
    <a href="{{ route('home') }}" class="item {{ request()->routeIs('canchas.*') ? 'active' : '' }}">
      <i class="ti-map-alt ico"></i><span>Canchas</span>
    </a>
    <a href="{{ route('home') }}" class="item {{ request()->routeIs('pichangas.*') ? 'active' : '' }}">
      <i class="ti-bolt ico"></i><span>Pichangas</span>
    </a>
    @auth
      <a href="{{ route('mi-perfil.show') }}" class="item {{ request()->routeIs('mi-perfil.*') ? 'active' : '' }}">
        <i class="ti-user ico"></i><span>Perfil</span>
      </a>
    @else
      <a href="{{ route('login') }}" class="item {{ request()->routeIs('login') ? 'active' : '' }}">
        <i class="ti-user ico"></i><span>Entrar</span>
      </a>
    @endauth
  </nav>
</div>

<script src="https://code.jquery.com/jquery-3.6.0.min.js"></script>
<script src="{{ url('assets/js/plugin.js') }}"></script>
<script src="{{ url('assets/js/lightbox.js') }}"></script>
<script src="{{ url('assets/js/scripts.js') }}"></script>
@hasSection('map')
  <script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
@endif
@stack('scripts')
</body>
</html>