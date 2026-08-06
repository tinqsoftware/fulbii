<?php

namespace Tests\Feature\Api;

use App\Models\User;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Laravel\Sanctum\Sanctum;
use Tests\Feature\Concerns\UsesInMemorySqlite;
use Tests\TestCase;

class AdminModerationBulkActionsTest extends TestCase
{
    use UsesInMemorySqlite;

    protected function setUp(): void
    {
        parent::setUp();
        $this->bootInMemorySqlite();
        $this->createSchema();
    }

    public function test_staff_can_process_bulk_moderation_but_cannot_suspend_users(): void
    {
        $staff = User::query()->create([
            'id' => 10,
            'name' => 'Staff',
            'email' => 'staff@test.com',
            'password' => 'secret',
        ]);
        $target = User::query()->create([
            'id' => 20,
            'name' => 'Target',
            'email' => 'target@test.com',
            'password' => 'secret',
        ]);

        $this->attachProfile($staff->id, 'staff_admin');

        \DB::table('reports')->insert([
            [
                'id' => 101,
                'reporter_user_id' => $staff->id,
                'target_type' => 'user',
                'target_id' => $target->id,
                'reason_code' => 'toxic',
                'status' => 'pending',
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'id' => 102,
                'reporter_user_id' => $staff->id,
                'target_type' => 'user',
                'target_id' => $target->id,
                'reason_code' => 'spam',
                'status' => 'pending',
                'created_at' => now(),
                'updated_at' => now(),
            ],
        ]);

        \DB::table('field_submissions')->insert([
            [
                'id' => 201,
                'user_id' => $target->id,
                'status' => 'pending',
                'nombre' => 'Cancha Uno',
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'id' => 202,
                'user_id' => $target->id,
                'status' => 'pending',
                'nombre' => 'Cancha Dos',
                'created_at' => now(),
                'updated_at' => now(),
            ],
        ]);

        \DB::table('strikes')->insert([
            [
                'id' => 301,
                'user_id' => $target->id,
                'report_id' => 101,
                'assigned_by_user_id' => $staff->id,
                'reason_code' => 'toxic',
                'status' => 'active',
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'id' => 302,
                'user_id' => $target->id,
                'report_id' => null,
                'assigned_by_user_id' => $staff->id,
                'reason_code' => 'auto_3_strikes',
                'status' => 'active',
                'created_at' => now(),
                'updated_at' => now(),
            ],
        ]);

        Sanctum::actingAs($staff);

        $resolve = $this->postJson('/api/v1/admin/reports/bulk-resolve', [
            'ids' => [101, 102],
            'status' => 'reviewed',
            'resolution_note' => 'bulk',
        ]);
        $resolve->assertOk()->assertJsonPath('processed', 2);
        $this->assertSame('reviewed', \DB::table('reports')->where('id', 101)->value('status'));

        $bulkField = $this->postJson('/api/v1/admin/field-submissions/bulk-decision', [
            'ids' => [201, 202],
            'action' => 'reject',
            'resolution_note' => 'no califica',
        ]);
        $bulkField->assertOk()->assertJsonPath('processed', 2);
        $this->assertSame('rejected', \DB::table('field_submissions')->where('id', 201)->value('status'));

        $bulkRevoke = $this->postJson('/api/v1/admin/strikes/bulk-revoke', [
            'ids' => [301, 302],
            'revoked_note' => 'limpieza',
        ]);
        $bulkRevoke->assertOk()->assertJsonPath('processed', 1);
        $bulkRevoke->assertJsonPath('skipped', 1);
        $bulkRevoke->assertJsonPath('skipped_items.0.reason', 'critical_revoke_blocked_for_staff');
        $this->assertSame('revoked', \DB::table('strikes')->where('id', 301)->value('status'));
        $this->assertSame('active', \DB::table('strikes')->where('id', 302)->value('status'));

        $this->assertSame(1, \DB::table('product_events')->where('event_name', 'admin_bulk_reports_resolved')->count());
        $this->assertSame(1, \DB::table('product_events')->where('event_name', 'admin_bulk_field_submissions_decided')->count());
        $this->assertSame(1, \DB::table('product_events')->where('event_name', 'admin_bulk_strikes_revoked')->count());
        $this->assertSame(1, \DB::table('product_events')->where('event_name', 'admin_action_blocked')->count());

        $suspension = $this->postJson("/api/v1/admin/users/{$target->id}/suspension", [
            'suspended_until' => now()->addDay()->toISOString(),
            'suspension_reason' => 'manual',
        ]);
        $suspension->assertForbidden();
    }

