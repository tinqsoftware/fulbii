<?php

namespace Tests\Feature\Api;

use App\Models\FieldSubmission;
use App\Models\User;
use App\Services\FieldSubmissionApprovalService;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Config;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class FieldApiControllerTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();

        Config::set('database.default', 'mysql');
        Config::set('database.connections.mysql', [
            'driver' => 'sqlite',
            'database' => ':memory:',
            'prefix' => '',
            'foreign_key_constraints' => true,
        ]);
        DB::setDefaultConnection('mysql');
        DB::purge('mysql');
        DB::reconnect('mysql');

        Schema::create('polideportivo', function (Blueprint $table) {
            $table->increments('id');
            $table->string('nombre');
            $table->string('direccion')->nullable();
            $table->string('x')->nullable();
            $table->string('y')->nullable();
            $table->text('descripcion')->nullable();
            $table->string('precio_desde')->nullable();
            $table->string('source_type')->nullable();
            $table->json('metadata_json')->nullable();
            $table->decimal('precio_desde_num', 10, 2)->nullable();
            $table->string('url_foto')->nullable();
            $table->string('celular')->nullable();
            $table->boolean('wsp')->default(false);
            $table->unsignedInteger('id_distrito')->nullable();
            $table->unsignedInteger('id_user_create')->nullable();
            $table->timestamps();
        });
        Schema::create('cancha', function (Blueprint $table) {
            $table->increments('id');
            $table->unsignedInteger('id_polideportivo');
            $table->string('nombre')->nullable();
            $table->string('equiposvs', 12)->nullable();
            $table->string('tipo_superficie')->nullable();
            $table->string('formato_vs')->nullable();
            $table->string('url_foto')->nullable();
            $table->decimal('anchom2', 8, 2)->nullable();
            $table->decimal('largom2', 8, 2)->nullable();
            $table->timestamps();
        });
        Schema::create('field_submissions', function (Blueprint $table) {
            $table->increments('id');
            $table->unsignedInteger('user_id');
            $table->string('status')->default('pending');
            $table->string('submission_type')->default('new_polideportivo');
            $table->string('nombre');
            $table->string('direccion')->nullable();
            $table->string('x')->nullable();
            $table->string('y')->nullable();
            $table->string('celular')->nullable();
            $table->boolean('wsp')->default(false);
            $table->unsignedInteger('id_distrito')->nullable();
            $table->text('descripcion')->nullable();
            $table->string('precio_desde')->nullable();
            $table->string('source_type')->nullable();
            $table->json('metadata_json')->nullable();
            $table->unsignedInteger('existing_polideportivo_id')->nullable();
            $table->string('cancha_nombre')->nullable();
            $table->string('cancha_equiposvs')->nullable();
            $table->string('cancha_tipo_superficie')->nullable();
            $table->decimal('cancha_anchom2', 8, 2)->nullable();
            $table->decimal('cancha_largom2', 8, 2)->nullable();
            $table->unsignedInteger('reviewed_by_user_id')->nullable();
            $table->dateTime('reviewed_at')->nullable();
            $table->unsignedInteger('approved_polideportivo_id')->nullable();
            $table->unsignedInteger('approved_cancha_id')->nullable();
            $table->string('resolution_note')->nullable();
            $table->timestamps();
        });
        Schema::create('field_submission_photos', function (Blueprint $table) {
            $table->increments('id');
            $table->unsignedInteger('field_submission_id');
            $table->string('photo_url');
            $table->string('status')->default('active');
            $table->timestamps();
        });

        $user = new User();
        $user->forceFill(['id' => 1, 'name' => 'Tester']);
        $user->exists = true;
        Sanctum::actingAs($user);
    }

    public function test_detail_returns_individual_courts_and_normalizes_capacity(): void
    {
        DB::table('polideportivo')->insert([
            'id' => 1,
            'nombre' => 'Centro Norte',
            'x' => '-12.04',
            'y' => '-77.04',
            'precio_desde_num' => 60,
        ]);
        DB::table('cancha')->insert([
            [
                'id' => 10,
                'id_polideportivo' => 1,
                'nombre' => 'Cancha A',
                'equiposvs' => '7',
                'tipo_superficie' => 'sintetico',
                'url_foto' => 'https://example.test/a.jpg',
                'formato_vs' => null,
            ],
            [
                'id' => 11,
                'id_polideportivo' => 1,
                'nombre' => 'Cancha B',
                'equiposvs' => null,
                'tipo_superficie' => null,
                'formato_vs' => '5v5',
                'url_foto' => null,
            ],
        ]);

        $response = $this->getJson('/api/v1/fields/1');

        $response->assertOk()
            ->assertJsonPath('field.canchas_count', 2)
            ->assertJsonPath('field.vs_formats', ['7v7', '5v5'])
            ->assertJsonPath('field.canchas.0.nombre', 'Cancha A')
            ->assertJsonPath('field.canchas.0.vs_format', '7v7')
            ->assertJsonPath('field.canchas.0.tipo_superficie', 'sintetico')
            ->assertJsonPath('field.canchas.1.vs_format', '5v5');
    }

    public function test_approved_new_polideportivo_is_listed_with_its_court_capacity(): void
    {
        DB::table('field_submissions')->insert([
            'id' => 30,
            'user_id' => 1,
            'status' => 'pending',
            'submission_type' => 'new_polideportivo',
            'nombre' => 'Arena Sur',
            'direccion' => 'Av. Principal 123, Lima',
            'x' => '-12.085000',
            'y' => '-77.020000',
            'precio_desde' => '60',
            'cancha_nombre' => 'Cancha Central',
            'cancha_equiposvs' => '7',
            'cancha_tipo_superficie' => 'sintetico',
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $reviewer = new User(['id' => 99, 'name' => 'Moderador']);
        $reviewer->exists = true;
        $result = app(FieldSubmissionApprovalService::class)->decide(
            FieldSubmission::query()->findOrFail(30),
            $reviewer,
            'approve',
            null,
        );

        $fieldId = $result['approved_polideportivo_id'];
        $this->assertDatabaseHas('cancha', [
            'id' => $result['approved_cancha_id'],
            'id_polideportivo' => $fieldId,
            'equiposvs' => '7',
        ]);

        $this->getJson('/api/v1/fields')
            ->assertOk()
            ->assertJsonFragment([
                'id' => $fieldId,
                'canchas_count' => 1,
                'vs_formats' => ['7v7'],
            ]);

        $this->getJson("/api/v1/fields/{$fieldId}")
            ->assertOk()
            ->assertJsonPath('field.canchas_count', 1)
            ->assertJsonPath('field.vs_formats', ['7v7'])
            ->assertJsonPath('field.canchas.0.nombre', 'Cancha Central')
            ->assertJsonPath('field.canchas.0.vs_format', '7v7');
    }

    public function test_selected_existing_polideportivo_is_persisted_as_existing_submission(): void
    {
        DB::table('polideportivo')->insert([
            'id' => 41,
            'nombre' => 'Centro Existente',
            'x' => '-12.050000',
            'y' => '-77.030000',
        ]);

        $this->postJson('/api/v1/field-submissions', [
            'submission_type' => 'existing_polideportivo',
            'existing_polideportivo_id' => '41',
            'nombre' => 'Centro Existente',
            'direccion' => 'Av. Principal 10, Lima',
            'x' => '-12.050000',
            'y' => '-77.030000',
            'wsp' => '0',
            'cancha_nombre' => 'Cancha Nueva',
            'cancha_equiposvs' => '7',
            'cancha_tipo_superficie' => 'sintetico',
        ])->assertCreated()
            ->assertJsonPath('message', 'Solicitud de cancha enviada.');

        $this->assertDatabaseHas('field_submissions', [
            'submission_type' => 'existing_polideportivo',
            'existing_polideportivo_id' => 41,
            'cancha_nombre' => 'Cancha Nueva',
        ]);
    }

    public function test_existing_submission_requires_a_destination_id(): void
    {
        $this->postJson('/api/v1/field-submissions', [
            'submission_type' => 'existing_polideportivo',
            'nombre' => 'Centro sin destino',
            'cancha_nombre' => 'Cancha Nueva',
            'cancha_equiposvs' => '7',
            'cancha_tipo_superficie' => 'sintetico',
        ])->assertUnprocessable()
            ->assertJsonValidationErrors('existing_polideportivo_id');
    }

    public function test_approved_existing_submission_adds_a_court_without_creating_a_second_centre(): void
    {
        DB::table('polideportivo')->insert([
            'id' => 51,
            'nombre' => 'El Agustino Sport',
            'x' => '-12.048000',
            'y' => '-77.001000',
        ]);
        DB::table('field_submissions')->insert([
            'id' => 52,
            'user_id' => 1,
            'status' => 'pending',
            'submission_type' => 'existing_polideportivo',
            'existing_polideportivo_id' => 51,
            'nombre' => 'El Agustino Sport',
            'cancha_nombre' => 'Cancha C',
            'cancha_equiposvs' => '8',
            'cancha_tipo_superficie' => 'artificial',
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $reviewer = new User(['id' => 99, 'name' => 'Moderador']);
        $reviewer->exists = true;
        $result = app(FieldSubmissionApprovalService::class)->decide(
            FieldSubmission::query()->findOrFail(52),
            $reviewer,
            'approve',
            null,
        );

        $this->assertSame(51, $result['approved_polideportivo_id']);
        $this->assertSame(1, DB::table('polideportivo')->count());
        $this->assertDatabaseHas('cancha', [
            'id' => $result['approved_cancha_id'],
            'id_polideportivo' => 51,
            'nombre' => 'Cancha C',
            'equiposvs' => '8',
        ]);
    }
}
