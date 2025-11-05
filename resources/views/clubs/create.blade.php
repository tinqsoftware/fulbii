@extends('fulbii')
@section('title','Crear club · Fulbii')

@section('content')
<div class="container" style="max-width:700px; padding:16px 16px 90px;">
  <h1 class="fw-700 mb-3" style="font-size:22px">Crear club</h1>
  <form method="POST" action="{{ route('clubs.store') }}" class="card p-3 shadow-sm" enctype="multipart/form-data">
    @csrf
    <div class="mb-3">
      <label class="form-label">Nombre</label>
      <input type="text" name="nombre" class="form-control" required>
    </div>
    <div class="mb-3">
      <label class="form-label">Slug</label>
      <input type="text" name="slug" class="form-control" required>
    </div>
    <div class="mb-3">
      <label class="form-label">Descripción</label>
      <textarea name="descripcion" class="form-control" rows="3"></textarea>
    </div>
    <div class="mb-3">
      <label class="form-label">Logo (opcional)</label>
      <input type="file" name="logo" class="form-control" accept="image/*">
      <div class="form-text">PNG/JPG hasta 2MB. Recomendado 1:1.</div>
    </div>
    <div class="d-flex gap-2">
      <button class="btn btn-success">Crear</button>
      <a href="{{ route('clubs.index') }}" class="btn btn-light">Cancelar</a>
    </div>
  </form>
</div>
@endsection