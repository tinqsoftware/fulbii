<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\V1\Auth\SocialAuthController;
use App\Http\Controllers\Api\V1\AdminMetricsController;
use App\Http\Controllers\Api\V1\AdminModerationController;
use App\Http\Controllers\Api\V1\ClubApiController;
use App\Http\Controllers\Api\V1\ClubChallengeController;
use App\Http\Controllers\Api\V1\ChampionshipController;
use App\Http\Controllers\Api\V1\ClubInvitationApiController;
use App\Http\Controllers\Api\V1\ClubGroupChatController;
use App\Http\Controllers\Api\V1\ClubJoinRequestController;
use App\Http\Controllers\Api\V1\ClubNotificationPreferenceController;
use App\Http\Controllers\Api\V1\FieldSubmissionController;
use App\Http\Controllers\Api\V1\FieldApiController;
use App\Http\Controllers\Api\V1\FieldGeometryController;
use App\Http\Controllers\Api\V1\AdminFieldManagementController;
use App\Http\Controllers\Api\V1\GeoController;
use App\Http\Controllers\Api\V1\GroupPichangaController;
use App\Http\Controllers\Api\V1\MeDeviceController;
use App\Http\Controllers\Api\V1\MeController;
use App\Http\Controllers\Api\V1\MeNotificationController;
use App\Http\Controllers\Api\V1\MeActivityController;
use App\Http\Controllers\Api\V1\OnboardingController;
use App\Http\Controllers\Api\V1\PichangaSocialController;
use App\Http\Controllers\Api\V1\ProfileClipController;
use App\Http\Controllers\Api\V1\ReportController;
use App\Http\Controllers\Api\V1\WatchMatchSessionController;
use App\Http\Controllers\Api\V1\UserBlockController;

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
|
| Here is where you can register API routes for your application. These
| routes are loaded by the RouteServiceProvider and all of them will
| be assigned to the "api" middleware group. Make something great!
|
*/

Route::middleware('auth:sanctum')->get('/user', function (Request $request) {
    return $request->user();
});

Route::prefix('v1')->group(function () {
    Route::post('/auth/social/login', [SocialAuthController::class, 'login'])
        ->middleware('throttle:social-auth-login');
    Route::get('/users/{user}/profile-clips', [ProfileClipController::class, 'indexByUser']);
});

// Public discovery: guests can explore centres and visible groups, but every
// mutation remains in the authenticated group below.
Route::prefix('v1')->group(function () {
    Route::get('/fields', [FieldApiController::class, 'index']);
    Route::get('/fields/nearby', [FieldApiController::class, 'nearby']);
    Route::get('/fields/{field}', [FieldApiController::class, 'show']);
    Route::get('/clubs', [ClubApiController::class, 'index'])
        ->middleware('auth.optional');
    Route::get('/clubs/{club}', [ClubApiController::class, 'show'])
        ->middleware('auth.optional');
    Route::get('/clubs/{club}/members', [ClubApiController::class, 'members'])
        ->middleware('auth.optional');
    Route::get('/clubs/{club}/members/{member}/public-profile', [ClubApiController::class, 'publicMemberProfile'])
        ->middleware('auth.optional');
    Route::get('/clubs/{club}/pichangas', [GroupPichangaController::class, 'indexByClub'])
        ->middleware('auth.optional');
    Route::get('/clubs/{club}/pichangas/calendar', [GroupPichangaController::class, 'calendarByClub'])
        ->middleware('auth.optional');
    Route::get('/pichangas/{pichanga}', [GroupPichangaController::class, 'show'])
        ->middleware('auth.optional')
        // Keep reserved paths such as /pichangas/my-board from being bound as IDs.
        ->whereNumber('pichanga');
    Route::get('/pichangas/{pichanga}/match-summary', [GroupPichangaController::class, 'matchSummary'])
        ->middleware('auth.optional')
        ->whereNumber('pichanga');
    Route::get('/pichangas/map', [GroupPichangaController::class, 'map'])
        ->middleware('auth.optional');

    // Public championship discovery and read-only views. Private/link
    // championships are filtered by the controller using the optional user.
    Route::get('/championships', [ChampionshipController::class, 'index'])
        ->middleware('auth.optional');
    Route::get('/championships/{championship}', [ChampionshipController::class, 'show'])
        ->middleware('auth.optional');
    Route::get('/championships/{championship}/standings', [ChampionshipController::class, 'standings'])
        ->middleware('auth.optional');
    Route::get('/championships/{championship}/fixture', [ChampionshipController::class, 'fixture'])
        ->middleware('auth.optional');
    Route::get('/championships/{championship}/player-stats', [ChampionshipController::class, 'playerStats'])
        ->middleware('auth.optional');
    Route::get('/championship-matches/{match}', [ChampionshipController::class, 'match'])
        ->middleware('auth.optional');
});

