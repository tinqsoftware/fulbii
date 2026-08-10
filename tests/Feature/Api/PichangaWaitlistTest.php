<?php

namespace Tests\Feature\Api;

use App\Models\User;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Laravel\Sanctum\Sanctum;
use Tests\Feature\Concerns\UsesInMemorySqlite;
use Tests\TestCase;

class PichangaWaitlistTest extends TestCase
{
    use UsesInMemorySqlite;

    protected function setUp(): void
    {
        parent::setUp();
        $this->bootInMemorySqlite();
        Schema::create('users', function (Blueprint $table) {
            $table->id();
            $table->string('name')->nullable();
            $table->string('email')->nullable();
            $table->string('password')->nullable();
            $table->dateTime('suspended_until')->nullable();
            $table->string('suspension_reason')->nullable();
            $table->timestamps();
        });
        Schema::create('clubs', function (Blueprint $table) {
            $table->id();
            $table->string('nombre')->nullable();
            $table->tinyInteger('estado')->default(1);
            $table->timestamps();
        });
        Schema::create('club_user', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('club_id');
            $table->unsignedBigInteger('user_id');
            $table->string('rol')->default('miembro');
            $table->tinyInteger('estado')->default(1);
            $table->timestamps();
        });
        Schema::create('group_pichangas', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('club_id');
            $table->string('status')->default('published');
            $table->dateTime('starts_at');
            $table->integer('capacity');
            $table->integer('team_count')->default(2);
            $table->timestamps();
        });
        Schema::create('group_pichanga_participants', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('pichanga_id');
            $table->unsignedBigInteger('user_id');
            $table->string('status');
            $table->string('team_code')->nullable();
            $table->integer('team_slot')->nullable();
            $table->timestamps();
        });
        Schema::create('group_pichanga_waitlist', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('pichanga_id');
            $table->unsignedBigInteger('user_id');
            $table->string('team_code')->nullable();
            $table->string('status');
            $table->dateTime('promoted_at')->nullable();
            $table->dateTime('withdrawn_at')->nullable();
            $table->timestamps();
        });
    }

    public function test_member_can_join_and_leave_full_pichanga_waitlist(): void
    {
        $confirmed = User::query()->create(['id' => 1, 'name' => 'Confirmed', 'email' => 'confirmed@test.com']);
        $waiting = User::query()->create(['id' => 2, 'name' => 'Waiting', 'email' => 'waiting@test.com']);
        \DB::table('clubs')->insert(['id' => 10, 'nombre' => 'Club', 'estado' => 1, 'created_at' => now(), 'updated_at' => now()]);
        \DB::table('club_user')->insert([
            ['club_id' => 10, 'user_id' => $confirmed->id, 'rol' => 'miembro', 'estado' => 1, 'created_at' => now(), 'updated_at' => now()],
            ['club_id' => 10, 'user_id' => $waiting->id, 'rol' => 'miembro', 'estado' => 1, 'created_at' => now(), 'updated_at' => now()],
        ]);
        \DB::table('group_pichangas')->insert(['id' => 30, 'club_id' => 10, 'status' => 'confirmed', 'starts_at' => now()->addDay(), 'capacity' => 1, 'team_count' => 2, 'created_at' => now(), 'updated_at' => now()]);
        \DB::table('group_pichanga_participants')->insert(['pichanga_id' => 30, 'user_id' => $confirmed->id, 'status' => 'confirmed', 'created_at' => now(), 'updated_at' => now()]);

        Sanctum::actingAs($waiting);
        $this->postJson('/api/v1/pichangas/30/waitlist', ['team_code' => 'A'])
            ->assertOk()->assertJsonPath('position', 1);
        $this->assertDatabaseHas('group_pichanga_waitlist', ['pichanga_id' => 30, 'user_id' => 2, 'status' => 'waiting']);
        $this->deleteJson('/api/v1/pichangas/30/waitlist')->assertOk();
        $this->assertDatabaseHas('group_pichanga_waitlist', ['pichanga_id' => 30, 'user_id' => 2, 'status' => 'withdrawn']);
    }

    public function test_withdrawal_promotes_first_waiting_member(): void
    {
        $confirmed = User::query()->create(['id' => 11, 'name' => 'Confirmed', 'email' => 'confirmed2@test.com']);
        $waiting = User::query()->create(['id' => 12, 'name' => 'Waiting', 'email' => 'waiting2@test.com']);
        \DB::table('clubs')->insert(['id' => 20, 'nombre' => 'Club', 'estado' => 1, 'created_at' => now(), 'updated_at' => now()]);
        \DB::table('club_user')->insert([
            ['club_id' => 20, 'user_id' => $confirmed->id, 'rol' => 'admin', 'estado' => 1, 'created_at' => now(), 'updated_at' => now()],
            ['club_id' => 20, 'user_id' => $waiting->id, 'rol' => 'miembro', 'estado' => 1, 'created_at' => now(), 'updated_at' => now()],
        ]);
        \DB::table('group_pichangas')->insert(['id' => 40, 'club_id' => 20, 'status' => 'confirmed', 'starts_at' => now()->addDay(), 'capacity' => 1, 'team_count' => 2, 'created_at' => now(), 'updated_at' => now()]);
        \DB::table('group_pichanga_participants')->insert(['pichanga_id' => 40, 'user_id' => $confirmed->id, 'status' => 'confirmed', 'team_code' => 'A', 'team_slot' => 1, 'created_at' => now(), 'updated_at' => now()]);
        \DB::table('group_pichanga_waitlist')->insert(['pichanga_id' => 40, 'user_id' => $waiting->id, 'team_code' => 'B', 'status' => 'waiting', 'created_at' => now(), 'updated_at' => now()]);

        Sanctum::actingAs($confirmed);
        $this->assertDatabaseHas('group_pichanga_participants', ['pichanga_id' => 40, 'user_id' => $confirmed->id, 'status' => 'confirmed']);
        $this->postJson('/api/v1/pichangas/40/withdraw')->assertOk();
        $this->assertDatabaseHas('group_pichanga_waitlist', ['pichanga_id' => 40, 'user_id' => $waiting->id, 'status' => 'promoted']);
        $this->assertDatabaseHas('group_pichanga_participants', ['pichanga_id' => 40, 'user_id' => $waiting->id, 'status' => 'confirmed']);
    }
}
