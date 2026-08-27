<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Admin\BackofficeController;
use App\Http\Controllers\Admin\ChampionshipController;
use App\Http\Controllers\WellKnownController;
use App\Http\Controllers\PublicLandingController;

Route::get('/', [PublicLandingController::class, 'landing'])->name('home');
Route::get('/soporte', [PublicLandingController::class, 'support'])->name('support');
Route::get('/privacidad', [PublicLandingController::class, 'privacy'])->name('privacy');
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
    Route::get('/fields', [BackofficeController::class, 'fields'])->name('fields.index');
    Route::post('/fields', [BackofficeController::class, 'storeField'])->middleware('throttle:admin-web-mutations')->name('fields.store');
    Route::put('/fields/{field}', [BackofficeController::class, 'updateField'])->middleware('throttle:admin-web-mutations')->name('fields.update');
    Route::put('/courts/{cancha}', [BackofficeController::class, 'updateCourt'])->middleware('throttle:admin-web-mutations')->name('courts.update');

    Route::get('/strikes', [BackofficeController::class, 'strikes'])->name('strikes.index');
    Route::post('/strikes', [BackofficeController::class, 'issueStrike'])->middleware('throttle:admin-web-mutations')->name('strikes.issue');
    Route::post('/strikes/{strike}/revoke', [BackofficeController::class, 'revokeStrike'])->middleware('throttle:admin-web-mutations')->name('strikes.revoke');
    Route::post('/strikes/bulk-revoke', [BackofficeController::class, 'bulkRevokeStrikes'])->middleware('throttle:admin-web-mutations')->name('strikes.bulk-revoke');
    Route::post('/users/{user}/suspension', [BackofficeController::class, 'setUserSuspension'])->middleware('throttle:admin-web-mutations')->name('users.suspension');

    Route::get('/metrics/growth', [BackofficeController::class, 'metricsGrowth'])->name('metrics.growth');
    Route::get('/ops/readiness', [BackofficeController::class, 'opsReadiness'])->name('ops.readiness');

  });

// Championship operations are scoped independently from the generic
// backoffice. Superadmins can create and discover all championships; delegated
// managers can operate only the championship permissions they were granted.
Route::prefix('admin')
  ->name('admin.')
  ->middleware(['auth'])
  ->group(function () {
    Route::get('/championships', [ChampionshipController::class, 'index'])->name('championships.index');
    Route::get('/championships/create', [ChampionshipController::class, 'create'])->name('championships.create');
    Route::get('/championships/groups/search', [ChampionshipController::class, 'searchGroups'])->name('championships.groups.search');
    Route::get('/championships/users/search', [ChampionshipController::class, 'searchUsers'])->name('championships.users.search');
    Route::post('/championships', [ChampionshipController::class, 'store'])->middleware('throttle:admin-web-mutations')->name('championships.store');
    Route::get('/championships/{championship}', [ChampionshipController::class, 'show'])->name('championships.show');
    Route::post('/championships/{championship}/fixture/generate', [ChampionshipController::class, 'generateFixture'])->middleware('throttle:admin-web-mutations')->name('championships.fixture.generate');
    Route::post('/championships/{championship}/publish', [ChampionshipController::class, 'publish'])->middleware('throttle:admin-web-mutations')->name('championships.publish');
    Route::put('/championships/{championship}/groups', [ChampionshipController::class, 'updateGroups'])->middleware('throttle:admin-web-mutations')->name('championships.groups.update');
    Route::post('/championships/{championship}/admins', [ChampionshipController::class, 'storeAdmin'])->middleware('throttle:admin-web-mutations')->name('championships.admins.store');
    Route::delete('/championships/{championship}/admins/{admin}', [ChampionshipController::class, 'destroyAdmin'])->middleware('throttle:admin-web-mutations')->name('championships.admins.destroy');
    Route::delete('/championships/{championship}', [ChampionshipController::class, 'destroy'])->middleware('throttle:admin-web-mutations')->name('championships.destroy');
    Route::post('/championships/{championship}/teams', [ChampionshipController::class, 'storeTeam'])->middleware('throttle:admin-web-mutations')->name('championships.teams.store');
    Route::post('/championship-teams/{team}/captain', [ChampionshipController::class, 'setCaptain'])->middleware('throttle:admin-web-mutations')->name('championships.teams.captain');
    Route::post('/championship-teams/{team}/members/invite', [ChampionshipController::class, 'inviteTeamMember'])->middleware('throttle:admin-web-mutations')->name('championships.teams.members.invite');
    Route::post('/championship-matchdays/{matchday}/schedule', [ChampionshipController::class, 'scheduleMatchday'])->middleware('throttle:admin-web-mutations')->name('championships.matchdays.schedule');
    Route::post('/championship-matches/{match}/schedule', [ChampionshipController::class, 'scheduleMatch'])->middleware('throttle:admin-web-mutations')->name('championships.matches.schedule');
    Route::post('/championship-matches/{match}/result', [ChampionshipController::class, 'recordResult'])->middleware('throttle:admin-web-mutations')->name('championships.matches.result');
  });
