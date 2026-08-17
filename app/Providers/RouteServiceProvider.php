<?php

namespace App\Providers;

use Illuminate\Cache\RateLimiting\Limit;
use Illuminate\Foundation\Support\Providers\RouteServiceProvider as ServiceProvider;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Support\Facades\Route;

class RouteServiceProvider extends ServiceProvider
{
    /**
     * The path to your application's "home" route.
     *
     * Typically, users are redirected here after authentication.
     *
     * @var string
     */
    public const HOME = '/';

    /**
     * Define your route model bindings, pattern filters, and other route configuration.
     */
    public function boot(): void
    {
        RateLimiter::for('api', function (Request $request) {
            return Limit::perMinute(60)->by($request->user()?->id ?: $request->ip());
        });

        RateLimiter::for('social-auth-login', function (Request $request) {
            $provider = (string) $request->input('provider', 'unknown');
            return Limit::perMinute(20)
                ->by($request->ip() . '|' . mb_strtolower($provider))
                ->response(fn () => $this->tooManyAttemptsResponse('Demasiados intentos de inicio de sesión social. Intenta en unos minutos.', $request));
        });

        RateLimiter::for('report-create', function (Request $request) {
            return Limit::perMinute(12)
                ->by((string) ($request->user()?->id ?: $request->ip()))
                ->response(fn () => $this->tooManyAttemptsResponse('Has enviado demasiados reportes en poco tiempo.', $request));
        });

        RateLimiter::for('field-submission-create', function (Request $request) {
            return Limit::perMinute(8)
                ->by((string) ($request->user()?->id ?: $request->ip()))
                ->response(fn () => $this->tooManyAttemptsResponse('Has enviado demasiadas solicitudes de cancha en poco tiempo.', $request));
        });

        RateLimiter::for('geo-lookup', function (Request $request) {
            return Limit::perMinute(30)
                ->by((string) ($request->user()?->id ?: $request->ip()))
                ->response(fn () => $this->tooManyAttemptsResponse('Demasiadas búsquedas de dirección. Intenta nuevamente en breve.', $request));
        });

        RateLimiter::for('pichanga-sensitive', function (Request $request) {
            return Limit::perMinute(20)
                ->by((string) ($request->user()?->id ?: $request->ip()))
                ->response(fn () => $this->tooManyAttemptsResponse('Demasiadas acciones sensibles de pichanga. Intenta nuevamente en breve.', $request));
        });

        RateLimiter::for('admin-mutations', function (Request $request) {
            return Limit::perMinute(30)
                ->by((string) ($request->user()?->id ?: $request->ip()))
                ->response(fn () => $this->tooManyAttemptsResponse('Límite de operaciones administrativas alcanzado. Intenta nuevamente en breve.', $request));
        });

        RateLimiter::for('admin-web-mutations', function (Request $request) {
            return Limit::perMinute(60)
                ->by((string) ($request->user()?->id ?: $request->ip()))
                ->response(fn () => $this->tooManyAttemptsResponse('Límite de operaciones administrativas del panel alcanzado.', $request));
        });

        RateLimiter::for('watch-session-create', function (Request $request) {
            return Limit::perMinute((int) config('watch.create_per_minute', 6))
                ->by((string) ($request->user()?->id ?: $request->ip()))
                ->response(fn () => $this->tooManyAttemptsResponse('Demasiadas sesiones Watch creadas en poco tiempo.', $request));
        });

        RateLimiter::for('watch-samples', function (Request $request) {
            return Limit::perMinute((int) config('watch.sample_batches_per_minute', 12))
                ->by((string) ($request->user()?->id ?: $request->ip()))
                ->response(fn () => $this->tooManyAttemptsResponse('Demasiados lotes de ubicación Watch en poco tiempo.', $request));
        });

        RateLimiter::for('watch-events', function (Request $request) {
            return Limit::perMinute((int) config('watch.event_batches_per_minute', 20))
                ->by((string) ($request->user()?->id ?: $request->ip()))
                ->response(fn () => $this->tooManyAttemptsResponse('Demasiados eventos Watch en poco tiempo.', $request));
        });

        RateLimiter::for('profile-media-upload', function (Request $request) {
            return Limit::perMinute(4)
                ->by((string) ($request->user()?->id ?: $request->ip()))
                ->response(fn () => $this->tooManyAttemptsResponse('Demasiadas cargas de contenido multimedia en poco tiempo.', $request));
        });

        $this->routes(function () {
            Route::middleware('api')
                ->prefix('api')
                ->group(base_path('routes/api.php'));

            Route::middleware('web')
                ->group(base_path('routes/web.php'));
        });
    }

    private function tooManyAttemptsResponse(string $message, ?Request $request = null)
    {
        if ($request && !$request->expectsJson()) {
            return response($message, 429);
        }

        return response()->json([
            'message' => $message,
            'error' => 'rate_limited',
            'status' => 429,
        ], 429);
    }
}
