<?php

namespace Tests\Feature\Api;

use App\Models\User;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\Storage;
use Laravel\Sanctum\Sanctum;
use Tests\Feature\Concerns\UsesInMemorySqlite;
use Tests\TestCase;

class ClubCreationTest extends TestCase
{
    use UsesInMemorySqlite;

    protected function setUp(): void
    {
        parent::setUp();
        $this->bootInMemorySqlite();
        $this->createSchema();
    }

    public function test_a_club_can_be_created_without_a_logo(): void
    {
        $user = $this->actingUser();

        $this->postJson('/api/v1/clubs', [
            'nombre' => 'Grupo sin foto',
            'descripcion' => 'Una descripción.',
            'is_visible' => false,
            'link_join_enabled' => true,
        ])->assertCreated();

        $this->assertDatabaseHas('clubs', [
            'nombre' => 'Grupo sin foto',
            'created_by' => $user->id,
            'is_visible' => 0,
            'link_join_enabled' => 0,
            'logo_url' => null,
        ]);
    }

    public function test_a_club_logo_is_stored_on_the_public_disk(): void
    {
        Storage::fake('public');
        $this->actingUser();

        $response = $this->post(
            '/api/v1/clubs',
            [
                'nombre' => 'Grupo con foto',
                'is_visible' => true,
                'link_join_enabled' => true,
                'logo' => UploadedFile::fake()->image('grupo.png', 800, 800),
            ],
            ['Accept' => 'application/json']
        );

        $response->assertCreated();
        $path = (string) $response->json('club.logo_url');

        $this->assertStringStartsWith('clubs/', $path);
        Storage::disk('public')->assertExists($path);
    }

    public function test_a_logo_larger_than_two_megabytes_is_rejected(): void
    {
        $this->actingUser();

        $this->post(
            '/api/v1/clubs',
            [
                'nombre' => 'Grupo grande',
                'logo' => UploadedFile::fake()->image('grupo.jpg')->size(2049),
            ],
            ['Accept' => 'application/json']
        )->assertUnprocessable()->assertJsonValidationErrors('logo');
    }

    public function test_updating_visibility_disables_join_requests(): void
    {
        $user = $this->actingUser();
        DB::table('clubs')->insert([
            'id' => 1,
            'nombre' => 'Grupo existente',
            'slug' => 'grupo-existente',
            'created_by' => $user->id,
            'estado' => 1,
            'is_visible' => 1,
            'link_join_enabled' => 1,
            'created_at' => now(),
            'updated_at' => now(),
        ]);
        DB::table('club_user')->insert([
            'club_id' => 1,
            'user_id' => $user->id,
            'rol' => 'admin',
            'estado' => 1,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $this->putJson('/api/v1/clubs/1', [
            'is_visible' => false,
            'link_join_enabled' => true,
        ])->assertOk();

        $this->assertDatabaseHas('clubs', [
            'id' => 1,
            'is_visible' => 0,
            'link_join_enabled' => 0,
        ]);
    }

    private function actingUser(): User
    {
        $user = User::query()->create([
            'name' => 'Creator',
            'email' => 'creator-' . uniqid() . '@test.com',
            'password' => 'secret',
        ]);
        Sanctum::actingAs($user);

        return $user;
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
            $table->string('slug', 160)->unique();
            $table->text('descripcion')->nullable();
            $table->string('logo_url')->nullable();
            $table->unsignedBigInteger('created_by')->nullable();
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
    }
}
