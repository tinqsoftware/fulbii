<?php

namespace Tests\Feature\Api;

use App\Models\User;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Laravel\Sanctum\Sanctum;
use Tests\Feature\Concerns\UsesInMemorySqlite;
use Tests\TestCase;

class ContextualReportsTest extends TestCase
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
        Schema::create('group_pichangas', function (Blueprint $table) {
            $table->id();
            $table->timestamps();
        });
        Schema::create('group_pichanga_posts', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('pichanga_id');
            $table->unsignedBigInteger('user_id');
            $table->string('status')->default('active');
            $table->timestamps();
        });
        Schema::create('reports', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('reporter_user_id');
            $table->string('target_type');
            $table->unsignedBigInteger('target_id');
            $table->string('content_type')->nullable();
            $table->unsignedBigInteger('content_id')->nullable();
            $table->string('reason_code');
            $table->string('description')->nullable();
            $table->string('status')->default('pending');
            $table->timestamps();
        });
    }

    public function test_user_can_report_contextual_pichanga_post_once_while_pending(): void
    {
        $reporter = User::query()->create(['id' => 1, 'name' => 'Reporter', 'email' => 'reporter@test.com']);
        $author = User::query()->create(['id' => 2, 'name' => 'Author', 'email' => 'author@test.com']);
        \DB::table('group_pichangas')->insert(['id' => 50, 'created_at' => now(), 'updated_at' => now()]);
        \DB::table('group_pichanga_posts')->insert([
            'id' => 70,
            'pichanga_id' => 50,
            'user_id' => $author->id,
            'status' => 'active',
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        Sanctum::actingAs($reporter);
        $payload = [
            'target_type' => 'group_pichanga',
            'target_id' => 50,
            'content_type' => 'pichanga_post',
            'content_id' => 70,
            'reason_code' => 'spam',
        ];
        $this->postJson('/api/v1/reports', $payload)->assertCreated()->assertJsonPath('report.content_id', 70);
        $this->assertDatabaseHas('reports', ['content_type' => 'pichanga_post', 'content_id' => 70, 'status' => 'pending']);
        $this->postJson('/api/v1/reports', $payload)->assertStatus(422);
    }
}
