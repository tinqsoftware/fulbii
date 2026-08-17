<?php

namespace Tests\Unit\Services;

use App\Services\AppleIdTokenVerifier;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use Symfony\Component\HttpKernel\Exception\HttpException;
use Tests\TestCase;

class AppleIdTokenVerifierTest extends TestCase
{
    public function test_it_accepts_a_valid_apple_jwt_with_matching_nonce(): void
    {
        config()->set('services.apple.client_id', 'com.fulbii');
        config()->set('social_auth.apple_require_nonce', true);
        config()->set('social_auth.clock_skew_seconds', 0);
        [$privateKey, $x5c] = $this->certificate();
        Http::fake(['https://appleid.apple.com/auth/keys' => Http::response(['keys' => [[
            'kid' => 'test-kid', 'alg' => 'RS256', 'x5c' => [$x5c],
        ]]])]);
        Cache::forget('social_auth:apple_jwks');

        $claims = app(AppleIdTokenVerifier::class)->verify($this->token($privateKey, [
            'iss' => 'https://appleid.apple.com',
            'aud' => 'com.fulbii',
            'sub' => 'apple-user-id',
            'iat' => now()->timestamp,
            'exp' => now()->addMinutes(5)->timestamp,
            'nonce' => hash('sha256', 'raw-nonce'),
        ]), 'raw-nonce');

        $this->assertSame('apple-user-id', $claims['sub']);
    }

    public function test_it_rejects_an_expired_apple_jwt_even_when_its_signature_is_valid(): void
    {
        config()->set('services.apple.client_id', 'com.fulbii');
        config()->set('social_auth.apple_require_nonce', false);
        config()->set('social_auth.clock_skew_seconds', 0);
        [$privateKey, $x5c] = $this->certificate();
        Http::fake(['https://appleid.apple.com/auth/keys' => Http::response(['keys' => [[
            'kid' => 'test-kid', 'alg' => 'RS256', 'x5c' => [$x5c],
        ]]])]);
        Cache::forget('social_auth:apple_jwks');

        $this->expectException(HttpException::class);
        app(AppleIdTokenVerifier::class)->verify($this->token($privateKey, [
            'iss' => 'https://appleid.apple.com',
            'aud' => 'com.fulbii',
            'sub' => 'apple-user-id',
            'iat' => now()->subMinutes(10)->timestamp,
            'exp' => now()->subSecond()->timestamp,
        ]));
    }

    /** @return array{string,string} */
    private function certificate(): array
    {
        // OpenSSL on some macOS installations persists entropy state to HOME,
        // which is intentionally read-only in the test sandbox.
        putenv('RANDFILE=' . sys_get_temp_dir() . '/fulbii-openssl-rand');
        $key = openssl_pkey_new(['private_key_bits' => 2048, 'private_key_type' => OPENSSL_KEYTYPE_RSA]);
        $csr = openssl_csr_new(['commonName' => 'fulbii-test'], $key);
        $certificate = openssl_csr_sign($csr, null, $key, 1);
        openssl_pkey_export($key, $privateKey);
        openssl_x509_export($certificate, $certificatePem);
        $x5c = preg_replace('/-----[^-]+-----|\s+/', '', $certificatePem);

        return [$privateKey, (string) $x5c];
    }

    /** @param array<string,mixed> $claims */
    private function token(string $privateKey, array $claims): string
    {
        $header = $this->base64Url(json_encode(['alg' => 'RS256', 'kid' => 'test-kid']));
        $payload = $this->base64Url(json_encode($claims));
        openssl_sign("{$header}.{$payload}", $signature, $privateKey, OPENSSL_ALGO_SHA256);

        return "{$header}.{$payload}." . $this->base64Url($signature);
    }

    private function base64Url(string $value): string
    {
        return rtrim(strtr(base64_encode($value), '+/', '-_'), '=');
    }
}
