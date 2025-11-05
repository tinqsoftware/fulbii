@extends('layouts.app')
@section('content')
<div class="container mx-auto max-w-3xl py-6">
  <h1 class="text-2xl font-bold mb-4">Editar usuario</h1>
  <form method="POST" action="{{ route('usuarios.update',$usuario) }}" class="space-y-3">
    @csrf @method('PUT')
    <input class="border p-2 w-full" name="name" value="{{ $usuario->name }}">
    <input class="border p-2 w-full" name="email" value="{{ $usuario->email }}">
    <div class="border p-3 rounded">
      <div class="font-semibold mb-2">Perfiles</div>
      @foreach($perfiles as $p)
        <label class="block"><input type="checkbox" name="perfiles[]" value="{{ $p->id }}" {{ in_array($p->id,$perfilesUser)?'checked':'' }}> {{ $p->nombre }}</label>
      @endforeach
    </div>
    <button class="px-3 py-2 bg-green-600 text-white rounded">Guardar</button>
  </form>
</div>
@endsection