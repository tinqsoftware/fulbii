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
    }
}
