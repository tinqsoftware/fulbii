@extends('layouts.app')

@section('content')
<div class="container">
  <div class="admin-page-title"><div><p class="admin-eyebrow">Catálogo</p><h1>Canchas reales</h1><p class="admin-page-subtitle">Mantén sedes y canchas publicadas con información confiable.</p></div></div>
  @include('admin.partials.nav')
  @if(session('ok')) <div class="alert alert-success">{{ session('ok') }}</div> @endif
  @if($errors->any()) <div class="alert alert-danger">{{ $errors->first() }}</div> @endif

  <div class="card mb-3">
    <div class="card-header">Publicar polideportivo y cancha</div>
    <form method="POST" action="{{ route('admin.fields.store') }}" class="card-body row g-2">
      @csrf
      <div class="col-md-6"><input required name="nombre" class="form-control" placeholder="Nombre del polideportivo"></div>
      <div class="col-md-6"><input name="direccion" class="form-control" placeholder="Dirección"></div>
      <div class="col-md-3"><input name="x" class="form-control" placeholder="Latitud"></div>
      <div class="col-md-3"><input name="y" class="form-control" placeholder="Longitud"></div>
      <div class="col-md-3"><input name="celular" class="form-control" placeholder="Celular"></div>
      <div class="col-md-3"><input name="precio_desde" class="form-control" placeholder="Precio desde"></div>
      <div class="col-md-6"><input required name="cancha_nombre" class="form-control" placeholder="Nombre de cancha"></div>
      <div class="col-md-3"><select required name="cancha_equiposvs" class="form-select">@foreach([5,6,7,8,9,11] as $size)<option value="{{ $size }}">{{ $size }} vs {{ $size }}</option>@endforeach</select></div>
      <div class="col-md-3"><select required name="cancha_tipo_superficie" class="form-select"><option value="sintetico">Grass sintético</option><option value="losa">Losa</option><option value="natural">Grass natural</option></select></div>
      <div class="col-12"><textarea name="descripcion" class="form-control" placeholder="Descripción"></textarea></div>
      <div class="col-12"><button class="btn btn-success">Publicar y aprobar ahora</button></div>
    </form>
  </div>

  @foreach($items as $field)
    <div class="card mb-3"><div class="card-body">
      <form method="POST" action="{{ route('admin.fields.update', $field) }}" class="row g-2 align-items-end">
        @csrf @method('PUT')
        <div class="col-md-4"><label class="form-label">Polideportivo</label><input required name="nombre" value="{{ $field->nombre }}" class="form-control"></div>
        <div class="col-md-5"><label class="form-label">Dirección</label><input name="direccion" value="{{ $field->direccion }}" class="form-control"></div>
        <div class="col-md-3"><button class="btn btn-outline-primary w-100">Guardar polideportivo</button></div>
      </form>
      @foreach($field->canchas as $court)
        <form method="POST" action="{{ route('admin.courts.update', $court) }}" class="row g-2 mt-2 border-top pt-2 align-items-end">
          @csrf @method('PUT')
          <div class="col-md-5"><input required name="nombre" value="{{ $court->nombre }}" class="form-control"></div>
          <div class="col-md-3"><select name="equiposvs" class="form-select">@foreach([5,6,7,8,9,11] as $size)<option value="{{ $size }}" @selected((string)$court->equiposvs === (string)$size)>{{ $size }} vs {{ $size }}</option>@endforeach</select></div>
          <div class="col-md-2"><select name="tipo_superficie" class="form-select">@foreach(['sintetico'=>'Grass sintético','losa'=>'Losa','natural'=>'Grass natural'] as $value=>$label)<option value="{{ $value }}" @selected($court->tipo_superficie === $value)>{{ $label }}</option>@endforeach</select></div>
          <div class="col-md-2"><button class="btn btn-outline-secondary w-100">Guardar cancha</button></div>
        </form>
      @endforeach
    </div></div>
  @endforeach
  {{ $items->links() }}
</div>
@endsection