Route::prefix('v1')->middleware('auth:sanctum')->group(function () {
    Route::post('/auth/logout', [SocialAuthController::class, 'logout']);
    Route::post('/auth/logout-all', [SocialAuthController::class, 'logoutAll']);

    Route::middleware('user.not_suspended')->group(function () {
        Route::get('/me', [MeController::class, 'show']);
        Route::put('/me', [MeController::class, 'update']);
        Route::post('/onboarding', [OnboardingController::class, 'store'])->middleware('throttle:onboarding');
        Route::get('/onboarding/nick-available', [OnboardingController::class, 'nickAvailable'])->middleware('throttle:nickname-availability');
        Route::get('/me/devices', [MeDeviceController::class, 'index']);
        Route::post('/me/devices/register', [MeDeviceController::class, 'register']);
        Route::post('/me/devices/{device}/deactivate', [MeDeviceController::class, 'deactivate']);
        Route::get('/me/notifications', [MeNotificationController::class, 'index']);
        Route::post('/me/notifications/read-all', [MeNotificationController::class, 'markAllRead']);
        Route::post('/me/notifications/{notification}/read', [MeNotificationController::class, 'markRead']);
        Route::get('/me/pichangas/history', [MeActivityController::class, 'pichangaHistory']);
        Route::get('/me/favorite-fields', [MeActivityController::class, 'favoriteFields']);
        Route::post('/me/favorite-fields/{polideportivo}', [MeActivityController::class, 'addFavoriteField']);
        Route::delete('/me/favorite-fields/{polideportivo}', [MeActivityController::class, 'removeFavoriteField']);
        Route::get('/me/profile-clips', [ProfileClipController::class, 'indexMine']);
        Route::post('/me/profile-clips', [ProfileClipController::class, 'store'])->middleware('throttle:profile-media-upload');
        Route::delete('/me/profile-clips/{clip}', [ProfileClipController::class, 'destroy']);
        Route::put('/me/profile-clips/reorder', [ProfileClipController::class, 'reorder']);
        Route::put('/fields/{field}/geometry', [FieldGeometryController::class, 'upsert']);
        Route::get('/users/search', [\App\Http\Controllers\UsuarioController::class, 'search']);
        Route::get('/rankings', [PichangaSocialController::class, 'rankings']);
        Route::get('/users/{user}/player-ranking', [PichangaSocialController::class, 'playerRanking']);
        Route::get('/users/{user}/ratings/history', [PichangaSocialController::class, 'ratingHistory']);
        Route::get('/users/{user}/ratings/eligibility', [PichangaSocialController::class, 'canRateProfile']);
        Route::post('/users/{user}/ratings', [PichangaSocialController::class, 'rateProfile']);

        Route::post('/clubs', [ClubApiController::class, 'store']);
        Route::get('/clubs/join/{joinCode}', [ClubJoinRequestController::class, 'previewByCode']);
        Route::post('/clubs/join/{joinCode}/request', [ClubJoinRequestController::class, 'requestByCode'])->middleware('throttle:club-join');
        Route::put('/clubs/{club}', [ClubApiController::class, 'update'])->middleware('club.active:club');
        Route::post('/clubs/{club}/join-requests', [ClubJoinRequestController::class, 'requestByClub'])
            ->middleware('club.active:club')
            ->middleware('throttle:club-join');
        Route::get('/clubs/{club}/join-requests', [ClubJoinRequestController::class, 'listByClub']);
        Route::post('/clubs/{club}/join-requests/{joinRequest}/decision', [ClubJoinRequestController::class, 'decide'])->middleware('club.active:club');
        Route::post('/clubs/{club}/join-requests/{joinRequest}/cancel', [ClubJoinRequestController::class, 'cancel'])->middleware('club.active:club');
        Route::post('/clubs/{club}/join-code/rotate', [ClubJoinRequestController::class, 'rotateJoinCode'])->middleware('club.active:club');
        Route::put('/clubs/{club}/members/{user}/role', [ClubApiController::class, 'setMemberRole'])->middleware('club.active:club');
        Route::delete('/clubs/{club}/members/{user}', [ClubApiController::class, 'removeMember'])->middleware('club.active:club');
        Route::get('/clubs/{club}/admin-activity', [ClubApiController::class, 'adminActivity']);

        Route::get('/challenges', [ClubChallengeController::class, 'indexMine']);
        Route::get('/clubs/{club}/challenges', [ClubChallengeController::class, 'indexByClub']);
        Route::post('/clubs/{club}/challenges', [ClubChallengeController::class, 'store'])->middleware('club.active:club');
        Route::get('/challenges/{challenge}', [ClubChallengeController::class, 'show']);
        Route::post('/challenges/{challenge}/coordinate', [ClubChallengeController::class, 'coordinate'])->middleware('club.active:challenge');
        Route::post('/challenges/{challenge}/reject', [ClubChallengeController::class, 'reject'])->middleware('club.active:challenge');
        Route::post('/challenges/{challenge}/cancel', [ClubChallengeController::class, 'cancel'])->middleware('club.active:challenge');
        Route::get('/challenges/{challenge}/messages', [ClubChallengeController::class, 'messages']);
        Route::post('/challenges/{challenge}/messages', [ClubChallengeController::class, 'sendMessage'])->middleware('club.active:challenge');
        Route::post('/challenges/{challenge}/field-options', [ClubChallengeController::class, 'proposeFieldOption'])->middleware('club.active:challenge');
        Route::post('/challenges/{challenge}/time-options', [ClubChallengeController::class, 'proposeTimeOption'])->middleware('club.active:challenge');
        Route::get('/challenges/{challenge}/configurations', [ClubChallengeController::class, 'listConfigurations']);
        Route::post('/challenges/{challenge}/configurations/propose', [ClubChallengeController::class, 'proposeConfiguration'])->middleware('club.active:challenge');
        Route::post('/challenges/{challenge}/configurations/{configuration}/decision', [ClubChallengeController::class, 'decideConfiguration'])->middleware('club.active:challenge');
        Route::put('/me/presence/chat', [ClubChallengeController::class, 'updateChatPresence']);

        Route::get('/invitations', [ClubInvitationApiController::class, 'indexMine']);
        Route::post('/clubs/{club}/invitations', [ClubInvitationApiController::class, 'store'])->middleware('club.active:club');
        Route::post('/invitations/{invitation}/respond', [ClubInvitationApiController::class, 'respond'])->middleware('club.active:invitation');
        Route::post('/invitations/{invitation}/revoke', [ClubInvitationApiController::class, 'revoke'])->middleware('club.active:invitation');

        Route::get('/clubs/{club}/chat/messages', [ClubGroupChatController::class, 'index']);
        Route::post('/clubs/{club}/chat/messages', [ClubGroupChatController::class, 'send'])->middleware('club.active:club');
        Route::post('/clubs/{club}/chat/read', [ClubGroupChatController::class, 'markRead'])->middleware('club.active:club');

        Route::get('/me/blocks', [UserBlockController::class, 'index']);
        Route::post('/users/{user}/block', [UserBlockController::class, 'store']);
        Route::delete('/users/{user}/block', [UserBlockController::class, 'destroy']);

        Route::get('/clubs/{club}/notification-preference', [ClubNotificationPreferenceController::class, 'show']);
        Route::put('/clubs/{club}/notification-preference', [ClubNotificationPreferenceController::class, 'update'])->middleware('club.active:club');
        Route::get('/clubs/{club}/notification-categories', [ClubNotificationPreferenceController::class, 'categories']);
        Route::put('/clubs/{club}/notification-categories/{category}', [ClubNotificationPreferenceController::class, 'updateCategory'])->middleware('club.active:club');

        Route::post('/clubs/{club}/pichangas', [GroupPichangaController::class, 'store'])->middleware('club.active:club');

        // Championship creation is restricted to superadmins. Managers and
        // captains receive scoped management access after the draft exists.
        Route::post('/championships', [ChampionshipController::class, 'store']);
        Route::post('/championships/{championship}/admins', [ChampionshipController::class, 'storeAdmin']);
        Route::delete('/championships/{championship}/admins/{user}', [ChampionshipController::class, 'removeAdmin']);
        Route::post('/championships/{championship}/teams', [ChampionshipController::class, 'storeTeam']);
        Route::post('/championships/{championship}/fixture/generate', [ChampionshipController::class, 'generateFixture']);
        Route::post('/championship-teams/{team}/members/invite', [ChampionshipController::class, 'inviteTeamMember']);
        Route::post('/championship-teams/{team}/captain', [ChampionshipController::class, 'setTeamCaptain']);
        Route::get('/championship-teams/{team}/members', [ChampionshipController::class, 'teamMembers']);
        Route::get('/championship-teams/{team}/invitations', [ChampionshipController::class, 'teamInvitations']);
        Route::delete('/championship-teams/{team}/members/{user}', [ChampionshipController::class, 'removeTeamMember']);
        Route::post('/championship-team-invitations/{invitation}/respond', [ChampionshipController::class, 'respondTeamInvitation']);
        Route::get('/me/championship-invitations', [ChampionshipController::class, 'myTeamInvitations']);
        Route::get('/championship-team-invitations/by-token/{token}', [ChampionshipController::class, 'invitationByToken']);
        Route::post('/championship-team-invitations/{invitation}/revoke', [ChampionshipController::class, 'revokeTeamInvitation']);
        Route::post('/championship-matchdays/{matchday}/schedule', [ChampionshipController::class, 'scheduleMatchday']);
        Route::post('/championship-matches/{match}/schedule', [ChampionshipController::class, 'scheduleMatch']);
        Route::post('/championship-matches/{match}/result', [ChampionshipController::class, 'recordResult']);
        Route::post('/championship-matches/{match}/squad', [ChampionshipController::class, 'updateSquad']);

        Route::get('/pichangas/available', [GroupPichangaController::class, 'available']);
        Route::get('/pichangas/my-board', [GroupPichangaController::class, 'myBoard']);
        Route::get('/pichangas/calendar', [GroupPichangaController::class, 'calendar']);
        Route::get('/pichangas/widget/confirmed-next', [GroupPichangaController::class, 'confirmedNextWidget']);
        Route::put('/pichangas/{pichanga}/audience', [GroupPichangaController::class, 'updateAudience'])
            ->middleware('club.active:pichanga')
            ->middleware('throttle:pichanga-sensitive');
        Route::post('/pichangas/{pichanga}/confirm', [GroupPichangaController::class, 'confirm'])->middleware('club.active:pichanga');
        Route::post('/pichangas/{pichanga}/withdraw', [GroupPichangaController::class, 'withdraw'])->middleware('club.active:pichanga');
        Route::get('/pichangas/{pichanga}/waitlist', [GroupPichangaController::class, 'waitlist']);
        Route::post('/pichangas/{pichanga}/waitlist', [GroupPichangaController::class, 'joinWaitlist'])->middleware('club.active:pichanga');
        Route::delete('/pichangas/{pichanga}/waitlist', [GroupPichangaController::class, 'leaveWaitlist'])->middleware('club.active:pichanga');
        Route::get('/pichangas/{pichanga}/teams/{teamCode}/formation-suggestion', [GroupPichangaController::class, 'formationSuggestion']);
        Route::put('/pichangas/{pichanga}/teams/{teamCode}/formation', [GroupPichangaController::class, 'updateFormation'])->middleware('club.active:pichanga');
        Route::put('/pichangas/{pichanga}/participants/{user}/team', [GroupPichangaController::class, 'moveParticipantTeam'])->middleware('club.active:pichanga');
        Route::post('/pichangas/{pichanga}/status', [GroupPichangaController::class, 'setStatus'])
            ->middleware('club.active:pichanga')
            ->middleware('throttle:pichanga-sensitive');
        Route::put('/pichangas/{pichanga}/schedule', [GroupPichangaController::class, 'updateSchedule'])
            ->middleware('club.active:pichanga')
            ->middleware('throttle:pichanga-sensitive');

        Route::post('/pichangas/{pichanga}/external-requests', [GroupPichangaController::class, 'createExternalRequest'])
            ->middleware('club.active:pichanga')
            ->middleware('throttle:pichanga-sensitive');
        Route::get('/pichangas/{pichanga}/external-requests', [GroupPichangaController::class, 'listExternalRequests']);
        Route::post('/pichangas/{pichanga}/external-requests/{externalRequest}/decision', [GroupPichangaController::class, 'decideExternalRequest'])
            ->middleware('club.active:pichanga')
            ->middleware('throttle:pichanga-sensitive');

        Route::post('/pichangas/{pichanga}/renotify/preview', [GroupPichangaController::class, 'renotifyPreview'])->middleware('club.active:pichanga');
        Route::post('/pichangas/{pichanga}/renotify/send', [GroupPichangaController::class, 'renotifySend'])
            ->middleware('club.active:pichanga')
            ->middleware('throttle:pichanga-sensitive');
        Route::get('/pichangas/{pichanga}/feed', [PichangaSocialController::class, 'feed']);
        Route::post('/pichangas/{pichanga}/feed/posts', [PichangaSocialController::class, 'addPost'])->middleware('club.active:pichanga');
        Route::delete('/pichangas/{pichanga}/feed/posts/{post}', [PichangaSocialController::class, 'removePost'])->middleware('club.active:pichanga');
        Route::post('/pichangas/{pichanga}/feed/posts/{post}/comments', [PichangaSocialController::class, 'addComment'])->middleware('club.active:pichanga');
        Route::delete('/pichangas/{pichanga}/feed/posts/{post}/comments/{comment}', [PichangaSocialController::class, 'removeComment'])->middleware('club.active:pichanga');
        Route::post('/pichangas/{pichanga}/ratings', [PichangaSocialController::class, 'addOrUpdateRating'])->middleware('club.active:pichanga');
        Route::get('/pichangas/{pichanga}/ratings', [PichangaSocialController::class, 'ratings']);

        Route::get('/reports/mine', [ReportController::class, 'indexMine']);
        Route::post('/reports', [ReportController::class, 'store'])
            ->middleware('throttle:report-create');

        Route::get('/field-submissions/mine', [FieldSubmissionController::class, 'indexMine']);
        Route::get('/geo/address-suggestions', [GeoController::class, 'suggestions'])->middleware('throttle:geo-lookup');
        Route::get('/geo/reverse', [GeoController::class, 'reverse'])->middleware('throttle:geo-lookup');
        Route::post('/field-submissions', [FieldSubmissionController::class, 'store'])
            ->middleware('throttle:field-submission-create');

        Route::prefix('/admin')->group(function () {
            Route::put('/fields/{field}', [AdminFieldManagementController::class, 'updateField'])
                ->middleware('throttle:admin-mutations');
            Route::put('/courts/{cancha}', [AdminFieldManagementController::class, 'updateCourt'])
                ->middleware('throttle:admin-mutations');
            Route::get('/metrics/growth', [AdminMetricsController::class, 'growth']);
            Route::get('/ops/release-readiness', [AdminMetricsController::class, 'releaseReadiness']);
            Route::get('/reports', [AdminModerationController::class, 'reports']);
            Route::post('/reports/{report}/resolve', [AdminModerationController::class, 'resolveReport'])->middleware('throttle:admin-mutations');
            Route::post('/reports/bulk-resolve', [AdminModerationController::class, 'bulkResolveReports'])->middleware('throttle:admin-mutations');
            Route::get('/strikes', [AdminModerationController::class, 'strikes']);
            Route::post('/strikes', [AdminModerationController::class, 'issueStrike'])->middleware('throttle:admin-mutations');
            Route::post('/strikes/{strike}/revoke', [AdminModerationController::class, 'revokeStrike'])->middleware('throttle:admin-mutations');
            Route::post('/strikes/bulk-revoke', [AdminModerationController::class, 'bulkRevokeStrikes'])->middleware('throttle:admin-mutations');
            Route::post('/users/{user}/suspension', [AdminModerationController::class, 'setUserSuspension'])->middleware('throttle:admin-mutations');

            Route::get('/field-submissions', [AdminModerationController::class, 'fieldSubmissions']);
            Route::post('/field-submissions/{submission}/decision', [AdminModerationController::class, 'decideFieldSubmission'])->middleware('throttle:admin-mutations');
            Route::post('/field-submissions/{submission}/photos/{photo}/remove', [AdminModerationController::class, 'removeFieldSubmissionPhoto'])->middleware('throttle:admin-mutations');
            Route::post('/field-submissions/bulk-decision', [AdminModerationController::class, 'bulkDecisionFieldSubmissions'])->middleware('throttle:admin-mutations');
        });

        Route::get('/users/{user}/pichanga-card', [PichangaSocialController::class, 'userCard']);

        Route::prefix('/watch')->group(function () {
            Route::get('/pichangas/home-feed', [WatchMatchSessionController::class, 'homeFeed']);
            Route::get('/match-sessions/my-active', [WatchMatchSessionController::class, 'myActive']);
            Route::get('/pichangas/{pichanga}/sessions/me', [WatchMatchSessionController::class, 'sessionsByPichangaMe']);
            Route::get('/pichangas/{pichanga}/heatmap/me', [WatchMatchSessionController::class, 'heatmapByPichangaMe']);
            Route::post('/match-sessions', [WatchMatchSessionController::class, 'store'])->middleware('throttle:watch-session-create');
            Route::post('/match-sessions/{session}/samples/batch', [WatchMatchSessionController::class, 'batchSamples'])->middleware('throttle:watch-samples');
            Route::post('/match-sessions/{session}/events/batch', [WatchMatchSessionController::class, 'batchEvents'])->middleware('throttle:watch-events');
            Route::post('/match-sessions/{session}/finish', [WatchMatchSessionController::class, 'finish']);
        });
    });
});
