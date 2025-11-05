<?php

use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\Auth;
use Illuminate\Http\Request;
use App\Models\User;

use App\Http\Controllers\Mapa;
use App\Http\Controllers\{ ClubController, CalificacionController, MiPerfilController, UsuarioController };

Route::get('/', [Mapa::class, 'mapa'])->name('home');
Route::get('/mapa', fn() => redirect()->route('home'))->name('mapa');

Auth::routes();

Route::get('/nick/available', [MiPerfilController::class, 'nickavailable'])->name('nick.available');

Route::get('/mi-perfil', [MiPerfilController::class, 'show'])->name('mi-perfil.show');
Route::post('/mi-perfil', [MiPerfilController::class, 'update'])->name('mi-perfil.update');
Route::post('/mi-perfil/calificaciones/{calificacion}/ocultar', [MiPerfilController::class, 'ocultar'])->name('mi-perfil.calificaciones.ocultar');

// Actualizar nick (con validación y unicidad)
Route::post('/mi-perfil/nick', function(Request $r){
  $u = auth()->user() ?? abort(401);
  $data = $r->validate([
    'nick' => ['required','regex:/^[A-Za-z0-9_\-]{3,20}$/','unique:users,nick,'.$u->id],
  ]);
  $u->update(['nick' => $data['nick']]);
  return back()->with('ok','Nick actualizado');
})->name('mi-perfil.nick');

// Actualizar email (doble ingreso validado en front; en back unicidad)
Route::post('/mi-perfil/email', function(Request $r){
  $u = auth()->user() ?? abort(401);
  $data = $r->validate([
    'email' => ['required','email','unique:users,email,'.$u->id],
  ]);
  $u->update(['email' => $data['email']]);
  return back()->with('ok','Correo actualizado');
})->name('mi-perfil.email');

// Actualizar contraseña (usa cast 'hashed' del modelo User)

Route::post('/mi-perfil/password', function(Request $r){
  $u = auth()->user() ?? abort(401);
  $data = $r->validate([
    'password' => ['required','string','min:8','confirmed'],
  ]);
  $u->update(['password' => $data['password']]);
  return back()->with('ok','Contraseña actualizada');
})->name('mi-perfil.password');

Route::post('/mi-perfil/autocalificacion', [MiPerfilController::class, 'autocalificacionUpsert'])->name('mi-perfil.autocalificacion');

Route::resource('clubs', ClubController::class);
Route::prefix('clubs/{club}')->name('clubs.')->group(function(){
  Route::get('/miembros', [ClubController::class,'miembros'])->name('miembros');
  Route::post('/miembros', [ClubController::class,'agregarMiembro'])->name('miembros.agregar');
  Route::delete('/miembros/{user}', [ClubController::class,'removerMiembro'])->name('miembros.remover');
  Route::post('/miembros/{user}/set-admin', [ClubController::class,'setAdmin'])->name('miembros.set-admin');
  Route::post('/calificar', [CalificacionController::class,'store'])->name('calificar');
  Route::get('/calificaciones/{user}', [CalificacionController::class,'history'])->name('calificaciones.history');
  Route::get('/can-rate/{user}', [CalificacionController::class,'canRate'])->name('can-rate');
});

Route::delete('/calificaciones/{calificacion}', [CalificacionController::class,'destroy'])->name('calificaciones.destroy');
Route::post('/calificaciones/{calificacion}/silenciar', [CalificacionController::class,'silenciar'])->name('calificaciones.silenciar');

Route::get('/usuarios', [UsuarioController::class,'index'])->name('usuarios.index');
Route::get('/usuarios/{usuario}/edit', [UsuarioController::class,'edit'])->name('usuarios.edit');
Route::put('/usuarios/{usuario}', [UsuarioController::class,'update'])->name('usuarios.update');
Route::delete('/usuarios/{usuario}', [UsuarioController::class,'destroy'])->name('usuarios.destroy');
Route::get('/usuarios/search', [UsuarioController::class,'search'])->name('users.search');

Route::view('/canchas','stubs.canchas')->name('canchas.index');
Route::view('/pichangas','stubs.pichangas')->name('pichangas.index');
