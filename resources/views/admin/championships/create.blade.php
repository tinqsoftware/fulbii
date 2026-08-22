@extends('layouts.app')

@section('content')
<div class="container">
  <h3 class="mb-3">Crear campeonato</h3>
  @include('admin.partials.nav')
  <form method="post" action="{{ route('admin.championships.store') }}" class="card card-body">
    @csrf
    <div class="row g-3">
      <div class="col-md-8"><label class="form-label">Nombre</label><input required name="name" value="{{ old('name') }}" class="form-control"></div>
      <div class="col-md-4"><label class="form-label">Visibilidad</label><select name="visibility" class="form-select"><option value="public">Público</option><option value="private">Privado</option><option value="link">Solo con enlace</option></select></div>
      <div class="col-md-4"><label class="form-label">Formato</label><select name="format" class="form-select"><option value="league">Liga por puntos</option><option value="knockout">Llaves de eliminación</option><option value="hybrid">Liga + playoffs (base)</option></select></div>
      <div class="col-12"><label class="form-label">Descripción</label><textarea name="description" rows="3" class="form-control">{{ old('description') }}</textarea></div>
      <div class="col-md-3"><label class="form-label">Puntos victoria</label><input type="number" min="0" max="100" name="points_win" value="3" class="form-control"></div>
      <div class="col-md-3"><label class="form-label">Puntos empate</label><input type="number" min="0" max="100" name="points_draw" value="1" class="form-control"></div>
      <div class="col-md-3"><label class="form-label">Puntos derrota</label><input type="number" min="0" max="100" name="points_loss" value="0" class="form-control"></div>
      <div class="col-md-3"><label class="form-label">Máx. equipos</label><input type="number" min="2" max="32" name="max_teams" value="8" class="form-control"></div>
      <div class="col-md-4"><label class="form-label">Jugadores por partido</label><input type="number" min="5" max="11" name="players_per_team" value="7" class="form-control"></div>
      <div class="col-md-8"><label class="form-label">Sede principal (opcional)</label><select name="field_id" class="form-select"><option value="">Elegir sede al programar cada partido</option>@foreach($venues as $venue)<option value="{{ $venue->id }}" @selected(old('field_id') == $venue->id)>{{ $venue->nombre }}{{ $venue->direccion ? ' · '.$venue->direccion : '' }}</option>@endforeach</select><div class="form-text">Cada partido podrá usar una cancha concreta de esta sede o de otra.</div></div>
      <div class="col-md-8 d-flex align-items-end"><div class="form-check"><input class="form-check-input" type="checkbox" name="double_round_robin" value="1" id="double_round_robin"><label class="form-check-label" for="double_round_robin">Ida y vuelta</label></div></div>
    </div>
    <div class="mt-4 d-flex gap-2"><button class="btn btn-primary">Crear borrador</button><a href="{{ route('admin.championships.index') }}" class="btn btn-outline-secondary">Cancelar</a></div>
  </form>
</div>
@endsection
