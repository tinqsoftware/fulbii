@section('content')
  <!-- Overlay de bloqueo solo para HOME; no cubre header ni tabbar (se monta dentro de <main>) -->
  <div id="home-lock" class="home-lock">
    <div class="home-lock__panel">
      <div class="home-lock__title pt-5">Se paciente pichanguero</div>
      <div class="home-lock__subtitle">¡Pronto activaremos este módulo!!</div>
      <img src="{{ url('assets/images/favicon.png') }}" class="pt-4 pb-4" alt="Fulbii">
    </div>
  </div>
@endsection

@push('styles')
.home-lock{
  position:absolute; inset:0; z-index:15;
  display:flex; align-items:center; justify-content:center;
  padding:24px 16px;
  background:rgba(2,6,23,.45);
  backdrop-filter:blur(1.3px);
}
.home-lock__panel{
  background:#fff; border-radius:16px;
  box-shadow:0 20px 60px rgba(0,0,0,.25);
  padding:20px 24px; text-align:center; max-width:540px;
}
.home-lock__title{ font-weight:800; font-size:22px; color:#1a7a43; }
.home-lock__subtitle{ margin-top:6px; color:#334155; font-size:20px; }
.home-lock__btn{
  margin-top:12px; display:inline-block;
  background:#1a7a43; color:#fff; font-weight:700;
  border-radius:999px; padding:10px 14px; cursor:pointer;
}
.home-lock img{ height:150px }
@endpush


@extends('fulbii')

@section('title','Fulbii · Mapa')

@section('map')
  <div id="map"></div>
@endsection

@section('sheet')
  @foreach(($cards ?? []) as $c)
    <div class="card-mini">
      <div class="body">
        <h6 class="font-xssss fw-600" style="color:#5fb48b">{{ $c['sub'] }}</h6>
        <div class="title">{{ $c['title'] }}</div>
        <div class="text-grey-500" style="font-size:12px">{{ $c['zona'] }}</div>
        <div class="mt-2">
          <strong class="text-success">{{ $c['modalidad'] }}</strong>
          <div class="text-grey-500" style="font-size:12px">{{ $c['hora'] }} ({{ $c['dur'] }})</div>
        </div>
      </div>
    </div>
  @endforeach
@endsection

@push('scripts')
<script>
  const map = L.map('map',{ zoomControl:false }).setView([-12.0694,-77.0360], 12.5);
  L.tileLayer('https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',{ maxZoom: 20 }).addTo(map);
  const fields = @json($fields ?? []);
  fields.forEach(f=>{
    const m = L.marker([f.x, f.y],{
      icon: L.divIcon({ className:'price-marker', html:`<div class=\"price-rect\">S/${f.price}</div>` })
    }).addTo(map);
    m.on('click', ()=> console.log('click', f));
  });
</script>
@endpush