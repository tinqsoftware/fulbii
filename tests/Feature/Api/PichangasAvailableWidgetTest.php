<?php

namespace Tests\Feature\Api;

use App\Models\User;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Laravel\Sanctum\Sanctum;
use Tests\Feature\Concerns\UsesInMemorySqlite;
use Tests\TestCase;

class PichangasAvailableWidgetTest extends TestCase
{
    use UsesInMemorySqlite;

    protected function setUp(): void
    {
        parent::setUp();
        $this->bootInMemorySqlite();
        $this->createSchema();
    }

    public function test_my_board_uses_its_reserved_route_instead_of_pichanga_detail_binding(): void
    {
        [$member] = $this->seedBaseGraph();
        Sanctum::actingAs($member);

        $this->getJson('/api/v1/pichangas/my-board')
            ->assertOk()
            ->assertJsonStructure([
                'confirmed_items',
                'pending_items',
                'terminated_items',
                'meta' => ['days'],
            ]);
    }

    public function test_calendar_returns_the_selected_month_with_confirmed_pending_and_terminated_items(): void
    {
        \Illuminate\Support\Carbon::setTestNow('2026-08-05 12:00:00');
        try {
            [$member, , $clubA] = $this->seedBaseGraph();
            $confirmed = $this->insertPichanga($clubA, 'Confirmada agosto', now()->addDays(2));
            $pending = $this->insertPichanga($clubA, 'Pendiente agosto', now()->addDays(3));
            $terminated = $this->insertPichanga($clubA, 'Terminada agosto', now()->subDays(2));
            $nextMonth = $this->insertPichanga($clubA, 'Septiembre', now()->addMonth());

            DB::table('group_pichanga_participants')->insert([
                'pichanga_id' => $confirmed,
                'user_id' => $member->id,
                'origin' => 'member',
                'status' => 'confirmed',
                'confirmed_at' => now(),
                'created_at' => now(),
                'updated_at' => now(),
            ]);

            Sanctum::actingAs($member);
            $items = collect($this->getJson('/api/v1/pichangas/calendar?month=2026-08')
                ->assertOk()
                ->json('items'))
                ->keyBy('id');

            $this->assertTrue($items->has($confirmed));
            $this->assertTrue($items->has($pending));
            $this->assertTrue($items->has($terminated));
            $this->assertFalse($items->has($nextMonth));
            $this->assertSame('confirmed', $items[$confirmed]['calendar_section']);
            $this->assertSame('pending', $items[$pending]['calendar_section']);
            $this->assertSame('terminated', $items[$terminated]['calendar_section']);
            $this->assertArrayHasKey('court_name', $items[$confirmed]);
            $this->assertArrayHasKey('field_name', $items[$confirmed]);
        } finally {
            \Illuminate\Support\Carbon::setTestNow();
        }
    }

    public function test_detail_exposes_presentation_data_and_contextual_permissions(): void
    {
        \Illuminate\Support\Carbon::setTestNow('2026-08-05 12:00:00');
        try {
            [$member, , $clubA] = $this->seedBaseGraph();
            $pichangaId = $this->insertPichanga($clubA, 'Detalle operativo', now()->addDay());
            Sanctum::actingAs($member);

            $this->getJson("/api/v1/pichangas/{$pichangaId}")
                ->assertOk()
                ->assertJsonPath('pichanga.phase', 'upcoming')
                ->assertJsonPath('pichanga.status_label', 'Abierta')
                ->assertJsonPath('me.can_confirm', true)
                ->assertJsonPath('me.can_request_external', false)
                ->assertJsonStructure([
                    'pichanga' => [
                        'court_name', 'field_name', 'venue_photo_url',
                        'confirmed_count', 'spots_left', 'end_at',
                    ],
                    'me' => ['can_change_team', 'can_withdraw'],
                ]);
        } finally {
            \Illuminate\Support\Carbon::setTestNow();
        }
    }

