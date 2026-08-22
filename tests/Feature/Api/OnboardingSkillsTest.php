<?php

namespace Tests\Feature\Api;

use App\Models\User;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Laravel\Sanctum\Sanctum;
use Tests\Feature\Concerns\UsesInMemorySqlite;
use Tests\TestCase;

class OnboardingSkillsTest extends TestCase
{
    use UsesInMemorySqlite;

    protected function setUp(): void
    {
        parent::setUp();
        $this->bootInMemorySqlite();

        Schema::create('users', function (Blueprint $table): void {
            $table->id();
            $table->string('name')->nullable();
            $table->string('email')->nullable();
            $table->string('password')->nullable();
            $table->string('nick')->nullable();
            $table->string('sexo', 2)->nullable();
            $table->unsignedSmallInteger('altura_cm')->nullable();
            $table->date('fec_nac')->nullable();
            $table->string('theme_mode', 10)->nullable();
            $table->unsignedTinyInteger('onboarding_step')->default(1);
            $table->timestamp('onboarding_completed_at')->nullable();
            $table->boolean('initial_self_rating_locked')->default(false);
            $table->timestamps();
        });

        Schema::create('perfil', function (Blueprint $table): void {
            $table->id();
            $table->string('nombre');
        });
        Schema::create('user_perfil', function (Blueprint $table): void {
            $table->unsignedBigInteger('id_user');
            $table->unsignedBigInteger('id_perfil');
        });

        Schema::create('calificaciones', function (Blueprint $table): void {
            $table->id();
            $table->unsignedBigInteger('club_id')->nullable();
            $table->unsignedBigInteger('user_calificador_id');
            $table->unsignedBigInteger('user_calificado_id');
            $table->decimal('fisico', 3, 1)->nullable();
            $table->decimal('arquero', 3, 1)->nullable();
            $table->decimal('delantero', 3, 1)->nullable();
            $table->decimal('mediocampo', 3, 1)->nullable();
            $table->decimal('defensa', 3, 1)->nullable();
            $table->string('comentario', 500)->nullable();
            $table->boolean('es_autocalificacion')
                ->virtualAs('user_calificador_id = user_calificado_id');
            $table->timestamps();
        });
    }

    public function test_skills_onboarding_does_not_write_generated_self_rating_column(): void
    {
        $user = User::query()->create([
            'name' => 'Nuevo jugador',
            'email' => 'onboarding-' . uniqid() . '@test.com',
        ]);
        Sanctum::actingAs($user);

        $payload = [
            'nick' => 'nuevo_jugador',
            'sexo' => 'M',
            'altura_cm' => 175,
            'fec_nac' => '1995-05-12',
            'theme_mode' => 'dark',
            'delantero' => 3.0,
            'mediocampo' => 2.5,
            'defensa' => 2.0,
            'arquero' => 1.5,
            'fisico' => 3.5,
        ];

        $this->postJson('/api/v1/onboarding', $payload)
            ->assertOk()
            ->assertJsonPath('onboarding_completed', true);

        $this->assertDatabaseHas('calificaciones', [
            'user_calificador_id' => $user->id,
            'user_calificado_id' => $user->id,
            'delantero' => 3.0,
            'fisico' => 3.5,
        ]);
        $this->assertDatabaseHas('users', [
            'id' => $user->id,
            'initial_self_rating_locked' => 1,
            'onboarding_step' => 7,
        ]);
        $this->assertDatabaseHas('calificaciones', [
            'user_calificador_id' => $user->id,
            'user_calificado_id' => $user->id,
            'es_autocalificacion' => 1,
        ]);

        $this->postJson('/api/v1/onboarding', [
            'delantero' => 4.0,
            'mediocampo' => 4.0,
            'defensa' => 4.0,
            'arquero' => 4.0,
            'fisico' => 4.0,
        ])->assertStatus(422)
            ->assertJsonPath('message', 'La autocalificación inicial ya está bloqueada.');
    }
}
