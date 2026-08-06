<?php

namespace Tests\Feature\Api;

use App\Models\User;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Laravel\Sanctum\Sanctum;
use Tests\Feature\Concerns\UsesInMemorySqlite;
use Tests\TestCase;

class JoinRequestsFlowTest extends TestCase
{
    use UsesInMemorySqlite;

    protected function setUp(): void
    {
        parent::setUp();
        $this->bootInMemorySqlite();
        $this->createSchema();
    }

    public function test_join_request_can_be_created_cancelled_and_accepted(): void
    {
        $requester = User::query()->create([
            'name' => 'Requester',
            'email' => 'requester@test.com',
            'password' => 'secret',
        ]);

        $admin = User::query()->create([
            'name' => 'Admin',
            'email' => 'admin@test.com',
            'password' => 'secret',
        ]);

        $clubId = 10;
        \DB::table('clubs')->insert([
            'id' => $clubId,
            'nombre' => 'Club One',
            'slug' => 'club-one',
            'estado' => 1,
            'is_visible' => 1,
            'join_code' => 'ABCDEF123456',
            'link_join_enabled' => 1,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        \DB::table('club_user')->insert([
            'club_id' => $clubId,
            'user_id' => $admin->id,
            'rol' => 'admin',
            'estado' => 1,
            'created_at' => now(),
            'updated_at' => now(),
        ]);
        \DB::table('club_user')->insert([
            'club_id' => $clubId,
            'user_id' => $requester->id,
            'rol' => 'miembro',
            'estado' => 0,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        Sanctum::actingAs($requester);
        $response = $this->postJson('/api/v1/clubs/join/ABCDEF123456/request');
        $response->assertCreated();
        $requestId = (int) $response->json('request.id');
        $this->assertDatabaseHas('club_join_requests', [
            'id' => $requestId,
            'status' => 'pending',
        ]);
        $this->getJson('/api/v1/clubs?scope=discover')
            ->assertOk()
            ->assertJsonPath('items.0.has_pending_join_request', true);
        $this->getJson("/api/v1/clubs/{$clubId}")
            ->assertOk()
            ->assertJsonPath('club.has_pending_join_request', true);

        $cancel = $this->postJson("/api/v1/clubs/{$clubId}/join-requests/{$requestId}/cancel");
        $cancel->assertOk()->assertJson(['message' => 'Solicitud cancelada.']);
        $this->assertDatabaseHas('club_join_requests', [
            'id' => $requestId,
            'status' => 'cancelled',
        ]);
        $this->getJson('/api/v1/clubs?scope=discover')
            ->assertOk()
            ->assertJsonPath('items.0.has_pending_join_request', false);

        $second = $this->postJson('/api/v1/clubs/join/ABCDEF123456/request');
        $second->assertCreated();
        $secondRequestId = (int) $second->json('request.id');

        Sanctum::actingAs($admin);
        $decide = $this->postJson(
            "/api/v1/clubs/{$clubId}/join-requests/{$secondRequestId}/decision",
            ['action' => 'accept']
        );
        $decide->assertOk()->assertJson(['message' => 'Solicitud aceptada.']);

        $this->assertDatabaseHas('club_join_requests', [
            'id' => $secondRequestId,
            'status' => 'accepted',
        ]);
        $this->assertDatabaseHas('club_user', [
            'club_id' => $clubId,
            'user_id' => $requester->id,
            'rol' => 'miembro',
            'estado' => 1,
        ]);
    }

    public function test_hidden_or_closed_groups_reject_search_and_link_requests(): void
    {
        $requester = User::query()->create([
            'name' => 'Requester',
            'email' => 'requester-closed@test.com',
            'password' => 'secret',
        ]);

        \DB::table('clubs')->insert([
            [
                'id' => 20,
                'nombre' => 'Closed club',
                'slug' => 'closed-club',
                'estado' => 1,
                'is_visible' => 1,
                'join_code' => 'CLOSED123456',
                'link_join_enabled' => 0,
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'id' => 21,
                'nombre' => 'Hidden club',
                'slug' => 'hidden-club',
                'estado' => 1,
                'is_visible' => 0,
                'join_code' => 'HIDDEN123456',
                'link_join_enabled' => 1,
                'created_at' => now(),
                'updated_at' => now(),
            ],
        ]);

        Sanctum::actingAs($requester);

        $this->postJson('/api/v1/clubs/20/join-requests')->assertNotFound();
        $this->postJson('/api/v1/clubs/join/CLOSED123456/request')->assertNotFound();
        $this->postJson('/api/v1/clubs/21/join-requests')->assertNotFound();
        $this->postJson('/api/v1/clubs/join/HIDDEN123456/request')->assertNotFound();
    }

    public function test_disabled_groups_reject_all_new_join_requests(): void
    {
        $requester = User::query()->create([
            'name' => 'Requester',
            'email' => 'requester-disabled@test.com',
            'password' => 'secret',
        ]);

        \DB::table('clubs')->insert([
            'id' => 30,
            'nombre' => 'Disabled club',
            'slug' => 'disabled-club',
            'estado' => 0,
            'is_visible' => 1,
            'join_code' => 'DISABLED1234',
            'link_join_enabled' => 1,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        Sanctum::actingAs($requester);

        $this->postJson('/api/v1/clubs/30/join-requests')
            ->assertStatus(409)
            ->assertJson(['code' => 'club_inactive']);
        $this->postJson('/api/v1/clubs/join/DISABLED1234/request')
            ->assertStatus(409);
    }

    private function createSchema(): void
    {
        Schema::create('users', function (Blueprint $table) {
            $table->id();
            $table->string('name')->nullable();
            $table->string('email')->nullable();
            $table->string('password')->nullable();
            $table->timestamp('email_verified_at')->nullable();
            $table->string('remember_token', 100)->nullable();
            $table->date('fec_nac')->nullable();
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

        Schema::create('clubs', function (Blueprint $table) {
            $table->id();
            $table->string('nombre', 150);
            $table->string('slug', 160);
            $table->tinyInteger('estado')->default(1);
            $table->boolean('is_visible')->default(true);
            $table->char('join_code', 12)->nullable();
            $table->boolean('link_join_enabled')->default(true);
            $table->timestamps();
        });

        Schema::create('club_user', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('club_id');
            $table->unsignedBigInteger('user_id');
            $table->enum('rol', ['admin', 'miembro'])->default('miembro');
            $table->tinyInteger('estado')->default(1);
            $table->timestamps();
            $table->unique(['club_id', 'user_id']);
        });

        Schema::create('club_join_requests', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('club_id');
            $table->unsignedBigInteger('requester_user_id');
            $table->enum('requested_via', ['search', 'link'])->default('search');
            $table->enum('status', ['pending', 'accepted', 'rejected', 'cancelled', 'expired'])->default('pending');
            $table->dateTime('requested_at')->nullable();
            $table->dateTime('decided_at')->nullable();
            $table->unsignedBigInteger('decided_by_user_id')->nullable();
            $table->string('note')->nullable();
            $table->timestamps();
        });

        Schema::create('product_events', function (Blueprint $table) {
            $table->id();
            $table->string('event_name', 80);
            $table->unsignedBigInteger('user_id')->nullable();
            $table->unsignedBigInteger('club_id')->nullable();
            $table->unsignedBigInteger('pichanga_id')->nullable();
            $table->string('source', 40)->default('api');
            $table->text('metadata_json')->nullable();
            $table->dateTime('happened_at');
            $table->timestamps();
        });
    }
}
