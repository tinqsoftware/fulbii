<!doctype html>
<html lang="es">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <meta name="theme-color" content="#102317">
  <meta name="description" content="@yield('meta_description', 'Información pública de Fulbii.')">
  <link rel="canonical" href="{{ url()->current() }}">
  <title>@yield('title') · Fulbii</title>
  <style>
    :root {
      --ink:#0a1510; --surface:#f8fbf7; --surface-strong:#fff; --green:#23623a;
      --green-deep:#102317; --mint:#aadca0; --mint-soft:#e6f2e2; --line:#d5e2d2;
      --muted:#526158; --orange:#df7e37; --shadow:0 22px 60px rgba(22,58,31,.10);
    }
    *{box-sizing:border-box}
    html{scroll-behavior:smooth}
    body{margin:0;background:var(--surface);color:var(--ink);font-family:Inter,ui-sans-serif,system-ui,-apple-system,BlinkMacSystemFont,"Segoe UI",sans-serif;line-height:1.55}
    a{color:inherit;text-decoration:none}
    .shell{width:min(1080px,calc(100% - 40px));margin:auto}
    .topbar{background:var(--green-deep);color:#eff7ec;border-bottom:1px solid rgba(170,220,160,.18)}
    .nav{min-height:76px;display:flex;align-items:center;justify-content:space-between;gap:24px}
    .brand{display:inline-flex;align-items:center;font-size:1.42rem;font-weight:850;letter-spacing:-.06em}
    .brand-mark{display:grid;place-items:center;width:36px;height:36px;margin-right:10px;border-radius:12px;background:var(--mint);color:var(--green-deep);font-style:normal;font-size:1.16rem}
    .nav-links{display:flex;align-items:center;gap:20px;color:#c4d9c1;font-size:.93rem;font-weight:650}
    .nav-links a:hover,.nav-links a:focus-visible{color:#fff}
    .nav-cta{padding:10px 17px;border:1px solid rgba(170,220,160,.55);border-radius:999px;color:#102317!important;background:var(--mint)}
    main{padding:58px 0 76px}
    .intro{max-width:780px;margin-bottom:30px}
    .eyebrow{margin:0 0 12px;color:var(--green);font-size:.76rem;font-weight:850;letter-spacing:.13em;text-transform:uppercase}
    h1{margin:0;font-size:clamp(2.25rem,5vw,4.2rem);letter-spacing:-.075em;line-height:.98}
    .lead{max-width:700px;margin:20px 0 0;color:var(--muted);font-size:1.1rem;line-height:1.65}
    .content-grid{display:grid;grid-template-columns:minmax(0,1fr) 300px;gap:22px;align-items:start}
    .panel{padding:30px;border:1px solid var(--line);border-radius:26px;background:var(--surface-strong);box-shadow:var(--shadow)}
    .panel h2{margin:0 0 16px;font-size:1.45rem;letter-spacing:-.04em;line-height:1.1}
    .panel h3{margin:28px 0 7px;font-size:1.06rem;letter-spacing:-.015em}
    .panel h3:first-child{margin-top:0}
    .panel p,.panel li{color:var(--muted);font-size:.98rem}
    .panel p{margin:0 0 14px}
    .panel ul{margin:8px 0 22px;padding-left:21px}
    .panel li{margin:7px 0}
    .panel a{color:var(--green);font-weight:750;text-decoration:underline;text-decoration-color:rgba(35,98,58,.25);text-underline-offset:3px}
    .side{position:sticky;top:20px}
    .contact-card{padding:24px;border-radius:23px;background:var(--green-deep);color:#eff7ec;box-shadow:var(--shadow)}
    .contact-card h2{font-size:1.25rem;margin-bottom:10px}
    .contact-card p{margin:0 0 18px;color:#c5d8c3;font-size:.93rem}
    .contact-actions{display:grid;gap:10px}
    .button{display:inline-flex;align-items:center;justify-content:center;min-height:48px;padding:0 17px;border-radius:999px;background:var(--mint);color:var(--green-deep)!important;font-weight:800;text-decoration:none!important}
    .button.secondary{border:1px solid rgba(170,220,160,.6);background:transparent;color:#eff7ec!important}
    .note{margin-top:16px;padding:15px 16px;border-left:3px solid var(--orange);border-radius:0 13px 13px 0;background:#fff6ed;color:#624021;font-size:.91rem}
    .faq{display:grid;gap:10px}
    details{border:1px solid var(--line);border-radius:16px;background:#fbfdfb;overflow:hidden}
    summary{cursor:pointer;padding:16px 18px;font-weight:780;list-style:none}
    summary::-webkit-details-marker{display:none}
    summary::after{content:'+';float:right;color:var(--green);font-size:1.25rem;line-height:1}
    details[open] summary::after{content:'−'}
    details p{padding:0 18px 17px;margin:0!important}
    .legal-meta{display:flex;flex-wrap:wrap;gap:8px;margin-top:20px;color:var(--muted);font-size:.89rem}
    .meta-pill{padding:6px 10px;border:1px solid var(--line);border-radius:999px;background:var(--mint-soft)}
    footer{padding:26px 0;border-top:1px solid var(--line);color:var(--muted);font-size:.88rem}
    footer .shell{display:flex;justify-content:space-between;align-items:center;gap:16px;flex-wrap:wrap}
    .footer-links{display:flex;gap:16px;flex-wrap:wrap}.footer-links a{color:var(--green);font-weight:750}
    :focus-visible{outline:3px solid rgba(35,98,58,.35);outline-offset:3px}
    @media(max-width:800px){.shell{width:min(100% - 28px,640px)}.nav{min-height:68px}.nav-links{gap:12px}.nav-links a:not(.nav-cta){display:none}main{padding:40px 0 54px}.content-grid{grid-template-columns:1fr}.side{position:static;order:-1}.panel{padding:23px;border-radius:21px}.contact-card{padding:21px}}
    @media(prefers-reduced-motion:reduce){html{scroll-behavior:auto}}
  </style>
  @stack('head')
</head>
<body>
  <header class="topbar">
    <div class="shell nav">
      <a class="brand" href="{{ url('/') }}" aria-label="Fulbii, inicio"><i class="brand-mark" aria-hidden="true">⚽</i>Fulbii</a>
      <nav class="nav-links" aria-label="Navegación pública">
        <a href="{{ url('/') }}#funciones">Funciones</a>
        <a href="{{ route('privacy') }}">Privacidad</a>
        <a href="{{ route('support') }}">Soporte</a>
        <a class="nav-cta" href="{{ $supportWhatsappUrl }}" target="_blank" rel="noopener">WhatsApp</a>
      </nav>
    </div>
  </header>
  <main>
    <div class="shell">
      @yield('content')
    </div>
  </main>
  <footer>
    <div class="shell">
      <span>© {{ now()->year }} {{ $legalOwner }} · Fulbii</span>
      <nav class="footer-links" aria-label="Enlaces legales">
        <a href="{{ route('support') }}">Soporte</a>
        <a href="{{ route('privacy') }}">Privacidad</a>
        <a href="{{ route('login') }}">Administración</a>
      </nav>
    </div>
  </footer>
</body>
</html>
