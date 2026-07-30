<?php

namespace App\Services;

use App\Models\UserDevice;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class PushGatewayService
{
    /**
     * @param array<string,mixed> $data
     * @return array{ok:bool,provider:string,response:string,error:?string}
     */
    public function send(UserDevice $device, string $title, string $body, array $data = []): array
    {
        $driver = (string) config('push.driver', 'log');

        if ($driver === 'fcm') {
            return $this->sendViaFcmV1($device, $title, $body, $data);
        }

        Log::info('push.log_driver', [
            'device_id' => $device->id,
            'platform' => $device->platform,
            'title' => $title,
            'body' => $body,
            'data' => $data,
        ]);

        return [
            'ok' => true,
            'provider' => 'log',
            'response' => 'logged',
            'error' => null,
        ];
    }

    /**
     * @param array<string,mixed> $data
     * @return array{ok:bool,provider:string,response:string,error:?string}
     */
    private function sendViaFcmV1(UserDevice $device, string $title, string $body, array $data = []): array
    {
        $projectId = trim((string) config('push.fcm_project_id', ''));
        if ($projectId === '') {
            return [
                'ok' => false,
                'provider' => 'fcm_v1',
                'response' => '',
                'error' => 'FCM_PROJECT_ID no configurado.',
            ];
        }

        try {
            $accessToken = $this->getAccessToken();
            if ($accessToken === '') {
                return [
                    'ok' => false,
                    'provider' => 'fcm_v1',
                    'response' => '',
                    'error' => 'No se pudo obtener access token de FCM v1.',
                ];
            }

            $message = [
                'token' => (string) $device->device_token,
                'notification' => [
                    'title' => $title,
                    'body' => $body,
                ],
                'data' => $this->stringifyData($data),
            ];

            if ($device->platform === 'android') {
                $message['android'] = ['priority' => 'high'];
            }
            if ($device->platform === 'ios') {
                $message['apns'] = ['headers' => ['apns-priority' => '10']];
            }

            $endpoint = sprintf(
                'https://fcm.googleapis.com/v1/projects/%s/messages:send',
                $projectId
            );
            $response = Http::timeout(15)
                ->withToken($accessToken)
                ->post($endpoint, ['message' => $message]);

            // Retry once with a fresh token if the token was rejected.
            if ($response->status() === 401) {
                $accessToken = $this->getAccessToken(forceRefresh: true);
                if ($accessToken !== '') {
                    $response = Http::timeout(15)
                        ->withToken($accessToken)
                        ->post($endpoint, ['message' => $message]);
                }
            }

            return [
                'ok' => $response->ok(),
                'provider' => 'fcm_v1',
                'response' => (string) $response->body(),
                'error' => $response->ok() ? null : 'FCM HTTP ' . $response->status(),
            ];
        } catch (\Throwable $e) {
            Log::warning('push.fcm_v1_exception', [
                'device_id' => $device->id,
                'platform' => $device->platform,
                'error' => $e->getMessage(),
            ]);

            return [
                'ok' => false,
                'provider' => 'fcm_v1',
                'response' => '',
                'error' => $e->getMessage(),
            ];
        }
    }

    private function getAccessToken(bool $forceRefresh = false): string
    {
        $serviceAccountPath = trim((string) config('push.fcm_service_account_path', ''));
        if ($serviceAccountPath === '') {
            Log::warning('push.fcm_v1_missing_config', ['key' => 'FCM_SERVICE_ACCOUNT_PATH']);
            return '';
        }

        $resolvedPath = $this->resolvePath($serviceAccountPath);
        if (!is_readable($resolvedPath)) {
            Log::warning('push.fcm_v1_unreadable_service_account', ['path' => $resolvedPath]);
            return '';
        }

        $raw = @file_get_contents($resolvedPath);
        $serviceAccount = is_string($raw) ? json_decode($raw, true) : null;
        if (!is_array($serviceAccount)) {
            Log::warning('push.fcm_v1_invalid_service_account_json', ['path' => $resolvedPath]);
            return '';
        }

        $clientEmail = trim((string) ($serviceAccount['client_email'] ?? ''));
        $privateKey = (string) ($serviceAccount['private_key'] ?? '');
        $tokenUri = trim((string) ($serviceAccount['token_uri'] ?? config('push.fcm_token_uri')));
        $scope = trim((string) config('push.fcm_scope', 'https://www.googleapis.com/auth/firebase.messaging'));

        if ($clientEmail === '' || $privateKey === '' || $tokenUri === '' || $scope === '') {
            Log::warning('push.fcm_v1_service_account_missing_fields');
            return '';
        }

        $cacheKey = 'push:fcm_v1:access_token:' . sha1($clientEmail . '|' . $tokenUri . '|' . $scope);

        if (!$forceRefresh) {
            $cached = Cache::get($cacheKey);
            if (is_array($cached)) {
                $token = (string) ($cached['access_token'] ?? '');
                $expiresAt = (int) ($cached['expires_at'] ?? 0);
                if ($token !== '' && $expiresAt > (time() + 60)) {
                    return $token;
                }
            }
        }

        $jwt = $this->buildJwtAssertion($clientEmail, $privateKey, $tokenUri, $scope);
        if ($jwt === '') {
            return '';
        }

        $response = Http::asForm()
            ->timeout(15)
            ->post($tokenUri, [
                'grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
                'assertion' => $jwt,
            ]);

        if (!$response->ok()) {
            Log::warning('push.fcm_v1_token_request_failed', [
                'status' => $response->status(),
                'body' => $response->body(),
            ]);
            return '';
        }

        $payload = $response->json();
        $accessToken = (string) ($payload['access_token'] ?? '');
        $expiresIn = max(120, (int) ($payload['expires_in'] ?? 3600));
        if ($accessToken === '') {
            Log::warning('push.fcm_v1_token_missing_access_token', ['payload' => $payload]);
            return '';
        }

        $expiresAt = time() + $expiresIn;
        Cache::put($cacheKey, [
            'access_token' => $accessToken,
            'expires_at' => $expiresAt,
        ], $expiresIn - 60);

        return $accessToken;
    }

    private function buildJwtAssertion(string $clientEmail, string $privateKey, string $tokenUri, string $scope): string
    {
        $issuedAt = time();
        $expiresAt = $issuedAt + 3600;

        $header = ['alg' => 'RS256', 'typ' => 'JWT'];
        $claims = [
            'iss' => $clientEmail,
            'scope' => $scope,
            'aud' => $tokenUri,
            'iat' => $issuedAt,
            'exp' => $expiresAt,
        ];

        $headerEncoded = $this->base64UrlEncode(json_encode($header, JSON_UNESCAPED_SLASHES));
        $claimsEncoded = $this->base64UrlEncode(json_encode($claims, JSON_UNESCAPED_SLASHES));
        $signingInput = $headerEncoded . '.' . $claimsEncoded;

        $signature = '';
        $ok = openssl_sign($signingInput, $signature, $privateKey, OPENSSL_ALGO_SHA256);
        if (!$ok || $signature === '') {
            Log::warning('push.fcm_v1_jwt_sign_failed');
            return '';
        }

        return $signingInput . '.' . $this->base64UrlEncode($signature);
    }

    private function base64UrlEncode(string $value): string
    {
        return rtrim(strtr(base64_encode($value), '+/', '-_'), '=');
    }

    private function resolvePath(string $path): string
    {
        if (str_starts_with($path, '/')) {
            return $path;
        }

        return base_path($path);
    }

    /**
     * @param array<string,mixed> $data
     * @return array<string,string>
     */
    private function stringifyData(array $data): array
    {
        $result = [];
        foreach ($data as $key => $value) {
            $key = trim((string) $key);
            if ($key === '') {
                continue;
            }

            if (is_scalar($value) || $value === null) {
                $result[$key] = $value === null ? '' : (string) $value;
                continue;
            }

            $result[$key] = (string) json_encode($value, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
        }

        return $result;
    }
}
