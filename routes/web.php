<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Admin\BackofficeController;
use App\Http\Controllers\WellKnownController;
use App\Http\Controllers\PublicLandingController;

Route::get('/', [PublicLandingController::class, 'landing'])->name('home');
Route::redirect('/mapa', '/')->name('mapa');
Route::prefix('.well-known')->group(function () {
  Route::get('/apple-app-site-association', [WellKnownController::class, 'appleAppSiteAssociation'])
    ->name('well-known.aasa');
  Route::get('/assetlinks.json', [WellKnownController::class, 'assetLinks'])
    ->name('well-known.assetlinks');
});

Route::get('/join/{joinCode}', [PublicLandingController::class, 'join'])->name('join.link');
Route::get('/pichanga/{pichangaId}', [PublicLandingController::class, 'pichanga'])
  ->whereNumber('pichangaId')->name('pichanga.link');
Route::get('/club/{clubId}', [PublicLandingController::class, 'club'])
  ->whereNumber('clubId')->name('club.share');

Auth::routes(['register' => false]);

// The mobile app is the source of truth for player workflows. Keep the old
// controllers available in the codebase, but do not expose their legacy rating
// or membership mutations through the public web surface.
Route::get('/mi-perfil', [PublicLandingController::class, 'appOnly'])->name('mi-perfil.show');
Route::get('/canchas', [PublicLandingController::class, 'appOnly'])->name('canchas.index');
Route::get('/pichangas', [PublicLandingController::class, 'appOnly'])->name('pichangas.index');
Route::get('/clubs/{legacy?}', [PublicLandingController::class, 'appOnly'])
  ->where('legacy', '.*')->name('clubs.legacy');
Route::get('/usuarios/{legacy?}', [PublicLandingController::class, 'appOnly'])
  ->where('legacy', '.*')->name('users.legacy');
Route::match(['post', 'put', 'patch', 'delete'], '/mi-perfil/{legacy?}', [PublicLandingController::class, 'unavailable'])
  ->where('legacy', '.*');
Route::match(['post', 'put', 'patch', 'delete'], '/clubs/{legacy?}', [PublicLandingController::class, 'unavailable'])
  ->where('legacy', '.*');
Route::match(['post', 'put', 'patch', 'delete'], '/usuarios/{legacy?}', [PublicLandingController::class, 'unavailable'])
  ->where('legacy', '.*');
Route::match(['post', 'put', 'patch', 'delete'], '/calificaciones/{legacy?}', [PublicLandingController::class, 'unavailable'])
  ->where('legacy', '.*');

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