    public function test_repair_command_persistently_assigns_legacy_confirmations_and_detail_totals_match(): void
    {
        \Illuminate\Support\Carbon::setTestNow('2026-08-05 12:00:00');
        try {
            [$member, , $clubA] = $this->seedBaseGraph();
            $pichangaId = $this->insertPichanga($clubA, 'Equipos históricos', now()->addDay());
            DB::table('group_pichangas')->where('id', $pichangaId)->update(['team_count' => 3]);

            foreach (range(1, 4) as $index) {
                DB::table('group_pichanga_participants')->insert([
                    'pichanga_id' => $pichangaId,
                    'user_id' => $member->id,
                    'origin' => 'member',
                    'status' => 'confirmed',
                    'confirmed_at' => now()->addSeconds($index),
                    'team_code' => null,
                    'team_slot' => null,
                    'created_at' => now(),
                    'updated_at' => now(),
                ]);
            }

            $this->artisan('pichangas:repair-team-assignments --force')
                ->expectsOutput('Reparación completada: 4 participantes asignados.')
                ->assertSuccessful();

            $assigned = DB::table('group_pichanga_participants')
                ->where('pichanga_id', $pichangaId)
                ->where('status', 'confirmed')
                ->get();
            $this->assertTrue($assigned->every(fn ($row) => $row->team_code !== null && $row->team_slot !== null));
            $this->assertSame(['A' => 2, 'B' => 1, 'C' => 1], $assigned->countBy('team_code')->sortKeys()->all());

            Sanctum::actingAs($member);
            $detail = $this->getJson("/api/v1/pichangas/{$pichangaId}")->assertOk()->json('pichanga');
            $teamTotal = collect($detail['teams'])->sum('confirmed_count');
            $this->assertSame((int) $detail['confirmed_count'], $teamTotal);

            $this->artisan('pichangas:repair-team-assignments --force')
                ->expectsOutput('Reparación completada: 0 participantes asignados.')
                ->assertSuccessful();
        } finally {
            \Illuminate\Support\Carbon::setTestNow();
        }
    }

    public function test_direct_confirmation_always_persists_selected_team_and_slot(): void
    {
        [$member, , $clubA] = $this->seedBaseGraph();
        $pichangaId = $this->insertPichanga($clubA, 'Confirmación con equipo', now()->addDay());
        Sanctum::actingAs($member);

        $this->postJson("/api/v1/pichangas/{$pichangaId}/confirm", ['team_code' => 'B'])
            ->assertOk();

        $this->assertDatabaseHas('group_pichanga_participants', [
            'pichanga_id' => $pichangaId,
            'user_id' => $member->id,
            'status' => 'confirmed',
            'team_code' => 'B',
            'team_slot' => 1,
        ]);
    }

    public function test_club_agenda_separates_pending_and_past_with_six_item_pages(): void
    {
        \Illuminate\Support\Carbon::setTestNow('2026-08-05 12:00:00');
        try {
            [$member, , $club] = $this->seedBaseGraph();
            foreach (range(1, 7) as $index) {
                $this->insertPichanga($club, "Pendiente {$index}", now()->addDays($index));
            }
            $past = $this->insertPichanga($club, 'Pasada', now()->subDays(2));
            Sanctum::actingAs($member);

            $firstPage = $this->getJson("/api/v1/clubs/{$club}/pichangas?tab=pending&page=1&per_page=6")
                ->assertOk()
                ->assertJsonPath('meta.per_page', 6)
                ->assertJsonPath('meta.total', 7)
                ->json('items');
            $this->assertCount(6, $firstPage);
            $this->assertNotContains($past, collect($firstPage)->pluck('id')->all());
            $this->getJson("/api/v1/clubs/{$club}/pichangas?tab=pending&page=2&per_page=6")
                ->assertOk()
                ->assertJsonCount(1, 'items');
            $this->getJson("/api/v1/clubs/{$club}/pichangas?tab=past&per_page=6")
                ->assertOk()
                ->assertJsonPath('items.0.id', $past);
        } finally {
            \Illuminate\Support\Carbon::setTestNow();
        }
    }

