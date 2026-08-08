<?php

namespace Tests\Feature\Api;

use App\Models\User;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Laravel\Sanctum\Sanctum;
use Tests\Feature\Concerns\UsesInMemorySqlite;
use Tests\TestCase;

class ClubScopeTest extends TestCase
{
    use UsesInMemorySqlite;

    protected function setUp(): void
    {
        parent::setUp();
        $this->bootInMemorySqlite();
        $this->createSchema();
    }

    public function test_authenticated_scopes_use_only_active_memberships_and_keep_disabled_memberships_in_mine(): void
    {
        $user = $this->createUser('member@example.test');
        $otherUser = $this->createUser('other@example.test');

        $this->insertClub(1, 'Creado sin pivote', $user->id, true);
        $this->insertClub(2, 'Membresia activa', $otherUser->id, true);
        $this->insertClub(3, 'Membresia inactiva', $otherUser->id, true);
        $this->insertClub(4, 'Disponible', $otherUser->id, true);
        $this->insertClub(5, 'Oculto', $otherUser->id, false);
        $this->insertClub(6, 'Mi grupo oculto', $otherUser->id, false);
        $this->insertClub(7, 'Mi grupo desactivado', $otherUser->id, true, 0);
        $this->insertClub(8, 'Disponible desactivado', $otherUser->id, true, 0);

        $this->insertMembership(2, $user->id, 1, 'miembro');
        $this->insertMembership(3, $user->id, 0, 'miembro');
        $this->insertMembership(6, $user->id, 1, 'miembro');
        $this->insertMembership(7, $user->id, 1, 'admin');

        Sanctum::actingAs($user);

        $mine = $this->getJson('/api/v1/clubs?scope=mine')->assertOk()->json('items');
        $discover = $this->getJson('/api/v1/clubs?scope=discover')->assertOk()->json('items');

        $mineById = collect($mine)->keyBy('id');
        $discoverById = collect($discover)->keyBy('id');

        $this->assertEqualsCanonicalizing([2, 6, 7], $mineById->keys()->all());
        $this->assertEqualsCanonicalizing([1, 3, 4], $discoverById->keys()->all());
        $this->assertEmpty(array_intersect($mineById->keys()->all(), $discoverById->keys()->all()));
        $this->assertTrue($discoverById[1]['is_owner']);
        $this->assertFalse($discoverById[1]['is_member']);
        $this->assertFalse($discoverById[1]['is_mine']);
        $this->assertNull($discoverById[1]['my_role']);
        $this->assertTrue($mineById[2]['is_member']);
        $this->assertTrue($mineById[2]['is_mine']);
        $this->assertFalse($discoverById[3]['is_member']);
        $this->assertNull($discoverById[3]['my_role']);
        $this->assertFalse($mineById[7]['is_active']);
    }

    public function test_guests_only_discover_visible_clubs_and_never_receive_mine_results(): void
    {
        $owner = $this->createUser('owner@example.test');
        $this->insertClub(1, 'Visible', $owner->id, true);
        $this->insertClub(2, 'Oculto', $owner->id, false);
        $this->insertClub(3, 'Desactivado', $owner->id, true, 0);

        $this->getJson('/api/v1/clubs?scope=mine')
            ->assertOk()
            ->assertExactJson(['scope' => 'mine', 'items' => []]);

        $discover = $this->getJson('/api/v1/clubs?scope=discover')
            ->assertOk()
            ->json('items');

        $this->assertSame([1], collect($discover)->pluck('id')->all());
        $this->assertFalse($discover[0]['is_mine']);
        $this->assertNull($discover[0]['my_role']);
    }

