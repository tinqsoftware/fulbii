@extends('fulbii')
@section('title','Editar club · Fulbii')

@section('content')
<div class="container" style="max-width:700px; padding:16px 16px 90px;">
  <h1 class="fw-700 mb-3" style="font-size:22px">Editar club</h1>
  <form method="POST" action="{{ route('clubs.update',$club) }}" class="card p-3 shadow-sm" enctype="multipart/form-data">
    @csrf @method('PUT')
    <div class="mb-3">
      <label class="form-label">Nombre</label>
      <input type="text" name="nombre" class="form-control" value="{{ $club->nombre }}" required>
    </div>
    <div class="mb-3">
      <label class="form-label">Descripción</label>
      <textarea name="descripcion" class="form-control" rows="3">{{ $club->descripcion }}</textarea>
    </div>
    <div class="mb-3">
      <label class="form-label">Logo (opcional)</label>
      @if($club->logo_url)
        <div class="mb-2">
          <img src="{{ asset('storage/'.$club->logo_url) }}" alt="Logo actual" style="height:56px;border-radius:8px;object-fit:cover">
        </div>
      @endif
      <input type="file" name="logo" class="form-control" accept="image/*">
      <div class="form-text">Si subes un archivo, reemplazará el logo actual.</div>
    </div>
    <div class="d-flex gap-2">
      <button class="btn btn-primary">Guardar</button>
      <a href="{{ route('clubs.show',$club) }}" class="btn btn-light">Volver</a>
    </div>
  </form>
</div>
@endsection