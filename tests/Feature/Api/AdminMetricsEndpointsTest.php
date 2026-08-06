<?php

namespace Tests\Feature\Api;

use App\Models\User;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Laravel\Sanctum\Sanctum;
use Tests\Feature\Concerns\UsesInMemorySqlite;
use Tests\TestCase;

class AdminMetricsEndpointsTest extends TestCase
{
    use UsesInMemorySqlite;

    protected function setUp(): void
    {
        parent::setUp();
        $this->bootInMemorySqlite();
        $this->createSchema();
    }

    public function test_growth_and_release_readiness_endpoints_return_expected_payloads(): void
    {
        $super = User::query()->create([
            'id' => 1,
            'name' => 'Super',
            'email' => 'super@test.com',
            'password' => 'secret',
        ]);
        $staff = User::query()->create([
            'id' => 2,
            'name' => 'Staff',
            'email' => 'staff@test.com',
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
        $staffProfileId = \DB::table('perfil')->insertGetId([
            'nombre' => 'staff_admin',
            'created_at' => now(),
            'updated_at' => now(),
        ]);
        \DB::table('user_perfil')->insert([
            'id_user' => $staff->id,
            'id_perfil' => $staffProfileId,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        \DB::table('product_events')->insert([
            [
                'event_name' => 'club_join_request_created',
                'happened_at' => now()->subDay(),
                'created_at' => now(),
            ],
            [
                'event_name' => 'club_join_request_accepted',
                'happened_at' => now()->subDay(),
                'created_at' => now(),
            ],
            [
                'event_name' => 'pichanga_created',
                'happened_at' => now()->subDay(),
                'created_at' => now(),
            ],
            [
                'event_name' => 'pichanga_confirmed',
                'happened_at' => now()->subDay(),
                'created_at' => now(),
            ],
        ]);

        \DB::table('jobs')->insert([
            'queue' => 'push',
            'payload' => '{}',
            'attempts' => 0,
            'available_at' => time(),
            'created_at' => time(),
        ]);
        \DB::table('failed_jobs')->insert([
            'uuid' => 'abc-123',
            'connection' => 'database',
            'queue' => 'push',
            'payload' => '{}',
            'exception' => 'test',
            'failed_at' => now(),
        ]);
        \DB::table('group_pichanga_notification_batches')->insert([
            'pichanga_id' => 1,
            'triggered_by_user_id' => 1,
            'batch_type' => 'auto_48h',
            'target_degree' => 1,
            'target_count' => 1,
            'muted_skipped_count' => 0,
            'sent_count' => 1,
            'created_at' => now()->subHour(),
            'updated_at' => now()->subHour(),
        ]);

        config()->set('services.app_links.base_url', 'http://fulbii.test');

        Sanctum::actingAs($super);

        $growth = $this->getJson('/api/v1/admin/metrics/growth?from=' . now()->subDays(2)->toDateString() . '&to=' . now()->toDateString());
        $growth->assertOk();
        $growth->assertJsonPath('totals.join_requests', 1);
        $growth->assertJsonPath('totals.join_accepted', 1);
        $growth->assertJsonPath('totals.pichangas_created', 1);
        $growth->assertJsonPath('totals.confirmations', 1);

        $readiness = $this->getJson('/api/v1/admin/ops/release-readiness');
        $readiness->assertOk();
        $readiness->assertJsonPath('jobs_pending', 1);
        $readiness->assertJsonPath('failed_jobs_count', 1);
        $readiness->assertJsonPath('product_events_enabled', true);
        $readiness->assertJsonPath('push_driver', 'log');
        $readiness->assertJsonPath('fcm_v1_ready', true);
        $readiness->assertJsonPath('app_link_base_url', 'http://fulbii.test');
        $readiness->assertJsonPath('well_known_endpoints_ok', false);
        $this->assertNotNull($readiness->json('last_auto_wave_at'));

        Sanctum::actingAs($staff);
        $this->getJson('/api/v1/admin/metrics/growth')->assertOk();
        $this->getJson('/api/v1/admin/ops/release-readiness')->assertOk();
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

        Schema::create('jobs', function (Blueprint $table) {
            $table->id();
            $table->string('queue');
            $table->longText('payload');
            $table->unsignedTinyInteger('attempts');
            $table->unsignedInteger('reserved_at')->nullable();
            $table->unsignedInteger('available_at');
            $table->unsignedInteger('created_at');
        });

        Schema::create('failed_jobs', function (Blueprint $table) {
            $table->id();
            $table->string('uuid')->unique();
            $table->text('connection');
            $table->text('queue');
            $table->longText('payload');
            $table->longText('exception');
            $table->timestamp('failed_at')->useCurrent();
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
    }
}