    public function test_public_finished_pichanga_exposes_only_real_watch_match_events(): void
    {
        \Illuminate\Support\Carbon::setTestNow('2026-08-05 12:00:00');
        try {
            [$member, , $club] = $this->seedBaseGraph();
            $pichanga = $this->insertPichanga($club, 'Resultado Watch', now()->subHours(3), true);
            DB::table('group_pichanga_participants')->insert([
                'pichanga_id' => $pichanga, 'user_id' => $member->id, 'origin' => 'member', 'status' => 'confirmed',
                'confirmed_at' => now()->subHours(3), 'team_code' => 'A', 'team_slot' => 1,
                'created_at' => now(), 'updated_at' => now(),
            ]);
            $session = DB::table('watch_match_sessions')->insertGetId([
                'user_id' => $member->id, 'group_pichanga_id' => $pichanga, 'start_time' => now()->subHours(3), 'status' => 'finished',
                'created_at' => now(), 'updated_at' => now(),
            ]);
            DB::table('watch_match_events')->insert([
                ['session_id' => $session, 'event_type' => 'goal', 'event_at' => now()->subHours(2), 'minute' => 12, 'created_at' => now(), 'updated_at' => now()],
                ['session_id' => $session, 'event_type' => 'assist', 'event_at' => now()->subHours(2)->addMinute(), 'minute' => 13, 'created_at' => now(), 'updated_at' => now()],
            ]);

            $this->getJson("/api/v1/pichangas/{$pichanga}/match-summary")
                ->assertOk()
                ->assertJsonPath('has_watch_data', true)
                ->assertJsonPath('totals.goals', 1)
                ->assertJsonPath('totals.assists', 1)
                ->assertJsonPath('events.0.player.id', $member->id);
        } finally {
            \Illuminate\Support\Carbon::setTestNow();
        }
    }

