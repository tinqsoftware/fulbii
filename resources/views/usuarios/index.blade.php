@extends('layouts.app')
@section('content')
<div class="container mx-auto max-w-5xl py-6">
  <h1 class="text-2xl font-bold mb-4">Usuarios</h1>
  <table class="w-full border">
    <tr class="bg-gray-50">
      <th class="p-2 text-left">ID</th>
      <th class="p-2 text-left">Nombre</th>
      <th class="p-2 text-left">Email</th>
      <th class="p-2">Acciones</th>
    </tr>
    @foreach($users as $u)
    <tr class="border-t">
      <td class="p-2">{{ $u->id }}</td>
      <td class="p-2">{{ $u->name }}</td>
      <td class="p-2">{{ $u->email }}</td>
      <td class="p-2">
        <a class="text-sm text-blue-600" href="{{ route('usuarios.edit',$u) }}">Editar</a>
        <form method="POST" action="{{ route('usuarios.destroy',$u) }}" class="inline" onsubmit="return confirm('¿Eliminar?')">
          @csrf @method('DELETE')
          <button class="text-sm text-red-600">Eliminar</button>
        </form>
      </td>
    </tr>
    @endforeach
  </table>
</div>
@endsection