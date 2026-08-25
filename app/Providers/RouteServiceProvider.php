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
            return Limit::perMinute(60)
                ->by($this->rateLimitKey($request))
                ->response(fn (Request $request, array $headers) => $this->tooManyAttemptsResponse(
                    'Demasiadas solicitudes. Espera unos segundos e inténtalo nuevamente.',
                    $request,
                    $headers,
                ));
        });

        RateLimiter::for('social-auth-login', function (Request $request) {
            $provider = (string) $request->input('provider', 'unknown');
            return Limit::perMinute(20)
                ->by($request->ip() . '|' . mb_strtolower($provider))
                ->response(fn (Request $request, array $headers) => $this->tooManyAttemptsResponse(
                    'Demasiados intentos de inicio de sesión social. Intenta en unos minutos.',
                    $request,
                    $headers,
                ));
        });

        RateLimiter::for('onboarding', function (Request $request) {
            return Limit::perMinute(12)
                ->by($this->rateLimitKey($request))
                ->response(fn (Request $request, array $headers) => $this->tooManyAttemptsResponse(
                    'Demasiados avances de onboarding en poco tiempo. Intenta nuevamente en breve.',
                    $request,
                    $headers,
                ));
        });

        RateLimiter::for('nickname-availability', function (Request $request) {
            return Limit::perMinute(20)
                ->by($this->rateLimitKey($request))
                ->response(fn (Request $request, array $headers) => $this->tooManyAttemptsResponse(
                    'Demasiadas consultas de nickname. Espera unos segundos e inténtalo nuevamente.',
                    $request,
                    $headers,
                ));
        });

        RateLimiter::for('club-join', function (Request $request) {
            return Limit::perMinute(6)
                ->by($this->rateLimitKey($request))
                ->response(fn (Request $request, array $headers) => $this->tooManyAttemptsResponse(
                    'Demasiadas solicitudes de ingreso en poco tiempo. Intenta nuevamente en breve.',
                    $request,
                    $headers,
                ));
        });

        RateLimiter::for('report-create', function (Request $request) {
            return Limit::perMinute(12)
                ->by((string) ($request->user()?->id ?: $request->ip()))
                ->response(fn (Request $request, array $headers) => $this->tooManyAttemptsResponse('Has enviado demasiados reportes en poco tiempo.', $request, $headers));
        });

        RateLimiter::for('field-submission-create', function (Request $request) {
            return Limit::perMinute(8)
                ->by((string) ($request->user()?->id ?: $request->ip()))
                ->response(fn (Request $request, array $headers) => $this->tooManyAttemptsResponse('Has enviado demasiadas solicitudes de cancha en poco tiempo.', $request, $headers));
        });

        RateLimiter::for('geo-lookup', function (Request $request) {
            return Limit::perMinute(30)
                ->by((string) ($request->user()?->id ?: $request->ip()))
                ->response(fn (Request $request, array $headers) => $this->tooManyAttemptsResponse('Demasiadas búsquedas de dirección. Intenta nuevamente en breve.', $request, $headers));
        });

        RateLimiter::for('pichanga-sensitive', function (Request $request) {
            return Limit::perMinute(20)
                ->by((string) ($request->user()?->id ?: $request->ip()))
                ->response(fn (Request $request, array $headers) => $this->tooManyAttemptsResponse('Demasiadas acciones sensibles de pichanga. Intenta nuevamente en breve.', $request, $headers));
        });

        RateLimiter::for('admin-mutations', function (Request $request) {
            return Limit::perMinute(30)
                ->by((string) ($request->user()?->id ?: $request->ip()))
                ->response(fn (Request $request, array $headers) => $this->tooManyAttemptsResponse('Límite de operaciones administrativas alcanzado. Intenta nuevamente en breve.', $request, $headers));
        });

        RateLimiter::for('admin-web-mutations', function (Request $request) {
            return Limit::perMinute(60)
                ->by((string) ($request->user()?->id ?: $request->ip()))
                ->response(fn (Request $request, array $headers) => $this->tooManyAttemptsResponse('Límite de operaciones administrativas del panel alcanzado.', $request, $headers));
        });

        RateLimiter::for('watch-session-create', function (Request $request) {
            return Limit::perMinute((int) config('watch.create_per_minute', 6))
                ->by((string) ($request->user()?->id ?: $request->ip()))
                ->response(fn (Request $request, array $headers) => $this->tooManyAttemptsResponse('Demasiadas sesiones Watch creadas en poco tiempo.', $request, $headers));
        });

        RateLimiter::for('watch-samples', function (Request $request) {
            return Limit::perMinute((int) config('watch.sample_batches_per_minute', 12))
                ->by((string) ($request->user()?->id ?: $request->ip()))
                ->response(fn (Request $request, array $headers) => $this->tooManyAttemptsResponse('Demasiados lotes de ubicación Watch en poco tiempo.', $request, $headers));
        });

        RateLimiter::for('watch-events', function (Request $request) {
            return Limit::perMinute((int) config('watch.event_batches_per_minute', 20))
                ->by((string) ($request->user()?->id ?: $request->ip()))
                ->response(fn (Request $request, array $headers) => $this->tooManyAttemptsResponse('Demasiados eventos Watch en poco tiempo.', $request, $headers));
        });

        RateLimiter::for('profile-media-upload', function (Request $request) {
            return Limit::perMinute(4)
                ->by((string) ($request->user()?->id ?: $request->ip()))
                ->response(fn (Request $request, array $headers) => $this->tooManyAttemptsResponse('Demasiadas cargas de contenido multimedia en poco tiempo.', $request, $headers));
        });

        $this->routes(function () {
            Route::middleware('api')
                ->prefix('api')
                ->group(base_path('routes/api.php'));

            Route::middleware('web')
                ->group(base_path('routes/web.php'));
        });
    }

    private function rateLimitKey(Request $request): string
    {
        $token = trim((string) $request->bearerToken());

        return $token !== ''
            ? 'token:'.hash('sha256', $token)
            : 'ip:'.$request->ip();
    }

    private function tooManyAttemptsResponse(string $message, ?Request $request = null, array $headers = [])
    {
        if ($request && !$request->expectsJson()) {
            return response($message, 429, $headers);
        }

        return response()->json([
            'message' => $message,
            'error' => 'rate_limited',
            'status' => 429,
        ], 429, $headers);
    }
}
