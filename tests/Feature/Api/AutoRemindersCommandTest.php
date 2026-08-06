<?php

namespace Tests\Feature\Api;

use App\Models\User;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\Config;
use Illuminate\Support\Facades\Queue;
use Illuminate\Support\Facades\Schema;
use Tests\Feature\Concerns\UsesInMemorySqlite;
use Tests\TestCase;

class AutoRemindersCommandTest extends TestCase
{
    use UsesInMemorySqlite;

    protected function setUp(): void
    {
        parent::setUp();
        $this->bootInMemorySqlite();
        $this->createSchema();
        Config::set('queue.default', 'sync');
    }

    public function test_auto_reminder_is_idempotent_and_respects_confirmed_and_mute(): void
    {
        Queue::fake();

        $creator = User::query()->create([
            'id' => 1,
            'name' => 'Creator',
            'email' => 'creator@test.com',
            'password' => 'secret',
        ]);
        $confirmed = User::query()->create([
            'id' => 2,
            'name' => 'Confirmed',
            'email' => 'confirmed@test.com',
            'password' => 'secret',
        ]);
        $eligible = User::query()->create([
            'id' => 3,
            'name' => 'Eligible',
            'email' => 'eligible@test.com',
            'password' => 'secret',
        ]);
        $muted = User::query()->create([
            'id' => 4,
            'name' => 'Muted',
            'email' => 'muted@test.com',
            'password' => 'secret',
        ]);

        \DB::table('clubs')->insert([
            'id' => 1,
            'nombre' => 'Club',
            'slug' => 'club',
            'estado' => 1,
            'is_visible' => 1,
            'audience_max_degree' => 3,
            'auto_reminder_enabled' => 1,
            'auto_reminder_48h_enabled' => 1,
            'auto_reminder_24h_enabled' => 1,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        foreach ([1, 2, 3, 4] as $userId) {
            \DB::table('club_user')->insert([
                'club_id' => 1,
                'user_id' => $userId,
                'rol' => $userId === 1 ? 'admin' : 'miembro',
                'estado' => 1,
                'created_at' => now(),
                'updated_at' => now(),
            ]);
        }

        \DB::table('user_group_notification_prefs')->insert([
            'user_id' => 4,
            'club_id' => 1,
            'mode' => 'mute_forever',
            'muted_until' => null,
            'updated_by_user' => 1,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        \DB::table('group_pichangas')->insert([
            'id' => 99,
            'club_id' => 1,
            'created_by_user_id' => 1,
            'title' => 'Partido',
            'starts_at' => now()->addHours(23),
            'duration_minutes' => 90,
            'capacity' => 14,
            'status' => 'published',
            'confirmation_mode' => 'auto_by_capacity',
            'is_open' => 0,
            'notify_degree' => 3,
            'allow_external_requests' => 0,
            'auto_reminder_enabled' => 1,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        \DB::table('group_pichanga_participants')->insert([
            [
                'pichanga_id' => 99,
                'user_id' => 1,
                'origin' => 'member',
                'status' => 'confirmed',
                'confirmed_at' => now(),
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'pichanga_id' => 99,
                'user_id' => 2,
                'origin' => 'member',
                'status' => 'confirmed',
                'confirmed_at' => now(),
                'created_at' => now(),
                'updated_at' => now(),
            ],
        ]);

        Artisan::call('pichangas:auto-reminders');
        Artisan::call('pichangas:auto-reminders');

        $this->assertDatabaseCount('group_pichanga_notification_batches', 1);
        $this->assertDatabaseHas('group_pichanga_notification_batches', [
            'pichanga_id' => 99,
            'batch_type' => 'auto_24h',
            'target_count' => 2,
            'sent_count' => 1,
        ]);

        $this->assertDatabaseHas('push_notifications', [
            'group_pichanga_id' => 99,
            'user_id' => 3,
            'type' => 'pichanga_auto_24h',
        ]);
        $this->assertDatabaseMissing('push_notifications', [
            'group_pichanga_id' => 99,
            'user_id' => 2,
        ]);
        $this->assertDatabaseMissing('push_notifications', [
            'group_pichanga_id' => 99,
            'user_id' => 4,
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
            $table->string('nombre');
            $table->string('slug');
            $table->tinyInteger('estado')->default(1);
            $table->boolean('is_visible')->default(true);
            $table->unsignedTinyInteger('audience_max_degree')->default(1);
            $table->boolean('auto_reminder_enabled')->default(true);
            $table->boolean('auto_reminder_48h_enabled')->default(true);
            $table->boolean('auto_reminder_24h_enabled')->default(true);
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
            $table->unsignedBigInteger('created_by_user_id');
            $table->string('title')->nullable();
            $table->dateTime('starts_at');
            $table->unsignedSmallInteger('duration_minutes')->default(60);
            $table->unsignedSmallInteger('capacity');
            $table->enum('status', ['published', 'confirmed', 'cancelled', 'completed'])->default('published');
            $table->enum('confirmation_mode', ['auto_by_capacity', 'manual_paid'])->default('auto_by_capacity');
            $table->boolean('is_open')->default(false);
            $table->unsignedTinyInteger('notify_degree')->default(1);
            $table->boolean('allow_external_requests')->default(false);
            $table->boolean('auto_reminder_enabled')->default(true);
            $table->dateTime('auto_reminder_48h_sent_at')->nullable();
            $table->dateTime('auto_reminder_24h_sent_at')->nullable();
            $table->enum('audience_sex', ['M', 'F'])->nullable();
            $table->unsignedTinyInteger('audience_age_min')->nullable();
            $table->unsignedTinyInteger('audience_age_max')->nullable();
            $table->unsignedTinyInteger('skill_fisico_min')->nullable();
            $table->unsignedTinyInteger('skill_arquero_min')->nullable();
            $table->unsignedTinyInteger('skill_delantero_min')->nullable();
            $table->unsignedTinyInteger('skill_mediocampo_min')->nullable();
            $table->unsignedTinyInteger('skill_defensa_min')->nullable();
            $table->timestamps();
        });
        Schema::create('group_pichanga_participants', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('pichanga_id');
            $table->unsignedBigInteger('user_id');
            $table->enum('origin', ['member', 'external'])->default('member');
            $table->enum('status', ['confirmed', 'withdrawn', 'removed'])->default('confirmed');
            $table->dateTime('confirmed_at')->nullable();
            $table->timestamps();
            $table->unique(['pichanga_id', 'user_id']);
        });
        Schema::create('group_pichanga_notification_batches', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('pichanga_id');
            $table->unsignedBigInteger('triggered_by_user_id');
            $table->enum('batch_type', ['initial', 'manual_renotify', 'auto_48h', 'auto_24h'])->default('manual_renotify');
            $table->unsignedTinyInteger('target_degree')->default(1);
            $table->text('filters_json')->nullable();
            $table->unsignedInteger('target_count')->default(0);
            $table->unsignedInteger('muted_skipped_count')->default(0);
            $table->unsignedInteger('sent_count')->default(0);
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

        Schema::create('calificaciones', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('user_calificado_id')->nullable();
            $table->unsignedTinyInteger('fisico')->nullable();
            $table->unsignedTinyInteger('arquero')->nullable();
            $table->unsignedTinyInteger('delantero')->nullable();
            $table->unsignedTinyInteger('mediocampo')->nullable();
            $table->unsignedTinyInteger('defensa')->nullable();
            $table->timestamp('deleted_at')->nullable();
        });
    }
}