    public function test_club_lists_include_future_pichanga_activity_and_my_confirmation(): void
    {
        $user = $this->createUser('pichanga-member@example.test');
        $owner = $this->createUser('pichanga-owner@example.test');
        $this->insertClub(1, 'Mi grupo activo', $owner->id, true);
        $this->insertClub(2, 'Grupo para descubrir', $owner->id, true);
        $this->insertMembership(1, $user->id, 1, 'miembro');

        DB::table('group_pichangas')->insert([
            ['id' => 10, 'club_id' => 1, 'starts_at' => now()->addDays(2), 'status' => 'published', 'is_open' => 1],
            ['id' => 11, 'club_id' => 1, 'starts_at' => now()->addDays(3), 'status' => 'confirmed', 'is_open' => 0],
            ['id' => 12, 'club_id' => 1, 'starts_at' => now()->subDay(), 'status' => 'published', 'is_open' => 1],
            ['id' => 13, 'club_id' => 1, 'starts_at' => now()->addDays(4), 'status' => 'cancelled', 'is_open' => 1],
            ['id' => 20, 'club_id' => 2, 'starts_at' => now()->addDays(2), 'status' => 'published', 'is_open' => 1],
        ]);
        DB::table('group_pichanga_participants')->insert([
            'pichanga_id' => 11,
            'user_id' => $user->id,
            'status' => 'confirmed',
        ]);

        Sanctum::actingAs($user);

        $mine = $this->getJson('/api/v1/clubs?scope=mine')->assertOk()->json('items.0');
        $discover = $this->getJson('/api/v1/clubs?scope=discover')->assertOk()->json('items.0');

        $this->assertSame(2, $mine['pending_pichangas_count']);
        $this->assertSame(1, $mine['open_pichangas_count']);
        $this->assertTrue($mine['has_my_confirmed_pichanga']);
        $this->assertSame(1, $discover['pending_pichangas_count']);
        $this->assertSame(1, $discover['open_pichangas_count']);
        $this->assertFalse($discover['has_my_confirmed_pichanga']);
    }

    public function test_active_member_can_read_a_disabled_club_but_cannot_mutate_it(): void
    {
        $user = $this->createUser('disabled-member@example.test');
        $this->insertClub(1, 'Mi grupo desactivado', $user->id, true, 0);
        $this->insertMembership(1, $user->id, 1, 'admin');

        Sanctum::actingAs($user);

        $this->getJson('/api/v1/clubs/1')
            ->assertOk()
            ->assertJsonPath('club.is_active', false)
            ->assertJsonPath('membership.is_member', true);

        $this->putJson('/api/v1/clubs/1', ['nombre' => 'No debe cambiar'])
            ->assertStatus(409)
            ->assertJson(['code' => 'club_inactive']);
    }

    public function test_public_member_profile_is_contextual_and_never_returns_private_fields(): void
    {
        $owner = $this->createUser('owner-profile@example.test');
        $member = $this->createUser('member-profile@example.test');
        $this->insertClub(1, 'Grupo visible', $owner->id, true);
        $this->insertClub(2, 'Grupo privado', $owner->id, false);
        $this->insertMembership(1, $member->id, 1, 'miembro');
        $this->insertMembership(2, $member->id, 1, 'miembro');

        $this->getJson("/api/v1/clubs/1/members/{$member->id}/public-profile")
            ->assertOk()
            ->assertJsonPath('member.id', $member->id)
            ->assertJsonPath('member.rol', 'miembro')
            ->assertJsonMissingPath('member.email')
            ->assertJsonMissingPath('member.fec_nac')
            ->assertJsonMissingPath('member.altura_cm');

        $this->getJson("/api/v1/clubs/2/members/{$member->id}/public-profile")
            ->assertNotFound();

        Sanctum::actingAs($member);
        $this->getJson("/api/v1/clubs/2/members/{$member->id}/public-profile")
            ->assertOk();
    }

    private function createUser(string $email): User
    {
        return User::query()->create([
            'name' => $email,
            'email' => $email,
            'password' => 'secret',
        ]);
    }

    private function insertClub(int $id, string $name, int $createdBy, bool $visible, int $state = 1): void
    {
        DB::table('clubs')->insert([
            'id' => $id,
            'nombre' => $name,
            'slug' => "club-{$id}",
            'created_by' => $createdBy,
            'estado' => $state,
            'is_visible' => $visible,
            'created_at' => now(),
            'updated_at' => now(),
        ]);
    }

    private function insertMembership(int $clubId, int $userId, int $state, string $role): void
    {
        DB::table('club_user')->insert([
            'club_id' => $clubId,
            'user_id' => $userId,
            'rol' => $role,
            'estado' => $state,
            'created_at' => now(),
            'updated_at' => now(),
        ]);
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
            $table->unsignedBigInteger('created_by')->nullable();
            $table->tinyInteger('estado')->default(1);
            $table->boolean('is_visible')->default(true);
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

        Schema::create('group_pichangas', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('club_id');
            $table->string('title')->nullable();
            $table->dateTime('starts_at');
            $table->string('status');
            $table->boolean('is_open')->default(false);
        });

        Schema::create('group_pichanga_participants', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('pichanga_id');
            $table->unsignedBigInteger('user_id');
            $table->string('status');
        });
    }
}
