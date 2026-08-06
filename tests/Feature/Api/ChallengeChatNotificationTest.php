<?php

namespace Tests\Feature\Api;

use App\Models\User;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Queue;
use Illuminate\Support\Facades\Schema;
use Laravel\Sanctum\Sanctum;
use Tests\Feature\Concerns\UsesInMemorySqlite;
use Tests\TestCase;

class ChallengeChatNotificationTest extends TestCase
{
    use UsesInMemorySqlite;

    protected function setUp(): void
    {
        parent::setUp();
        $this->bootInMemorySqlite();
        $this->createSchema();
    }

    public function test_chat_message_notifies_only_eligible_members(): void
    {
        Queue::fake();

        $sender = User::query()->create([
            'id' => 1,
            'name' => 'Sender',
            'email' => 'sender@test.com',
            'password' => 'secret',
        ]);
        $receiver = User::query()->create([
            'id' => 2,
            'name' => 'Receiver',
            'email' => 'receiver@test.com',
            'password' => 'secret',
        ]);
        $muted = User::query()->create([
            'id' => 3,
            'name' => 'Muted',
            'email' => 'muted@test.com',
            'password' => 'secret',
        ]);
        $inChat = User::query()->create([
            'id' => 4,
            'name' => 'InChat',
            'email' => 'inchat@test.com',
            'password' => 'secret',
        ]);

        \DB::table('clubs')->insert([
            ['id' => 10, 'nombre' => 'Club A', 'slug' => 'club-a', 'estado' => 1, 'is_visible' => 1, 'created_at' => now(), 'updated_at' => now()],
            ['id' => 20, 'nombre' => 'Club B', 'slug' => 'club-b', 'estado' => 1, 'is_visible' => 1, 'created_at' => now(), 'updated_at' => now()],
        ]);

        \DB::table('club_user')->insert([
            ['club_id' => 10, 'user_id' => 1, 'rol' => 'miembro', 'estado' => 1, 'created_at' => now(), 'updated_at' => now()],
            ['club_id' => 20, 'user_id' => 2, 'rol' => 'miembro', 'estado' => 1, 'created_at' => now(), 'updated_at' => now()],
            ['club_id' => 20, 'user_id' => 3, 'rol' => 'miembro', 'estado' => 1, 'created_at' => now(), 'updated_at' => now()],
            ['club_id' => 20, 'user_id' => 4, 'rol' => 'miembro', 'estado' => 1, 'created_at' => now(), 'updated_at' => now()],
        ]);

        \DB::table('club_challenges')->insert([
            'id' => 55,
            'challenger_club_id' => 10,
            'challenged_club_id' => 20,
            'created_by_user_id' => 1,
            'coordinator_challenger_user_id' => 1,
            'team_size' => 6,
            'challenge_window' => 'next_week',
            'status' => 'negotiating',
            'expires_at' => now()->addDays(4),
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        \DB::table('user_group_notification_prefs')->insert([
            'user_id' => 3,
            'club_id' => 20,
            'mode' => 'mute_forever',
            'muted_until' => null,
            'updated_by_user' => 1,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        \DB::table('user_chat_presence')->insert([
            'user_id' => 4,
            'challenge_id' => 55,
            'is_active' => 1,
            'last_heartbeat_at' => now(),
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        Sanctum::actingAs($sender);
        $response = $this->postJson('/api/v1/challenges/55/messages', [
            'content' => 'Vamos a coordinar fecha y cancha.',
        ]);

        $response->assertCreated();
        $response->assertJsonPath('dispatch.target_count', 3);
        $response->assertJsonPath('dispatch.muted_skipped_count', 1);
        $response->assertJsonPath('dispatch.active_chat_skipped_count', 1);
        $response->assertJsonPath('dispatch.sent_count', 1);

        $this->assertDatabaseHas('push_notifications', [
            'user_id' => 2,
            'type' => 'challenge_chat_message',
        ]);
        $this->assertDatabaseMissing('push_notifications', [
            'user_id' => 1,
            'type' => 'challenge_chat_message',
        ]);
        $this->assertDatabaseMissing('push_notifications', [
            'user_id' => 3,
            'type' => 'challenge_chat_message',
        ]);
        $this->assertDatabaseMissing('push_notifications', [
            'user_id' => 4,
            'type' => 'challenge_chat_message',
        ]);
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

        Schema::create('clubs', function (Blueprint $table) {
            $table->id();
            $table->string('nombre', 150);
            $table->string('slug', 160);
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

        Schema::create('club_challenges', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('challenger_club_id');
            $table->unsignedBigInteger('challenged_club_id');
            $table->unsignedBigInteger('created_by_user_id');
            $table->unsignedBigInteger('coordinator_challenger_user_id')->nullable();
            $table->unsignedBigInteger('coordinator_challenged_user_id')->nullable();
            $table->unsignedTinyInteger('team_size')->default(6);
            $table->enum('challenge_window', ['next_week', 'next_fortnight', 'next_month'])->default('next_week');
            $table->enum('status', ['pending', 'negotiating', 'configuring', 'confirmed', 'rejected', 'cancelled', 'expired'])->default('pending');
            $table->dateTime('expires_at');
            $table->timestamps();
        });

        Schema::create('club_challenge_messages', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('challenge_id');
            $table->unsignedBigInteger('sender_user_id');
            $table->enum('message_type', ['text', 'system'])->default('text');
            $table->string('content', 1200);
            $table->text('metadata_json')->nullable();
            $table->timestamps();
        });

        Schema::create('user_group_notification_prefs', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('user_id');
            $table->unsignedBigInteger('club_id');
            $table->enum('mode', ['always_on', 'mute_24h', 'mute_1w', 'mute_forever'])->default('always_on');
            $table->dateTime('muted_until')->nullable();
            $table->boolean('updated_by_user')->default(true);
            $table->timestamps();
        });

        Schema::create('user_chat_presence', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('user_id');
            $table->unsignedBigInteger('challenge_id')->nullable();
            $table->boolean('is_active')->default(false);
            $table->dateTime('last_heartbeat_at');
            $table->timestamps();
        });

        Schema::create('push_notifications', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('user_id');
            $table->unsignedBigInteger('club_id')->nullable();
            $table->unsignedBigInteger('group_pichanga_id')->nullable();
            $table->string('type', 80);
            $table->string('title', 140);
            $table->string('body', 500);
            $table->text('data_json')->nullable();
            $table->boolean('is_read')->default(false);
            $table->dateTime('read_at')->nullable();
            $table->timestamps();
        });
    }
}

