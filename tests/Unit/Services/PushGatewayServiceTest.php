<?php

namespace Tests\Unit\Services;

use App\Models\UserDevice;
use App\Services\PushGatewayService;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use Tests\TestCase;

class PushGatewayServiceTest extends TestCase
{
    public function test_log_driver_returns_success_without_external_calls(): void
    {
        config()->set('push.driver', 'log');

        $service = new PushGatewayService();
        $device = $this->makeDevice(1, 'ios', 'dummy-token');

        $result = $service->send($device, 'Hola', 'Mensaje');

        $this->assertTrue($result['ok']);
        $this->assertSame('log', $result['provider']);
    }

    public function test_fcm_v1_returns_error_when_service_account_is_missing(): void
    {
        config()->set('push.driver', 'fcm');
        config()->set('push.fcm_project_id', 'fulbii');
        config()->set('push.fcm_service_account_path', '');

        $service = new PushGatewayService();
        $device = $this->makeDevice(2, 'android', 'dummy-token');

        $result = $service->send($device, 'Hola', 'Mensaje');

        $this->assertFalse($result['ok']);
        $this->assertSame('fcm_v1', $result['provider']);
        $this->assertStringContainsString('access token', (string) $result['error']);
    }

    public function test_fcm_v1_sends_message_with_bearer_token(): void
    {
        config()->set('push.driver', 'fcm');
        config()->set('push.fcm_project_id', 'fulbii-project');
        config()->set('push.fcm_scope', 'https://www.googleapis.com/auth/firebase.messaging');
        config()->set('push.fcm_token_uri', 'https://oauth2.googleapis.com/token');

        // Some local OpenSSL builds try to persist random state in an
        // unwritable home directory. A writable test-only location keeps this
        // cryptographic fixture deterministic across CI and developer Macs.
        putenv('RANDFILE=' . sys_get_temp_dir() . '/fulbii-openssl-rand');
        $privateKey = '';
        $keyResource = openssl_pkey_new([
            'private_key_bits' => 2048,
            'private_key_type' => OPENSSL_KEYTYPE_RSA,
        ]);
        $this->assertNotFalse($keyResource);
        openssl_pkey_export($keyResource, $privateKey);

        $tmpFile = tempnam(sys_get_temp_dir(), 'fcm-sa-');
        file_put_contents($tmpFile, json_encode([
            'type' => 'service_account',
            'project_id' => 'fulbii-project',
            'private_key_id' => 'abc123',
            'private_key' => $privateKey,
            'client_email' => 'firebase-adminsdk@test.iam.gserviceaccount.com',
            'client_id' => '123',
            'token_uri' => 'https://oauth2.googleapis.com/token',
        ], JSON_PRETTY_PRINT));

        config()->set('push.fcm_service_account_path', $tmpFile);
        Cache::flush();

        Http::fake([
            'https://oauth2.googleapis.com/token' => Http::response([
                'access_token' => 'token-abc',
                'expires_in' => 3600,
                'token_type' => 'Bearer',
            ], 200),
            'https://fcm.googleapis.com/v1/projects/fulbii-project/messages:send' => Http::response([
                'name' => 'projects/fulbii-project/messages/1',
            ], 200),
        ]);

        $service = new PushGatewayService();
        $device = $this->makeDevice(3, 'android', 'android-token-123');

        $result = $service->send($device, 'Titulo', 'Body', [
            'pichanga_id' => 10,
            'meta' => ['foo' => 'bar'],
        ]);

        $this->assertTrue($result['ok']);
        $this->assertSame('fcm_v1', $result['provider']);

        Http::assertSent(function ($request) {
            if (!str_contains($request->url(), '/v1/projects/fulbii-project/messages:send')) {
                return true;
            }

            $payload = $request->data();
            return $request->hasHeader('Authorization', 'Bearer token-abc')
                && ($payload['message']['token'] ?? null) === 'android-token-123'
                && ($payload['message']['data']['pichanga_id'] ?? null) === '10';
        });

        @unlink($tmpFile);
    }

    private function makeDevice(int $id, string $platform, string $token): UserDevice
    {
        $device = new UserDevice();
        $device->id = $id;
        $device->platform = $platform;
        $device->device_token = $token;

        return $device;
    }
}
