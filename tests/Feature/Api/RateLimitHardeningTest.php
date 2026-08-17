<?php

namespace Tests\Feature\Api;

use App\Models\User;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Laravel\Sanctum\Sanctum;
use Tests\Feature\Concerns\UsesInMemorySqlite;
use Tests\TestCase;

class RateLimitHardeningTest extends TestCase
{
    use UsesInMemorySqlite;

    protected function setUp(): void
    {
        parent::setUp();
        $this->bootInMemorySqlite();
        $this->createSchema();
    }

    public function test_social_auth_login_rate_limit_returns_429_payload(): void
    {
        for ($i = 0; $i < 20; $i++) {
            $this->withServerVariables(['REMOTE_ADDR' => '10.1.0.5'])
                ->postJson('/api/v1/auth/social/login', [])
                ->assertStatus(422);
        }

        $blocked = $this->withServerVariables(['REMOTE_ADDR' => '10.1.0.5'])
            ->postJson('/api/v1/auth/social/login', []);

        $blocked->assertStatus(429);
        $blocked->assertJsonPath('error', 'rate_limited');
        $blocked->assertJsonPath('status', 429);
    }

    public function test_apple_login_rejects_an_unsigned_token_before_creating_a_session(): void
    {
        config()->set('social_auth.trusted_mode', false);
        config()->set('social_auth.apple_require_nonce', true);
        $header = rtrim(strtr(base64_encode(json_encode(['alg' => 'none', 'kid' => 'fake'])), '+/', '-_'), '=');
        $payload = rtrim(strtr(base64_encode(json_encode(['iss' => 'https://appleid.apple.com', 'sub' => 'victim'])), '+/', '-_'), '=');

        $this->postJson('/api/v1/auth/social/login', [
            'provider' => 'apple',
            'id_token' => "{$header}.{$payload}.",
            'nonce' => 'nonce-that-must-not-be-trusted',
        ])->assertStatus(422);
    }

    public function test_social_tokens_expire_and_logout_all_revokes_every_session(): void
    {
        config()->set('social_auth.trusted_mode', true);
        config()->set('sanctum.expiration', 60);
        config()->set('sanctum.max_tokens_per_user', 2);

        $first = $this->postJson('/api/v1/auth/social/login', [
            'provider' => 'google',
            'provider_uid' => 'trusted-local-user',
            'email' => 'trusted@test.com',
            'device_name' => 'iPhone de prueba',
        ])->assertOk();

        $this->assertDatabaseCount('personal_access_tokens', 1);
        $this->assertNotNull(\DB::table('personal_access_tokens')->value('expires_at'));

        $this->withToken($first->json('access_token'))
            ->postJson('/api/v1/auth/logout-all')
            ->assertOk();

        $this->assertDatabaseCount('personal_access_tokens', 0);
    }

    public function test_trusted_mode_is_refused_outside_local_and_testing_environments(): void
    {
        config()->set('social_auth.trusted_mode', true);
        $this->app->instance('env', 'production');

        try {
            $this->postJson('/api/v1/auth/social/login', [
                'provider' => 'google',
                'provider_uid' => 'forged-production-user',
                'email' => 'forged@example.test',
            ])->assertStatus(503);

            $this->assertDatabaseCount('users', 0);
        } finally {
            $this->app->instance('env', 'testing');
        }
    }

    public function test_admin_mutation_rate_limit_returns_429_payload(): void
    {
        $super = User::query()->create([
            'id' => 501,
            'name' => 'Super',
            'email' => 'super-rate@test.com',
            'password' => 'secret',
        ]);

        $profileId = \DB::table('perfil')->insertGetId([
            'nombre' => 'superadmin',
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        \DB::table('user_perfil')->insert([
            'id_user' => $super->id,
            'id_perfil' => $profileId,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        Sanctum::actingAs($super);

        for ($i = 0; $i < 30; $i++) {
            $this->postJson('/api/v1/admin/reports/bulk-resolve', [
                'ids' => [1],
            ])->assertStatus(422);
        }

        $blocked = $this->postJson('/api/v1/admin/reports/bulk-resolve', [
            'ids' => [1],
        ]);

        $blocked->assertStatus(429);
        $blocked->assertJsonPath('error', 'rate_limited');
        $blocked->assertJsonPath('status', 429);
    }

    private function createSchema(): void
    {
        Schema::create('users', function (Blueprint $table) {
            $table->id();
            $table->string('name')->nullable();
            $table->string('email')->nullable();
            $table->string('password')->nullable();
            $table->dateTime('suspended_until')->nullable();
            $table->string('suspension_reason')->nullable();
            $table->timestamps();
        });

        Schema::create('perfil', function (Blueprint $table) {
            $table->id();
            $table->string('nombre');
            $table->timestamps();
        });

        Schema::create('user_perfil', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('id_user');
            $table->unsignedBigInteger('id_perfil');
            $table->timestamps();
        });

        Schema::create('personal_access_tokens', function (Blueprint $table) {
            $table->id();
            $table->string('tokenable_type');
            $table->unsignedBigInteger('tokenable_id');
            $table->string('name');
            $table->string('token', 64)->unique();
            $table->text('abilities')->nullable();
            $table->timestamp('last_used_at')->nullable();
            $table->timestamp('expires_at')->nullable();
            $table->timestamps();
        });
    }
}
