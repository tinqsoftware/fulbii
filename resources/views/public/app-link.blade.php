<!doctype html>
<html lang="es">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <link rel="canonical" href="{{ $baseUrl }}{{ $canonicalPath }}">
  <meta name="robots" content="noindex">
  <title>{{ $title }} · Fulbii</title>
  <style>
    :root{--ink:#0a1510;--green:#23623a;--mint:#aadca0;--line:#d5e2d2;--muted:#617067}*{box-sizing:border-box}body{min-height:100vh;margin:0;display:grid;place-items:center;padding:24px;background:radial-gradient(circle at top,#dcedd6,#f7faf6 48%,#ecf4e9);font-family:Inter,ui-sans-serif,system-ui,-apple-system,"Segoe UI",sans-serif;color:var(--ink)}main{width:min(100%,520px);padding:36px;border:1px solid var(--line);border-radius:30px;background:rgba(255,255,255,.92);box-shadow:0 24px 70px rgba(27,66,34,.12);text-align:center}.brand{display:inline-flex;align-items:center;font-weight:850;letter-spacing:-.05em;font-size:1.35rem}.brand i{display:grid;place-items:center;width:32px;height:32px;margin-right:8px;border-radius:10px;background:var(--green);color:#fff;font-style:normal}.eyebrow{margin:32px 0 10px;color:var(--green);font-size:.75rem;font-weight:800;text-transform:uppercase;letter-spacing:.1em}h1{margin:0;font-size:clamp(2rem,8vw,3rem);letter-spacing:-.06em;line-height:1.02}p{margin:18px auto 0;max-width:400px;color:var(--muted);line-height:1.55}.actions{display:grid;gap:10px;margin-top:28px}.button{display:flex;align-items:center;justify-content:center;min-height:49px;padding:0 18px;border-radius:999px;background:var(--green);color:#fff;text-decoration:none;font-weight:760}.secondary{background:#fff;border:1px solid #91aa8b;color:var(--green)}.foot{margin-top:24px;font-size:.84rem;color:#748178}.foot a{color:var(--green);font-weight:700;text-decoration:none}
  </style>
</head>
<body>
  <main>
    <a class="brand" href="{{ url('/') }}"><i>⚽</i>Fulbii</a>
    <p class="eyebrow">{{ $eyebrow }}</p>
    <h1>{{ $title }}</h1>
    <p>{{ $description }}</p>
    <div class="actions">
      <a class="button" href="{{ $appLink }}">Abrir Fulbii</a>
      @if($iosStoreUrl !== '')<a class="button secondary" href="{{ $iosStoreUrl }}">Descargar para iPhone</a>@endif
      @if($androidStoreUrl !== '')<a class="button secondary" href="{{ $androidStoreUrl }}">Descargar para Android</a>@endif
    </div>
    <p class="foot">¿No se abrió? Instala Fulbii y vuelve a tocar el enlace. <a href="{{ url('/') }}">Conoce Fulbii</a></p>
    <p class="foot"><a href="{{ route('support') }}">Soporte</a> · <a href="{{ route('privacy') }}">Privacidad</a> · <a href="{{ $supportWhatsappUrl }}" target="_blank" rel="noopener">WhatsApp</a></p>
  </main>
  <script>setTimeout(function(){ window.location.assign(@json($appLink)); }, 500);</script>
</body>
</html>
