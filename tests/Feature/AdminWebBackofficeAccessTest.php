<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Tests\Feature\Concerns\UsesInMemorySqlite;
use Tests\TestCase;

class AdminWebBackofficeAccessTest extends TestCase
{
    use UsesInMemorySqlite;

    protected function setUp(): void
    {
        parent::setUp();
        $this->bootInMemorySqlite();
        $this->createSchema();
    }

    public function test_staff_can_access_admin_dashboard_and_regular_user_cannot(): void
    {
        $staff = User::query()->create([
            'id' => 1,
            'name' => 'Staff',
            'email' => 'staff@test.com',
            'password' => 'secret',
        ]);
        $regular = User::query()->create([
            'id' => 2,
            'name' => 'Regular',
            'email' => 'regular@test.com',
            'password' => 'secret',
        ]);

        $profileId = \DB::table('perfil')->insertGetId([
            'nombre' => 'staff_admin',
            'created_at' => now(),
            'updated_at' => now(),
        ]);
        \DB::table('user_perfil')->insert([
            'id_user' => $staff->id,
            'id_perfil' => $profileId,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $this->actingAs($staff)->get('/admin')->assertOk();
        $this->actingAs($regular)->get('/admin')->assertForbidden();
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
            $table->rememberToken()->nullable();
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
    }
}
