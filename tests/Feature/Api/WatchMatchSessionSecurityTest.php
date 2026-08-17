<?php

namespace Tests\Feature\Api;

use App\Models\User;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Laravel\Sanctum\Sanctum;
use Tests\Feature\Concerns\UsesInMemorySqlite;
use Tests\TestCase;

class WatchMatchSessionSecurityTest extends TestCase
{
    use UsesInMemorySqlite;

    protected function setUp(): void
    {
        parent::setUp();
        $this->bootInMemorySqlite();
        $this->createSchema();
    }

    public function test_non_participant_cannot_create_a_watch_session_for_another_pichanga(): void
    {
        [$participant, $outsider, $pichangaId] = $this->seedGraph();
        Sanctum::actingAs($outsider);

        $this->postJson('/api/v1/watch/match-sessions', [
            'group_pichanga_id' => $pichangaId,
            'start_time' => now()->toISOString(),
            'source' => 'live',
        ])->assertForbidden();
    }

    public function test_participant_cannot_attach_a_session_to_a_different_field(): void
    {
        [$participant, , $pichangaId] = $this->seedGraph();
        Sanctum::actingAs($participant);

        $this->postJson('/api/v1/watch/match-sessions', [
            'group_pichanga_id' => $pichangaId,
            'field_id' => 99,
            'start_time' => now()->toISOString(),
            'source' => 'live',
        ])->assertStatus(422);
    }

    /** @return array{User,User,int} */
    private function seedGraph(): array
    {
        $participant = User::query()->create(['name' => 'Participant', 'email' => 'participant@test.com', 'password' => 'secret']);
        $outsider = User::query()->create(['name' => 'Outsider', 'email' => 'outsider@test.com', 'password' => 'secret']);
        Schema::table('clubs', fn (Blueprint $table) => $table->timestamps());
        \DB::table('clubs')->insert(['id' => 1, 'nombre' => 'Club seguro', 'estado' => 1, 'created_at' => now(), 'updated_at' => now()]);
        \DB::table('club_user')->insert(['club_id' => 1, 'user_id' => $participant->id, 'rol' => 'miembro', 'estado' => 1]);
        \DB::table('group_pichangas')->insert([
            'id' => 7,
            'club_id' => 1,
            'field_id' => 10,
            'cancha_id' => 20,
            'starts_at' => now(),
            'duration_minutes' => 90,
        ]);
        \DB::table('group_pichanga_participants')->insert(['pichanga_id' => 7, 'user_id' => $participant->id, 'status' => 'confirmed']);

        return [$participant, $outsider, 7];
    }

    private function createSchema(): void
    {
        Schema::create('users', function (Blueprint $table) {
            $table->id(); $table->string('name')->nullable(); $table->string('email')->nullable(); $table->string('password')->nullable();
            $table->dateTime('suspended_until')->nullable(); $table->string('suspension_reason')->nullable(); $table->timestamps();
        });
        Schema::create('perfil', function (Blueprint $table) { $table->id(); $table->string('nombre'); });
        Schema::create('user_perfil', function (Blueprint $table) { $table->id(); $table->unsignedBigInteger('id_user'); $table->unsignedBigInteger('id_perfil'); });
        Schema::create('clubs', function (Blueprint $table) { $table->id(); $table->string('nombre'); $table->integer('estado')->nullable(); });
        Schema::create('club_user', function (Blueprint $table) { $table->id(); $table->unsignedBigInteger('club_id'); $table->unsignedBigInteger('user_id'); $table->string('rol'); $table->integer('estado'); });
        Schema::create('group_pichangas', function (Blueprint $table) { $table->id(); $table->unsignedBigInteger('club_id'); $table->unsignedInteger('field_id'); $table->unsignedInteger('cancha_id'); $table->dateTime('starts_at'); $table->integer('duration_minutes')->nullable(); });
        Schema::create('group_pichanga_participants', function (Blueprint $table) { $table->id(); $table->unsignedBigInteger('pichanga_id'); $table->unsignedBigInteger('user_id'); $table->string('status'); });
        Schema::create('watch_match_sessions', function (Blueprint $table) {
            $table->id(); $table->unsignedBigInteger('user_id'); $table->string('external_session_id')->nullable(); $table->unsignedBigInteger('group_pichanga_id')->nullable();
            $table->unsignedInteger('field_id')->nullable(); $table->unsignedInteger('cancha_id')->nullable(); $table->unsignedBigInteger('field_geometry_id')->nullable();
            $table->dateTime('start_time'); $table->dateTime('end_time')->nullable(); $table->string('status'); $table->string('my_goal_side')->nullable(); $table->string('device')->nullable(); $table->string('source')->nullable();
            $table->decimal('distance_meters', 10, 2)->nullable(); $table->decimal('distance_meters_raw', 10, 2)->nullable(); $table->decimal('distance_meters_filtered', 10, 2)->nullable(); $table->text('device_payload_json')->nullable(); $table->timestamps();
        });
        Schema::create('watch_position_samples', function (Blueprint $table) { $table->id(); $table->unsignedBigInteger('session_id'); $table->dateTime('sampled_at'); $table->decimal('lat', 11, 7); $table->decimal('lng', 11, 7); $table->decimal('horizontal_accuracy', 8, 2)->nullable(); $table->decimal('speed', 8, 2)->nullable(); $table->string('quality_flag')->nullable(); $table->timestamps(); });
        Schema::create('watch_match_events', function (Blueprint $table) { $table->id(); $table->unsignedBigInteger('session_id'); $table->string('event_type'); $table->dateTime('event_at'); $table->integer('minute')->nullable(); $table->string('clock_time')->nullable(); $table->text('metadata_json')->nullable(); $table->timestamps(); });
    }
}
