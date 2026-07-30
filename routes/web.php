<?php

use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\Auth;
use Illuminate\Http\Request;
use App\Models\User;

use App\Http\Controllers\Admin\BackofficeController;
use App\Http\Controllers\WellKnownController;
use App\Http\Controllers\Mapa;
use App\Http\Controllers\{ ClubController, CalificacionController, MiPerfilController, UsuarioController };

Route::get('/', [Mapa::class, 'mapa'])->name('home');
Route::get('/mapa', fn() => redirect()->route('home'))->name('mapa');
Route::prefix('.well-known')->group(function () {
  Route::get('/apple-app-site-association', [WellKnownController::class, 'appleAppSiteAssociation'])
    ->name('well-known.aasa');
  Route::get('/assetlinks.json', [WellKnownController::class, 'assetLinks'])
    ->name('well-known.assetlinks');
});

Route::get('/join/{joinCode}', function (string $joinCode) {
  $code = strtoupper(trim($joinCode));
  abort_if($code === '', 404);

  $appLink = "fulbii://join/{$code}";
  $baseUrl = rtrim((string) config('services.app_links.base_url', config('app.url')), '/');
  $canonical = "{$baseUrl}/join/{$code}";
  $androidStore = (string) config('services.app_links.android_store_url', '');
  $iosStore = (string) config('services.app_links.ios_store_url', '');

  return response(
    '<!doctype html>
<html lang="es">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <title>Fulbii - Ingreso por link</title>
  <link rel="canonical" href="' . e($canonical) . '">
  <style>
    body { font-family: Arial, sans-serif; padding: 24px; max-width: 520px; margin: 0 auto; }
    .btn { display: inline-block; margin-right: 8px; margin-bottom: 8px; padding: 10px 14px; border-radius: 8px; text-decoration: none; background: #0d7a3f; color: #fff; }
    .btn.alt { background: #334155; }
  </style>
</head>
<body>
  <h1>Unirte a un grupo en Fulbii</h1>
  <p>Código de ingreso: <strong>' . e($code) . '</strong></p>
  <p>Si tienes la app, se abrirá automáticamente.</p>
  <p><a class="btn" href="' . e($appLink) . '">Abrir app</a></p>
  <p>Si no tienes la app, instala y vuelve a abrir este link.</p>' .
    ($androidStore !== '' ? '<p><a class="btn alt" href="' . e($androidStore) . '">Android</a></p>' : '') .
    ($iosStore !== '' ? '<p><a class="btn alt" href="' . e($iosStore) . '">iPhone</a></p>' : '') .
    '<script>
      setTimeout(function(){ window.location.href = "' . e($appLink) . '"; }, 350);
    </script>
</body>
</html>',
    200,
    ['Content-Type' => 'text/html; charset=UTF-8']
  );
})->name('join.link');

Route::get('/pichanga/{pichangaId}', function (int $pichangaId) {
  abort_if($pichangaId <= 0, 404);

  $appLink = "fulbii://pichanga/{$pichangaId}";
  $baseUrl = rtrim((string) config('services.app_links.base_url', config('app.url')), '/');
  $canonical = "{$baseUrl}/pichanga/{$pichangaId}";
  $androidStore = (string) config('services.app_links.android_store_url', '');
  $iosStore = (string) config('services.app_links.ios_store_url', '');

  return response(
    '<!doctype html>
<html lang="es">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <title>Fulbii - Pichanga</title>
  <link rel="canonical" href="' . e($canonical) . '">
  <style>
    body { font-family: Arial, sans-serif; padding: 24px; max-width: 560px; margin: 0 auto; }
    .btn { display: inline-block; margin-right: 8px; margin-bottom: 8px; padding: 10px 14px; border-radius: 8px; text-decoration: none; background: #0d7a3f; color: #fff; }
    .btn.alt { background: #334155; }
  </style>
</head>
<body>
  <h1>Ver pichanga en Fulbii</h1>
  <p>ID de pichanga: <strong>' . e((string) $pichangaId) . '</strong></p>
  <p>Si tienes la app, se abrirá automáticamente.</p>
  <p><a class="btn" href="' . e($appLink) . '">Abrir app</a></p>
  <p>Si no tienes la app, instala y vuelve a abrir este link.</p>' .
    ($androidStore !== '' ? '<p><a class="btn alt" href="' . e($androidStore) . '">Android</a></p>' : '') .
    ($iosStore !== '' ? '<p><a class="btn alt" href="' . e($iosStore) . '">iPhone</a></p>' : '') .
    '<script>
      setTimeout(function(){ window.location.href = "' . e($appLink) . '"; }, 350);
    </script>
</body>
</html>',
    200,
    ['Content-Type' => 'text/html; charset=UTF-8']
  );
})->whereNumber('pichangaId')->name('pichanga.link');

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

Route::prefix('admin')
  ->name('admin.')
  ->middleware(['auth', 'admin.backoffice'])
  ->group(function () {
    Route::get('/', [BackofficeController::class, 'dashboard'])->name('dashboard');
    Route::get('/reports', [BackofficeController::class, 'reports'])->name('reports.index');
    Route::post('/reports/{report}/resolve', [BackofficeController::class, 'resolveReport'])->middleware('throttle:admin-web-mutations')->name('reports.resolve');
    Route::post('/reports/bulk-resolve', [BackofficeController::class, 'bulkResolveReports'])->middleware('throttle:admin-web-mutations')->name('reports.bulk-resolve');

    Route::get('/field-submissions', [BackofficeController::class, 'fieldSubmissions'])->name('field-submissions.index');
    Route::post('/field-submissions/{submission}/decision', [BackofficeController::class, 'decideFieldSubmission'])->middleware('throttle:admin-web-mutations')->name('field-submissions.decide');
    Route::post('/field-submissions/bulk-decision', [BackofficeController::class, 'bulkDecisionFieldSubmissions'])->middleware('throttle:admin-web-mutations')->name('field-submissions.bulk-decision');

    Route::get('/strikes', [BackofficeController::class, 'strikes'])->name('strikes.index');
    Route::post('/strikes', [BackofficeController::class, 'issueStrike'])->middleware('throttle:admin-web-mutations')->name('strikes.issue');
    Route::post('/strikes/{strike}/revoke', [BackofficeController::class, 'revokeStrike'])->middleware('throttle:admin-web-mutations')->name('strikes.revoke');
    Route::post('/strikes/bulk-revoke', [BackofficeController::class, 'bulkRevokeStrikes'])->middleware('throttle:admin-web-mutations')->name('strikes.bulk-revoke');
    Route::post('/users/{user}/suspension', [BackofficeController::class, 'setUserSuspension'])->middleware('throttle:admin-web-mutations')->name('users.suspension');

    Route::get('/metrics/growth', [BackofficeController::class, 'metricsGrowth'])->name('metrics.growth');
    Route::get('/ops/readiness', [BackofficeController::class, 'opsReadiness'])->name('ops.readiness');
  });