    public function test_available_applies_days_filter_and_returns_member_metadata(): void
    {
        [$member, $external, $clubA] = $this->seedBaseGraph();

        $now = now()->startOfMinute();
        $p1 = $this->insertPichanga($clubA, 'Hoy Confirmada', $now->copy()->addHours(2));
        $p2 = $this->insertPichanga($clubA, 'Mañana Retiro', $now->copy()->addDay());
        $p3 = $this->insertPichanga($clubA, 'Día 4 Pendiente', $now->copy()->addDays(4)->setHour(21));
        $this->insertPichanga($clubA, 'Día 7 Fuera', $now->copy()->addDays(7)->setHour(10));

        DB::table('group_pichanga_participants')->insert([
            'pichanga_id' => $p1,
            'user_id' => $member->id,
            'origin' => 'member',
            'status' => 'confirmed',
            'confirmed_at' => now(),
            'created_at' => now(),
            'updated_at' => now(),
        ]);
        DB::table('group_pichanga_participants')->insert([
            'pichanga_id' => $p2,
            'user_id' => $member->id,
            'origin' => 'member',
            'status' => 'withdrawn',
            'withdrawn_at' => now(),
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        Sanctum::actingAs($member);
        $response = $this->getJson('/api/v1/pichangas/available?days=7');
        $response->assertOk();

        $items = collect($response->json('items'));
        $this->assertCount(3, $items);
        $this->assertNull($items->firstWhere('title', 'Día 7 Fuera'));
        $this->assertSame(0, (int) ($response->json('meta.monthly_played_count') ?? -1));

        $item1 = $items->firstWhere('id', $p1);
        $this->assertTrue((bool) ($item1['me_is_member'] ?? false));
        $this->assertSame('confirmed', $item1['me_participant_status']);
        $this->assertNull($item1['me_pending_kind']);

        $item2 = $items->firstWhere('id', $p2);
        $this->assertTrue((bool) ($item2['me_is_member'] ?? false));
        $this->assertSame('withdrawn', $item2['me_participant_status']);
        $this->assertSame('pending_group', $item2['me_pending_kind']);

        $item3 = $items->firstWhere('id', $p3);
        $this->assertTrue((bool) ($item3['me_is_member'] ?? false));
        $this->assertNull($item3['me_participant_status']);
        $this->assertSame('pending_group', $item3['me_pending_kind']);
        $this->assertArrayHasKey('status', $item3);
        $this->assertArrayHasKey('starts_at', $item3);

        $this->assertNotNull($external);
    }

    public function test_available_marks_pending_open_and_external_request_status(): void
    {
        [, $external, $clubA] = $this->seedBaseGraph();

        $now = now()->startOfMinute();
        $openPending = $this->insertPichanga($clubA, 'Abierta Pendiente', $now->copy()->addHours(3), true, true, 2);
        $openRequested = $this->insertPichanga($clubA, 'Abierta Solicitada', $now->copy()->addDay(), false, true, 2);
        $openConfirmed = $this->insertPichanga($clubA, 'Abierta Confirmada', $now->copy()->addDays(2), false, true, 2);
        $closedHidden = $this->insertPichanga($clubA, 'Cerrada Oculta', $now->copy()->addHours(4), false, false, 2);

        DB::table('group_pichanga_external_requests')->insert([
            'pichanga_id' => $openRequested,
            'user_id' => $external->id,
            'status' => 'pending',
            'requested_at' => now(),
            'created_at' => now(),
            'updated_at' => now(),
        ]);
        DB::table('group_pichanga_participants')->insert([
            'pichanga_id' => $openConfirmed,
            'user_id' => $external->id,
            'origin' => 'external',
            'status' => 'confirmed',
            'confirmed_at' => now(),
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        Sanctum::actingAs($external);
        $response = $this->getJson('/api/v1/pichangas/available?days=7');
        $response->assertOk();

        $items = collect($response->json('items'));
        $this->assertCount(3, $items);
        $this->assertNull($items->firstWhere('id', $closedHidden));
        $this->assertSame(0, (int) ($response->json('meta.monthly_played_count') ?? -1));

        $pendingItem = $items->firstWhere('id', $openPending);
        $this->assertFalse((bool) ($pendingItem['me_is_member'] ?? true));
        $this->assertNull($pendingItem['me_participant_status']);
        $this->assertNull($pendingItem['me_external_request_status']);
        $this->assertSame('pending_open', $pendingItem['me_pending_kind']);

        $requestedItem = $items->firstWhere('id', $openRequested);
        $this->assertSame('pending', $requestedItem['me_external_request_status']);
        $this->assertSame('pending_open', $requestedItem['me_pending_kind']);
        $this->assertSame(2, (int) ($requestedItem['eligible_external_degree'] ?? 0));

        $confirmedItem = $items->firstWhere('id', $openConfirmed);
        $this->assertSame('confirmed', $confirmedItem['me_participant_status']);
        $this->assertNull($confirmedItem['me_pending_kind']);
    }

    public function test_available_returns_monthly_played_count_using_pichanga_end_time(): void
    {
        \Illuminate\Support\Carbon::setTestNow('2026-03-29 12:00:00');
        try {
            [$member, , $clubA] = $this->seedBaseGraph();

            $now = now()->startOfMinute();
            $monthStart = $now->copy()->startOfMonth();
            $lastMonthEnd = $monthStart->copy()->subMinute();

            $endedThisMonth = $this->insertPichanga($clubA, 'Terminó este mes', $now->copy()->subHours(3));
            $futureThisMonth = $this->insertPichanga($clubA, 'Aún no termina', $now->copy()->addHours(3));
            $endedLastMonth = $this->insertPichanga($clubA, 'Terminó mes pasado', $lastMonthEnd->copy()->subHours(3));
            $withdrawnThisMonth = $this->insertPichanga($clubA, 'Retirado este mes', $monthStart->copy()->addDays(2)->setHour(21));

            DB::table('group_pichanga_participants')->insert([
                [
                    'pichanga_id' => $endedThisMonth,
                    'user_id' => $member->id,
                    'origin' => 'member',
                    'status' => 'confirmed',
                    'confirmed_at' => now(),
                    'withdrawn_at' => null,
                    'created_at' => now(),
                    'updated_at' => now(),
                ],
                [
                    'pichanga_id' => $futureThisMonth,
                    'user_id' => $member->id,
                    'origin' => 'member',
                    'status' => 'confirmed',
                    'confirmed_at' => now(),
                    'withdrawn_at' => null,
                    'created_at' => now(),
                    'updated_at' => now(),
                ],
                [
                    'pichanga_id' => $endedLastMonth,
                    'user_id' => $member->id,
                    'origin' => 'member',
                    'status' => 'confirmed',
                    'confirmed_at' => now(),
                    'withdrawn_at' => null,
                    'created_at' => now(),
                    'updated_at' => now(),
                ],
                [
                    'pichanga_id' => $withdrawnThisMonth,
                    'user_id' => $member->id,
                    'origin' => 'member',
                    'status' => 'withdrawn',
                    'confirmed_at' => null,
                    'withdrawn_at' => now(),
                    'created_at' => now(),
                    'updated_at' => now(),
                ],
            ]);

            Sanctum::actingAs($member);
            $response = $this->getJson('/api/v1/pichangas/available?days=7');
            $response->assertOk();

            $this->assertSame(1, (int) ($response->json('meta.monthly_played_count') ?? 0));
        } finally {
            \Illuminate\Support\Carbon::setTestNow();
        }
    }

    public function test_confirmed_next_widget_returns_top_three_confirmed_with_teams_and_share_url(): void
    {
        \Illuminate\Support\Carbon::setTestNow('2026-03-29 09:00:00');
        try {
            [$member, , $clubA] = $this->seedBaseGraph();

            $now = now()->startOfMinute();
            $first = $this->insertPichanga($clubA, 'Primera', $now->copy()->addHours(2));
            $second = $this->insertPichanga($clubA, 'Segunda', $now->copy()->addHours(4));
            $third = $this->insertPichanga($clubA, 'Tercera', $now->copy()->addDay());
            $fourth = $this->insertPichanga($clubA, 'Cuarta', $now->copy()->addDays(2));
            $hidden = $this->insertPichanga($clubA, 'No confirmada', $now->copy()->addDays(3));

            DB::table('group_pichanga_participants')->insert([
                [
                    'pichanga_id' => $first,
                    'user_id' => $member->id,
                    'origin' => 'member',
                    'status' => 'confirmed',
                    'confirmed_at' => now(),
                    'withdrawn_at' => null,
                    'team_code' => 'A',
                    'team_slot' => 1,
                    'created_at' => now(),
                    'updated_at' => now(),
                ],
                [
                    'pichanga_id' => $second,
                    'user_id' => $member->id,
                    'origin' => 'member',
                    'status' => 'confirmed',
                    'confirmed_at' => now(),
                    'withdrawn_at' => null,
                    'team_code' => 'B',
                    'team_slot' => 1,
                    'created_at' => now(),
                    'updated_at' => now(),
                ],
                [
                    'pichanga_id' => $third,
                    'user_id' => $member->id,
                    'origin' => 'member',
                    'status' => 'confirmed',
                    'confirmed_at' => now(),
                    'withdrawn_at' => null,
                    'team_code' => 'A',
                    'team_slot' => 2,
                    'created_at' => now(),
                    'updated_at' => now(),
                ],
                [
                    'pichanga_id' => $fourth,
                    'user_id' => $member->id,
                    'origin' => 'member',
                    'status' => 'confirmed',
                    'confirmed_at' => now(),
                    'withdrawn_at' => null,
                    'team_code' => 'A',
                    'team_slot' => 3,
                    'created_at' => now(),
                    'updated_at' => now(),
                ],
                [
                    'pichanga_id' => $hidden,
                    'user_id' => $member->id,
                    'origin' => 'member',
                    'status' => 'withdrawn',
                    'confirmed_at' => null,
                    'withdrawn_at' => now(),
                    'team_code' => null,
                    'team_slot' => null,
                    'created_at' => now(),
                    'updated_at' => now(),
                ],
            ]);

            Sanctum::actingAs($member);
            $response = $this->getJson('/api/v1/pichangas/widget/confirmed-next?limit=3');
            $response->assertOk();

            $items = collect($response->json('items'));
            $this->assertCount(3, $items);
            $this->assertSame([$first, $second, $third], $items->pluck('id')->all());

            foreach ($items as $item) {
                $this->assertSame('confirmed', $item['me_participant_status']);
                $this->assertStringContainsString('/pichanga/' . $item['id'], (string) ($item['share_url'] ?? ''));
                $this->assertIsArray($item['teams']);
                $this->assertNotEmpty($item['teams']);
                $firstTeam = collect($item['teams'])->first();
                $this->assertArrayHasKey('code', $firstTeam);
                $this->assertArrayHasKey('avg_rating', $firstTeam);
                $this->assertArrayHasKey('slots', $firstTeam);
            }
        } finally {
            \Illuminate\Support\Carbon::setTestNow();
        }
    }

    /**
     * @return array{0:User,1:User,2:int}
     */
    private function seedBaseGraph(): array
    {
        $member = User::query()->create([
            'name' => 'Member',
            'email' => 'member@test.com',
            'password' => 'secret',
        ]);
        $external = User::query()->create([
            'name' => 'External',
            'email' => 'external@test.com',
            'password' => 'secret',
        ]);
        $bridge = User::query()->create([
            'name' => 'Bridge',
            'email' => 'bridge@test.com',
            'password' => 'secret',
        ]);

        $clubA = 100;
        $clubB = 200;
        DB::table('clubs')->insert([
            ['id' => $clubA, 'nombre' => 'Club A', 'slug' => 'club-a', 'estado' => 1, 'is_visible' => 1, 'created_at' => now(), 'updated_at' => now()],
            ['id' => $clubB, 'nombre' => 'Club B', 'slug' => 'club-b', 'estado' => 1, 'is_visible' => 1, 'created_at' => now(), 'updated_at' => now()],
        ]);

        DB::table('club_user')->insert([
            ['club_id' => $clubA, 'user_id' => $member->id, 'rol' => 'miembro', 'estado' => 1, 'created_at' => now(), 'updated_at' => now()],
            ['club_id' => $clubB, 'user_id' => $external->id, 'rol' => 'miembro', 'estado' => 1, 'created_at' => now(), 'updated_at' => now()],
            ['club_id' => $clubA, 'user_id' => $bridge->id, 'rol' => 'miembro', 'estado' => 1, 'created_at' => now(), 'updated_at' => now()],
            ['club_id' => $clubB, 'user_id' => $bridge->id, 'rol' => 'miembro', 'estado' => 1, 'created_at' => now(), 'updated_at' => now()],
        ]);

        return [$member, $external, $clubA];
    }

    private function insertPichanga(
        int $clubId,
        string $title,
        \Illuminate\Support\Carbon $startsAt,
        bool $isOpen = false,
        bool $allowExternal = true,
        int $notifyDegree = 2
    ): int {
        return (int) DB::table('group_pichangas')->insertGetId([
            'club_id' => $clubId,
            'created_by_user_id' => 1,
            'title' => $title,
            'address' => 'Dirección demo',
            'starts_at' => $startsAt,
            'duration_minutes' => 90,
            'capacity' => 14,
            'status' => 'published',
            'confirmation_mode' => 'auto_by_capacity',
            'is_open' => $isOpen ? 1 : 0,
            'notify_degree' => $notifyDegree,
            'allow_external_requests' => $allowExternal ? 1 : 0,
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
            $table->string('sexo', 2)->nullable();
            $table->date('fec_nac')->nullable();
            $table->timestamp('email_verified_at')->nullable();
            $table->string('remember_token', 100)->nullable();
            $table->dateTime('suspended_until')->nullable();
            $table->string('suspension_reason')->nullable();
            $table->timestamps();
        });

        Schema::create('clubs', function (Blueprint $table) {
            $table->id();
            $table->string('nombre', 150);
            $table->string('slug', 160);
            $table->tinyInteger('estado')->default(1);
            $table->boolean('is_visible')->default(true);
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
            $table->string('title', 160)->nullable();
            $table->string('address', 255)->nullable();
            $table->dateTime('starts_at');
            $table->unsignedSmallInteger('duration_minutes')->default(60);
            $table->unsignedSmallInteger('capacity');
            $table->unsignedTinyInteger('team_count')->nullable();
            $table->enum('status', ['published', 'confirmed', 'cancelled', 'completed'])->default('published');
            $table->enum('confirmation_mode', ['auto_by_capacity', 'manual_paid'])->default('auto_by_capacity');
            $table->boolean('is_open')->default(false);
            $table->unsignedTinyInteger('notify_degree')->default(1);
            $table->boolean('allow_external_requests')->default(false);
            $table->timestamps();
        });

        Schema::create('group_pichanga_participants', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('pichanga_id');
            $table->unsignedBigInteger('user_id');
            $table->enum('origin', ['member', 'external'])->default('member');
            $table->enum('status', ['confirmed', 'withdrawn', 'removed'])->default('confirmed');
            $table->dateTime('confirmed_at')->nullable();
            $table->dateTime('withdrawn_at')->nullable();
            $table->string('team_code', 1)->nullable();
            $table->unsignedSmallInteger('team_slot')->nullable();
            $table->string('formation_role', 16)->nullable();
            $table->unsignedSmallInteger('formation_order')->nullable();
            $table->timestamps();
        });

        Schema::create('group_pichanga_external_requests', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('pichanga_id');
            $table->unsignedBigInteger('user_id');
            $table->enum('status', ['pending', 'accepted', 'rejected', 'expired'])->default('pending');
            $table->unsignedTinyInteger('origin_degree')->nullable();
            $table->dateTime('requested_at')->nullable();
            $table->dateTime('decided_at')->nullable();
            $table->timestamps();
        });

        Schema::create('calificaciones', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('user_calificado_id');
            $table->unsignedBigInteger('club_id')->nullable();
            $table->decimal('fisico', 4, 2)->nullable();
            $table->decimal('arquero', 4, 2)->nullable();
            $table->decimal('delantero', 4, 2)->nullable();
            $table->decimal('mediocampo', 4, 2)->nullable();
            $table->decimal('defensa', 4, 2)->nullable();
            $table->softDeletes();
            $table->timestamps();
        });

        Schema::create('group_pichanga_ratings', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('pichanga_id');
            $table->unsignedBigInteger('rated_user_id');
            $table->decimal('fisico', 4, 2)->nullable();
            $table->decimal('arquero', 4, 2)->nullable();
            $table->decimal('delantero', 4, 2)->nullable();
            $table->decimal('mediocampo', 4, 2)->nullable();
            $table->decimal('defensa', 4, 2)->nullable();
            $table->timestamps();
        });

        Schema::create('watch_match_sessions', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('user_id');
            $table->unsignedBigInteger('group_pichanga_id')->nullable();
            $table->dateTime('start_time');
            $table->string('status');
            $table->timestamps();
        });
        Schema::create('watch_match_events', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('session_id');
            $table->string('event_type');
            $table->dateTime('event_at');
            $table->unsignedSmallInteger('minute')->nullable();
            $table->string('clock_time')->nullable();
            $table->json('metadata_json')->nullable();
            $table->timestamps();
        });
    }
}
