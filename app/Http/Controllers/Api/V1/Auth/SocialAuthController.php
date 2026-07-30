<?php

namespace App\Http\Controllers\Api\V1\Auth;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Services\ProductEventService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Str;
use Illuminate\Validation\Rule;

class SocialAuthController extends Controller
{
    public function __construct(private readonly ProductEventService $eventService)
    {
    }

    public function login(Request $request)
    {
        $data = $request->validate([
            'provider' => ['required', Rule::in(['google', 'apple'])],
            'id_token' => ['nullable', 'string'],
            'provider_uid' => ['nullable', 'string', 'max:191'],
            'email' => ['nullable', 'email', 'max:255'],
            'name' => ['nullable', 'string', 'max:255'],
            'avatar_url' => ['nullable', 'string', 'max:500'],
            'device_name' => ['nullable', 'string', 'max:100'],
        ]);

        $identity = $this->resolveIdentity($data);
        $provider = $data['provider'];

        $providerUid = trim((string) ($identity['provider_uid'] ?? ''));
        $email = mb_strtolower(trim((string) ($identity['email'] ?? '')));
        $name = trim((string) ($identity['name'] ?? ($data['name'] ?? '')));
        $avatarUrl = trim((string) ($identity['avatar_url'] ?? ($data['avatar_url'] ?? '')));

        abort_if($providerUid === '', 422, 'No se pudo validar la identidad del proveedor.');

        $user = User::query()
            ->where('auth_provider', $provider)
            ->where('provider_uid', $providerUid)
            ->first();

        if (!$user && $email !== '') {
            $user = User::whereRaw('LOWER(email) = ?', [$email])->first();
        }

        if (!$user) {
            $user = new User();
            $user->name = $name !== '' ? $name : ucfirst($provider) . ' User';
            $user->email = $email !== '' ? $email : "{$provider}_{$providerUid}@fulbii.local";
            $user->password = Str::random(64);
            if (Schema::hasColumn('users', 'estado')) {
                $user->estado = '1';
            }
        }

        if (Schema::hasColumn('users', 'auth_provider')) {
            $user->auth_provider = $provider;
        }
        if (Schema::hasColumn('users', 'provider_uid')) {
            $user->provider_uid = $providerUid;
        }
        if ($avatarUrl !== '' && Schema::hasColumn('users', 'avatar_url')) {
            $user->avatar_url = $avatarUrl;
        }
        if ($name !== '' && empty($user->name)) {
            $user->name = $name;
        }
        if ($email !== '' && empty($user->email)) {
            $user->email = $email;
        }

        $user->save();

        $deviceName = trim((string) ($data['device_name'] ?? 'mobile-app'));
        $token = $user->createToken($deviceName)->plainTextToken;

        $needsOnboarding = empty($user->nick) || (Schema::hasColumn('users', 'sexo') && empty($user->sexo));

        $this->eventService->track(
            'auth_social_login_success',
            (int) $user->id,
            null,
            null,
            [
                'provider' => $provider,
                'needs_onboarding' => $needsOnboarding,
                'trusted_mode' => (bool) config('social_auth.trusted_mode'),
            ],
            'auth'
        );

        return response()->json([
            'token_type' => 'Bearer',
            'access_token' => $token,
            'needs_onboarding' => $needsOnboarding,
            'is_suspended' => $user->isSuspended(),
            'suspended_until' => optional($user->suspended_until)->toISOString(),
            'user' => $user->fresh(),
            'auth_mode' => config('social_auth.trusted_mode') ? 'trusted_mode' : 'verified_mode',
        ]);
    }

    public function logout(Request $request)
    {
        $user = $request->user() ?? abort(401);
        $token = $user->currentAccessToken();
        if ($token) {
            $token->delete();
        }

        return response()->json(['message' => 'Sesión cerrada.']);
    }

    private function resolveIdentity(array $data): array
    {
        $provider = $data['provider'];
        $trustedMode = (bool) config('social_auth.trusted_mode', false);

        if ($trustedMode) {
            return [
                'provider_uid' => $data['provider_uid'] ?? null,
                'email' => $data['email'] ?? null,
                'name' => $data['name'] ?? null,
                'avatar_url' => $data['avatar_url'] ?? null,
            ];
        }

        if ($provider === 'google') {
            return $this->resolveGoogleIdentity($data['id_token'] ?? null);
        }

        return $this->resolveAppleIdentityUnverified($data['id_token'] ?? null, $data['email'] ?? null);
    }

    private function resolveGoogleIdentity(?string $idToken): array
    {
        abort_if(empty($idToken), 422, 'id_token de Google es requerido.');

        $response = Http::timeout(10)->get('https://oauth2.googleapis.com/tokeninfo', [
            'id_token' => $idToken,
        ]);

        abort_unless($response->ok(), 422, 'Token de Google inválido.');

        $payload = $response->json();
        $aud = (string) ($payload['aud'] ?? '');
        $configuredClient = (string) config('services.google.client_id', '');
        if ($configuredClient !== '' && $aud !== $configuredClient) {
            abort(422, 'El token de Google no coincide con el client_id configurado.');
        }

        return [
            'provider_uid' => $payload['sub'] ?? null,
            'email' => $payload['email'] ?? null,
            'name' => $payload['name'] ?? null,
            'avatar_url' => $payload['picture'] ?? null,
        ];
    }

    private function resolveAppleIdentityUnverified(?string $idToken, ?string $email): array
    {
        abort_if(empty($idToken), 422, 'id_token de Apple es requerido.');

        $parts = explode('.', $idToken);
        abort_if(count($parts) < 2, 422, 'Token de Apple inválido.');

        $payload = json_decode($this->base64UrlDecode($parts[1]), true);
        abort_if(!is_array($payload), 422, 'No se pudo decodificar token de Apple.');

        $issuer = (string) ($payload['iss'] ?? '');
        abort_if($issuer !== 'https://appleid.apple.com', 422, 'Issuer inválido para token de Apple.');

        $configuredClient = (string) config('services.apple.client_id', '');
        $aud = (string) ($payload['aud'] ?? '');
        if ($configuredClient !== '' && $aud !== '' && $aud !== $configuredClient) {
            abort(422, 'El token de Apple no coincide con el client_id configurado.');
        }

        return [
            'provider_uid' => $payload['sub'] ?? null,
            'email' => $payload['email'] ?? $email,
            'name' => null,
            'avatar_url' => null,
        ];
    }

    private function base64UrlDecode(string $value): string
    {
        $remainder = strlen($value) % 4;
        if ($remainder) {
            $value .= str_repeat('=', 4 - $remainder);
        }

        return base64_decode(strtr($value, '-_', '+/')) ?: '';
    }
}