    public function test_staff_cannot_issue_strike_to_backoffice_user_and_super_cannot_self_suspend(): void
    {
        $staff = User::query()->create([
            'id' => 11,
            'name' => 'Staff',
            'email' => 'staff2@test.com',
            'password' => 'secret',
        ]);
        $super = User::query()->create([
            'id' => 12,
            'name' => 'Super',
            'email' => 'super@test.com',
            'password' => 'secret',
        ]);

        $this->attachProfile($staff->id, 'staff_admin');
        $this->attachProfile($super->id, 'superadmin');

        Sanctum::actingAs($staff);
        $blockedStrike = $this->postJson('/api/v1/admin/strikes', [
            'user_id' => $super->id,
            'reason_code' => 'platform_abuse',
        ]);
        $blockedStrike->assertForbidden();
        $this->assertSame(1, \DB::table('product_events')->where('event_name', 'admin_action_blocked')->count());

        Sanctum::actingAs($super);
        $selfSuspend = $this->postJson("/api/v1/admin/users/{$super->id}/suspension", [
            'suspended_until' => now()->addDays(2)->toISOString(),
            'suspension_reason' => 'test',
        ]);
        $selfSuspend->assertStatus(422);
        $selfSuspend->assertJsonPath('message', 'No puedes ejecutar una suspensión sobre tu propia cuenta.');
    }

    private function attachProfile(int $userId, string $profileName): void
    {
        $profileId = \DB::table('perfil')->insertGetId([
            'nombre' => $profileName,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        \DB::table('user_perfil')->insert([
            'id_user' => $userId,
            'id_perfil' => $profileId,
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

        Schema::create('reports', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('reporter_user_id');
            $table->string('target_type');
            $table->unsignedBigInteger('target_id');
            $table->string('reason_code');
            $table->string('description')->nullable();
            $table->string('status')->default('pending');
            $table->unsignedBigInteger('resolved_by_user_id')->nullable();
            $table->dateTime('resolved_at')->nullable();
            $table->string('resolution_note')->nullable();
            $table->timestamps();
        });

        Schema::create('field_submissions', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('user_id');
            $table->string('status')->default('pending');
            $table->string('nombre');
            $table->string('direccion')->nullable();
            $table->string('x')->nullable();
            $table->string('y')->nullable();
            $table->string('celular')->nullable();
            $table->boolean('wsp')->default(false);
            $table->integer('id_distrito')->nullable();
            $table->string('descripcion')->nullable();
            $table->string('precio_desde')->nullable();
            $table->string('source_type')->default('gps');
            $table->unsignedBigInteger('reviewed_by_user_id')->nullable();
            $table->dateTime('reviewed_at')->nullable();
            $table->integer('approved_polideportivo_id')->nullable();
            $table->string('resolution_note')->nullable();
            $table->timestamps();
        });

        Schema::create('field_submission_photos', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('field_submission_id');
            $table->string('photo_url');
            $table->string('status')->default('active');
            $table->unsignedBigInteger('removed_by_user_id')->nullable();
            $table->string('removed_reason')->nullable();
            $table->timestamps();
        });

        Schema::create('polideportivo', function (Blueprint $table) {
            $table->id();
            $table->string('nombre')->nullable();
            $table->string('x')->nullable();
            $table->string('y')->nullable();
            $table->string('celular')->nullable();
            $table->string('wsp')->nullable();
            $table->integer('id_distrito')->nullable();
            $table->string('descripcion')->nullable();
            $table->unsignedBigInteger('id_user_create')->nullable();
            $table->string('precio_desde')->nullable();
            $table->string('url_foto')->nullable();
            $table->timestamps();
        });

        Schema::create('strikes', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('user_id');
            $table->unsignedBigInteger('report_id')->nullable();
            $table->unsignedBigInteger('assigned_by_user_id');
            $table->string('reason_code');
            $table->string('description')->nullable();
            $table->string('status')->default('active');
            $table->dateTime('expires_at')->nullable();
            $table->unsignedBigInteger('revoked_by_user_id')->nullable();
            $table->dateTime('revoked_at')->nullable();
            $table->string('revoked_note')->nullable();
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
