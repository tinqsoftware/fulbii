<?php

namespace Tests\Feature\Api;

use App\Models\FieldSubmission;
use App\Models\User;
use App\Services\FieldSubmissionApprovalService;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Config;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Queue;
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
        Schema::create('polideportivo_photos', function (Blueprint $table) {
            $table->increments('id');
            $table->unsignedInteger('polideportivo_id');
            $table->string('photo_url');
            $table->unsignedInteger('sort_order')->default(0);
            $table->timestamps();
        });
        Schema::create('cancha_photos', function (Blueprint $table) {
            $table->increments('id');
            $table->unsignedInteger('cancha_id');
            $table->string('photo_url');
            $table->unsignedInteger('sort_order')->default(0);
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
            $table->string('asset_type')->default('court');
            $table->unsignedInteger('sort_order')->default(0);
            $table->string('status')->default('active');
            $table->timestamps();
        });
        Schema::create('group_pichangas', function (Blueprint $table) {
            $table->increments('id');
            $table->unsignedInteger('field_id')->nullable();
            $table->unsignedInteger('cancha_id')->nullable();
            $table->string('title')->nullable();
            $table->string('status')->default('published');
            $table->boolean('is_open')->default(false);
            $table->dateTime('starts_at');
            $table->unsignedInteger('duration_minutes')->default(90);
            $table->unsignedInteger('capacity')->default(14);
            $table->string('match_format')->nullable();
            $table->unsignedInteger('players_per_team')->nullable();
            $table->timestamps();
        });
        Schema::create('group_pichanga_participants', function (Blueprint $table) {
            $table->increments('id');
            $table->unsignedInteger('pichanga_id');
            $table->unsignedInteger('user_id');
            $table->string('status')->default('pending');
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
                'anchom2' => 20,
                'largom2' => 40,
            ],
            [
                'id' => 11,
                'id_polideportivo' => 1,
                'nombre' => 'Cancha B',
                'equiposvs' => null,
                'tipo_superficie' => null,
                'formato_vs' => '5v5',
                'url_foto' => null,
                'anchom2' => null,
                'largom2' => null,
            ],
        ]);

        $response = $this->getJson('/api/v1/fields/1');

        $response->assertOk()
            ->assertJsonPath('field.canchas_count', 2)
            ->assertJsonPath('field.vs_formats', ['7v7', '5v5'])
            ->assertJsonPath('field.canchas.0.nombre', 'Cancha A')
            ->assertJsonPath('field.canchas.0.vs_format', '7v7')
            ->assertJsonPath('field.canchas.0.tipo_superficie', 'sintetico')
            ->assertJsonPath('field.canchas.0.anchom2', 20)
            ->assertJsonPath('field.canchas.0.largom2', 40)
            ->assertJsonPath('field.canchas.1.vs_format', '5v5');
    }

    public function test_index_filters_polideportivos_by_optional_map_viewport(): void
    {
        DB::table('polideportivo')->insert([
            ['id' => 201, 'nombre' => 'Dentro del mapa', 'x' => '-12.050000', 'y' => '-77.040000', 'created_at' => now(), 'updated_at' => now()],
            ['id' => 202, 'nombre' => 'Fuera del mapa', 'x' => '-12.300000', 'y' => '-77.040000', 'created_at' => now(), 'updated_at' => now()],
        ]);

        $this->getJson('/api/v1/fields?south=-12.10&west=-77.10&north=-12.00&east=-77.00')
            ->assertOk()
            ->assertJsonCount(1, 'items')
            ->assertJsonPath('items.0.id', 201);
    }

    public function test_index_rejects_an_incomplete_or_invalid_map_viewport(): void
    {
        $this->getJson('/api/v1/fields?south=-12.10')
            ->assertStatus(422);

        $this->getJson('/api/v1/fields?south=-12.00&west=-77.00&north=-12.10&east=-77.10')
            ->assertStatus(422)
            ->assertJsonPath('message', 'Los límites del mapa no son válidos.');
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

    public function test_surface_and_format_filters_match_the_same_court(): void
    {
        DB::table('polideportivo')->insert([
            [
                'id' => 61,
                'nombre' => 'Centro con filtros separados',
                'precio_desde_num' => 70,
            ],
            [
                'id' => 62,
                'nombre' => 'Centro con cancha compatible',
                'precio_desde_num' => 70,
            ],
            [
                'id' => 63,
                'nombre' => 'Centro fuera de precio',
                'precio_desde_num' => 120,
            ],
        ]);
        DB::table('cancha')->insert([
            // This centre must not match: each filter is satisfied by a
            // different court.
            [
                'id' => 610,
                'id_polideportivo' => 61,
                'equiposvs' => '11',
                'tipo_superficie' => 'sintetico',
                'formato_vs' => null,
            ],
            [
                'id' => 611,
                'id_polideportivo' => 61,
                'equiposvs' => '7',
                'tipo_superficie' => 'losa',
                'formato_vs' => null,
            ],
            // This single court satisfies both surface and format.
            [
                'id' => 620,
                'id_polideportivo' => 62,
                'equiposvs' => '11',
                'tipo_superficie' => 'losa',
                'formato_vs' => null,
            ],
            // It matches the court filters but not the centre price range.
            [
                'id' => 630,
                'id_polideportivo' => 63,
                'equiposvs' => '11',
                'tipo_superficie' => 'losa',
                'formato_vs' => null,
            ],
        ]);

        $this->getJson('/api/v1/fields?surface_types=losa&vs_formats=11v11&price_min=60&price_max=80')
            ->assertOk()
            ->assertJsonCount(1, 'items')
            ->assertJsonPath('items.0.id', 62)
            ->assertJsonPath('items.0.vs_formats', ['11v11']);
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

    public function test_superadmin_submission_is_published_immediately_without_the_monthly_limit(): void
    {
        Schema::create('perfil', function (Blueprint $table) {
            $table->increments('id');
            $table->string('nombre');
        });
        Schema::create('user_perfil', function (Blueprint $table) {
            $table->unsignedInteger('id_user');
            $table->unsignedInteger('id_perfil');
        });
        DB::table('perfil')->insert(['id' => 1, 'nombre' => 'superadmin']);
        DB::table('user_perfil')->insert(['id_user' => 1, 'id_perfil' => 1]);
        foreach (range(1, 3) as $index) {
            DB::table('field_submissions')->insert([
                'user_id' => 1,
                'status' => 'rejected',
                'submission_type' => 'new_polideportivo',
                'nombre' => "Aporte previo {$index}",
                'created_at' => now(),
                'updated_at' => now(),
            ]);
        }

        $this->postJson('/api/v1/field-submissions', [
            'nombre' => 'Polideportivo real',
            'direccion' => 'Av. Real 123',
            'cancha_nombre' => 'Cancha principal',
            'cancha_equiposvs' => '7',
            'cancha_tipo_superficie' => 'sintetico',
        ])->assertCreated()
            ->assertJsonPath('message', 'Cancha publicada y aprobada automáticamente.')
            ->assertJsonPath('submission.status', 'approved')
            ->assertJsonPath('summary.is_unlimited', true)
            ->assertJsonPath('summary.can_submit', true);

        $this->assertDatabaseHas('polideportivo', [
            'nombre' => 'Polideportivo real',
            'id_user_create' => 1,
        ]);
        $this->assertDatabaseHas('cancha', ['nombre' => 'Cancha principal']);
    }

    public function test_superadmin_can_edit_a_field_and_its_court(): void
    {
        Schema::create('perfil', function (Blueprint $table) {
            $table->increments('id');
            $table->string('nombre');
        });
        Schema::create('user_perfil', function (Blueprint $table) {
            $table->unsignedInteger('id_user');
            $table->unsignedInteger('id_perfil');
        });
        DB::table('perfil')->insert(['id' => 1, 'nombre' => 'superadmin']);
        DB::table('user_perfil')->insert(['id_user' => 1, 'id_perfil' => 1]);
        DB::table('polideportivo')->insert(['id' => 92, 'nombre' => 'Antes']);
        DB::table('cancha')->insert([
            'id' => 93,
            'id_polideportivo' => 92,
            'nombre' => 'Cancha antes',
            'equiposvs' => '5',
        ]);

        $this->putJson('/api/v1/admin/fields/92', [
            'nombre' => 'Complejo actualizado',
            'direccion' => 'Av. Cambio 123',
            'precio_desde' => '85',
        ])->assertOk()->assertJsonPath('field_id', 92);
        $this->putJson('/api/v1/admin/courts/93', [
            'nombre' => 'Cancha renovada',
            'equiposvs' => '7',
            'tipo_superficie' => 'sintetico',
        ])->assertOk()->assertJsonPath('cancha_id', 93);

        $this->assertDatabaseHas('polideportivo', [
            'id' => 92,
            'nombre' => 'Complejo actualizado',
            'precio_desde_num' => 85,
        ]);
        $this->assertDatabaseHas('cancha', [
            'id' => 93,
            'nombre' => 'Cancha renovada',
            'formato_vs' => '7v7',
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

    public function test_submission_limits_legacy_court_photos_to_three(): void
    {
        $this->postJson('/api/v1/field-submissions', [
            'nombre' => 'Centro con fotos',
            'cancha_nombre' => 'Cancha Nueva',
            'cancha_equiposvs' => '7',
            'cancha_tipo_superficie' => 'sintetico',
            'photos' => [
                'https://example.test/one.jpg',
                'https://example.test/two.jpg',
                'https://example.test/three.jpg',
                'https://example.test/four.jpg',
            ],
        ])->assertUnprocessable()
            ->assertJsonValidationErrors('photos');
    }

    public function test_submission_separates_venue_and_court_photo_urls(): void
    {
        $response = $this->postJson('/api/v1/field-submissions', [
            'submission_type' => 'new_polideportivo',
            'nombre' => 'Arena Fotos',
            'cancha_nombre' => 'Cancha Principal',
            'cancha_equiposvs' => '7',
            'cancha_tipo_superficie' => 'sintetico',
            'photos' => ['https://example.test/court.jpg'],
        ]);

        $response->assertCreated();
        $this->assertDatabaseHas('field_submission_photos', [
            'photo_url' => 'https://example.test/court.jpg',
            'asset_type' => 'court',
        ]);
    }

    public function test_approval_persists_separate_venue_and_court_galleries(): void
    {
        DB::table('field_submissions')->insert([
            'id' => 70, 'user_id' => 1, 'status' => 'pending',
            'submission_type' => 'new_polideportivo', 'nombre' => 'Arena Fotos',
            'cancha_nombre' => 'Cancha Principal', 'cancha_equiposvs' => '7',
            'cancha_tipo_superficie' => 'sintetico', 'created_at' => now(), 'updated_at' => now(),
        ]);
        DB::table('field_submission_photos')->insert([
            ['field_submission_id' => 70, 'photo_url' => 'https://example.test/venue.jpg', 'asset_type' => 'venue', 'sort_order' => 0, 'status' => 'active', 'created_at' => now(), 'updated_at' => now()],
            ['field_submission_id' => 70, 'photo_url' => 'https://example.test/court.jpg', 'asset_type' => 'court', 'sort_order' => 0, 'status' => 'active', 'created_at' => now(), 'updated_at' => now()],
        ]);

        $reviewer = new User(['id' => 99, 'name' => 'Moderador']);
        $reviewer->exists = true;
        $result = app(FieldSubmissionApprovalService::class)->decide(FieldSubmission::query()->findOrFail(70), $reviewer, 'approve', null);

        $this->assertDatabaseHas('polideportivo_photos', ['polideportivo_id' => $result['approved_polideportivo_id'], 'photo_url' => 'https://example.test/venue.jpg']);
        $this->assertDatabaseHas('cancha_photos', ['cancha_id' => $result['approved_cancha_id'], 'photo_url' => 'https://example.test/court.jpg']);
        $this->assertDatabaseHas('polideportivo', ['id' => $result['approved_polideportivo_id'], 'url_foto' => 'https://example.test/venue.jpg']);
        $this->assertDatabaseHas('cancha', ['id' => $result['approved_cancha_id'], 'url_foto' => 'https://example.test/court.jpg']);
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
            'cancha_tipo_superficie' => 'natural',
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
            'tipo_superficie' => 'natural',
        ]);
    }

    public function test_detail_lists_only_future_open_pichangas_with_places(): void
    {
        DB::table('polideportivo')->insert([
            'id' => 80,
            'nombre' => 'Complejo con pichangas',
        ]);
        DB::table('cancha')->insert([
            'id' => 801,
            'id_polideportivo' => 80,
            'nombre' => 'Cancha principal',
        ]);
        DB::table('group_pichangas')->insert([
            ['id' => 1, 'field_id' => 80, 'cancha_id' => 801, 'title' => 'Disponible', 'status' => 'published', 'is_open' => true, 'starts_at' => now()->addDay(), 'duration_minutes' => 90, 'capacity' => 10, 'match_format' => '5v5', 'players_per_team' => 5],
            ['id' => 2, 'field_id' => 80, 'cancha_id' => 801, 'title' => 'Pasada', 'status' => 'published', 'is_open' => true, 'starts_at' => now()->subDay(), 'duration_minutes' => 90, 'capacity' => 10, 'match_format' => null, 'players_per_team' => null],
            ['id' => 3, 'field_id' => 80, 'cancha_id' => 801, 'title' => 'Cerrada', 'status' => 'published', 'is_open' => false, 'starts_at' => now()->addDays(2), 'duration_minutes' => 90, 'capacity' => 10, 'match_format' => null, 'players_per_team' => null],
            ['id' => 4, 'field_id' => 80, 'cancha_id' => 801, 'title' => 'Llena', 'status' => 'published', 'is_open' => true, 'starts_at' => now()->addDays(3), 'duration_minutes' => 90, 'capacity' => 1, 'match_format' => null, 'players_per_team' => null],
        ]);
        DB::table('group_pichanga_participants')->insert([
            'pichanga_id' => 4,
            'user_id' => 8,
            'status' => 'confirmed',
        ]);

        $this->getJson('/api/v1/fields/80')
            ->assertOk()
            ->assertJsonCount(1, 'field.open_pichangas')
            ->assertJsonPath('field.open_pichangas.0.id', 1)
            ->assertJsonPath('field.open_pichangas.0.spots_left', 10)
            ->assertJsonPath('field.open_pichangas.0.court_name', 'Cancha principal');
    }

    public function test_pending_submission_blocks_a_second_submission_and_is_exposed_in_summary(): void
    {
        DB::table('field_submissions')->insert([
            'user_id' => 1,
            'status' => 'pending',
            'submission_type' => 'new_polideportivo',
            'nombre' => 'Aporte pendiente',
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $this->getJson('/api/v1/field-submissions/mine')
            ->assertOk()
            ->assertJsonPath('summary.monthly_used', 1)
            ->assertJsonPath('summary.monthly_limit', 3)
            ->assertJsonPath('summary.can_submit', false)
            ->assertJsonPath('summary.pending_submission.nombre', 'Aporte pendiente');

        $this->postJson('/api/v1/field-submissions', ['nombre' => 'Segundo aporte'])
            ->assertStatus(422)
            ->assertSee('Ya tienes una solicitud pendiente');
    }

    public function test_monthly_limit_counts_resolved_submissions_but_resets_next_month(): void
    {
        foreach (range(1, 3) as $index) {
            DB::table('field_submissions')->insert([
                'user_id' => 1,
                'status' => 'rejected',
                'submission_type' => 'new_polideportivo',
                'nombre' => "Aporte {$index}",
                'created_at' => now()->startOfMonth()->addDays($index),
                'updated_at' => now(),
            ]);
        }
        DB::table('field_submissions')->insert([
            'user_id' => 1,
            'status' => 'approved',
            'submission_type' => 'new_polideportivo',
            'nombre' => 'Aporte antiguo',
            'created_at' => now()->subMonth()->startOfMonth(),
            'updated_at' => now(),
        ]);

        $this->getJson('/api/v1/field-submissions/mine')
            ->assertOk()
            ->assertJsonPath('summary.monthly_used', 3)
            ->assertJsonPath('summary.can_submit', false);
        $this->postJson('/api/v1/field-submissions', ['nombre' => 'Cuarto aporte'])
            ->assertStatus(422)
            ->assertJsonPath('message', 'Ya alcanzaste el máximo de 3 solicitudes de cancha este mes.');
    }

    public function test_approval_and_rejection_create_a_navigable_notification_for_the_submitter(): void
    {
        Schema::create('push_notifications', function (Blueprint $table) {
            $table->increments('id');
            $table->unsignedInteger('user_id');
            $table->unsignedInteger('club_id')->nullable();
            $table->unsignedInteger('group_pichanga_id')->nullable();
            $table->string('type');
            $table->string('title');
            $table->text('body')->nullable();
            $table->json('data_json')->nullable();
            $table->boolean('is_read')->default(false);
            $table->dateTime('read_at')->nullable();
            $table->timestamps();
        });
        Queue::fake();
        DB::table('field_submissions')->insert([
            'id' => 91,
            'user_id' => 1,
            'status' => 'pending',
            'submission_type' => 'new_polideportivo',
            'nombre' => 'Aporte por revisar',
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $reviewer = new User(['id' => 99, 'name' => 'Moderador']);
        $reviewer->exists = true;
        app(FieldSubmissionApprovalService::class)->decide(
            FieldSubmission::query()->findOrFail(91),
            $reviewer,
            'reject',
            'Información incompleta',
        );

        $notification = DB::table('push_notifications')->first();
        $this->assertSame('field_submission_rejected', $notification->type);
        $this->assertSame('field_submission', json_decode($notification->data_json, true)['target_type']);
        $this->assertSame('91', json_decode($notification->data_json, true)['target_id']);
    }
}
