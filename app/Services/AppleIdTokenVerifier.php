<?php

namespace App\Services;

use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;

/**
 * Verifies an Apple identity token using Apple's rotating JWKS keys.
 *
 * Apple tokens must never be trusted from their decoded payload alone. The
 * signature, issuer, audience, lifetime and nonce are all verified here.
 */
class AppleIdTokenVerifier
{
    private const ISSUER = 'https://appleid.apple.com';

    /** @return array<string,mixed> */
    public function verify(string $token, ?string $nonce = null): array
    {
        $parts = explode('.', $token);
        abort_unless(count($parts) === 3, 422, 'Token de Apple inválido.');

        $header = $this->decodeJson($parts[0]);
        $claims = $this->decodeJson($parts[1]);
        abort_unless(is_array($header) && is_array($claims), 422, 'Token de Apple inválido.');
        abort_unless(($header['alg'] ?? null) === 'RS256', 422, 'Algoritmo Apple no permitido.');

        $kid = (string) ($header['kid'] ?? '');
        abort_if($kid === '', 422, 'Token de Apple sin key id.');
        $certificate = $this->certificateFor($kid);
        abort_unless($certificate !== null, 422, 'No se encontró la clave pública de Apple.');

        $signature = $this->base64UrlDecode($parts[2]);
        abort_unless($signature !== '', 422, 'Firma Apple inválida.');
        $verified = openssl_verify($parts[0] . '.' . $parts[1], $signature, $certificate, OPENSSL_ALGO_SHA256);
        abort_unless($verified === 1, 422, 'Firma Apple inválida.');

        $now = now()->timestamp;
        $skew = (int) config('social_auth.clock_skew_seconds', 300);
        abort_unless(($claims['iss'] ?? null) === self::ISSUER, 422, 'Issuer inválido para token de Apple.');
        abort_unless(in_array((string) ($claims['aud'] ?? ''), $this->allowedAudiences(), true), 422, 'El token de Apple no coincide con el client_id configurado.');
        abort_unless(isset($claims['exp']) && is_numeric($claims['exp']) && (int) $claims['exp'] >= ($now - $skew), 422, 'Token de Apple expirado.');
        abort_unless(isset($claims['iat']) && is_numeric($claims['iat']) && (int) $claims['iat'] <= ($now + $skew), 422, 'Token de Apple inválido por fecha de emisión.');
        abort_unless(trim((string) ($claims['sub'] ?? '')) !== '', 422, 'Token de Apple sin subject.');

        $requireNonce = (bool) config('social_auth.apple_require_nonce', true);
        if ($requireNonce) {
            abort_unless(is_string($nonce) && $nonce !== '', 422, 'nonce de Apple es requerido.');
            $claimNonce = (string) ($claims['nonce'] ?? '');
            $hashedNonce = hash('sha256', $nonce);
            abort_unless($claimNonce !== '' && (hash_equals($hashedNonce, $claimNonce) || hash_equals($nonce, $claimNonce)), 422, 'nonce de Apple inválido.');
        }

        return $claims;
    }

    /** @return array<int,string> */
    private function allowedAudiences(): array
    {
        $configured = config('social_auth.apple_audiences', []);
        $audiences = is_array($configured) ? $configured : [];
        $audiences[] = (string) config('services.apple.client_id', '');

        return array_values(array_unique(array_filter(array_map('trim', $audiences))));
    }

    private function certificateFor(string $kid): ?string
    {
        $keys = $this->keys();
        $key = collect($keys)->first(fn (array $item) => ($item['kid'] ?? null) === $kid);
        if (!$key) {
            Cache::forget('social_auth:apple_jwks');
            $key = collect($this->keys())->first(fn (array $item) => ($item['kid'] ?? null) === $kid);
        }

        $x5c = $key['x5c'][0] ?? null;
        if (!is_string($x5c) || $x5c === '') {
            return null;
        }

        return "-----BEGIN CERTIFICATE-----\n" . chunk_split($x5c, 64, "\n") . "-----END CERTIFICATE-----\n";
    }

    /** @return array<int,array<string,mixed>> */
    private function keys(): array
    {
        return Cache::remember('social_auth:apple_jwks', now()->addHours(6), function (): array {
            $response = Http::acceptJson()->timeout(10)->get('https://appleid.apple.com/auth/keys');
            abort_unless($response->successful() && is_array($response->json('keys')), 503, 'No se pudieron obtener las claves públicas de Apple.');

            return $response->json('keys');
        });
    }

    /** @return array<string,mixed>|null */
    private function decodeJson(string $value): ?array
    {
        $decoded = json_decode($this->base64UrlDecode($value), true);

        return is_array($decoded) ? $decoded : null;
    }

    private function base64UrlDecode(string $value): string
    {
        $remainder = strlen($value) % 4;
        if ($remainder) {
            $value .= str_repeat('=', 4 - $remainder);
        }

        return base64_decode(strtr($value, '-_', '+/'), true) ?: '';
    }
}
