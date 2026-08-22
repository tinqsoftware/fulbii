<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (!Schema::hasTable('users')) {
            return;
        }

        if (!Schema::hasTable('championships')) {
            Schema::create('championships', function (Blueprint $table) {
                $table->id();
                $table->unsignedBigInteger('created_by_user_id');
                $table->unsignedBigInteger('club_id')->nullable();
                $table->unsignedInteger('field_id')->nullable();
                $table->string('name', 160);
                $table->string('slug', 180)->nullable();
                $table->string('share_token', 80)->nullable();
                $table->text('description')->nullable();
                $table->string('logo_url', 500)->nullable();
                $table->text('rules')->nullable();
                $table->enum('visibility', ['public', 'private', 'link'])->default('private');
                $table->enum('status', ['draft', 'registration', 'published', 'in_progress', 'completed', 'archived'])->default('draft');
                $table->enum('format', ['league', 'knockout', 'hybrid'])->default('league');
                $table->boolean('double_round_robin')->default(false);
                $table->unsignedSmallInteger('points_win')->default(3);
                $table->unsignedSmallInteger('points_draw')->default(1);
                $table->unsignedSmallInteger('points_loss')->default(0);
                $table->unsignedTinyInteger('max_teams')->default(8);
                $table->unsignedTinyInteger('players_per_team')->default(7);
                $table->dateTime('registration_starts_at')->nullable();
                $table->dateTime('registration_ends_at')->nullable();
                $table->dateTime('starts_at')->nullable();
                $table->dateTime('ends_at')->nullable();
                $table->json('settings_json')->nullable();
                $table->timestamps();

                $table->index(['status', 'visibility'], 'ch_status_visibility');
                $table->index(['club_id', 'status'], 'ch_club_status');
                $table->index(['field_id', 'status'], 'ch_field_status');
                $table->index(['created_by_user_id', 'status'], 'ch_creator_status');
                $table->unique('slug', 'uq_ch_slug');
                $table->unique('share_token', 'uq_ch_share_token');
                $table->foreign('created_by_user_id', 'fk_ch_creator')->references('id')->on('users')->cascadeOnDelete();
            });
        }

        if (!Schema::hasTable('championship_admins')) {
            Schema::create('championship_admins', function (Blueprint $table) {
                $table->id();
                $table->unsignedBigInteger('championship_id');
                $table->unsignedBigInteger('user_id');
                $table->enum('role', ['owner', 'manager'])->default('manager');
                $table->json('permissions_json')->nullable();
                $table->timestamps();

                $table->unique(['championship_id', 'user_id'], 'uq_ch_admin_user');
                $table->index(['user_id', 'role'], 'idx_ch_admin_user_role');
                $table->foreign('championship_id', 'fk_ch_admin_ch')->references('id')->on('championships')->cascadeOnDelete();
                $table->foreign('user_id', 'fk_ch_admin_user')->references('id')->on('users')->cascadeOnDelete();
            });
        }

        if (!Schema::hasTable('championship_teams')) {
            Schema::create('championship_teams', function (Blueprint $table) {
                $table->id();
                $table->unsignedBigInteger('championship_id');
                $table->string('name', 120);
                $table->string('color', 20)->nullable();
                $table->string('logo_url', 500)->nullable();
                $table->unsignedBigInteger('captain_user_id')->nullable();
                $table->enum('status', ['draft', 'active', 'eliminated', 'withdrawn'])->default('draft');
                $table->unsignedTinyInteger('sort_order')->default(0);
                $table->timestamps();

                $table->unique(['championship_id', 'name'], 'uq_ch_team_name');
                $table->index(['championship_id', 'status'], 'idx_ch_team_status');
                $table->foreign('championship_id', 'fk_ch_team_ch')->references('id')->on('championships')->cascadeOnDelete();
                $table->foreign('captain_user_id', 'fk_ch_team_captain')->references('id')->on('users')->nullOnDelete();
            });
        }

        if (!Schema::hasTable('championship_team_members')) {
            Schema::create('championship_team_members', function (Blueprint $table) {
                $table->id();
                $table->unsignedBigInteger('championship_team_id');
                $table->unsignedBigInteger('user_id');
                $table->unsignedBigInteger('invited_by_user_id')->nullable();
                $table->enum('status', ['invited', 'pending', 'approved', 'rejected', 'removed'])->default('pending');
                $table->enum('role', ['player', 'captain'])->default('player');
                $table->dateTime('joined_at')->nullable();
                $table->dateTime('removed_at')->nullable();
                $table->timestamps();

                $table->unique(['championship_team_id', 'user_id'], 'uq_ch_member_user');
                $table->index(['user_id', 'status'], 'idx_ch_member_user_status');
                $table->foreign('championship_team_id', 'fk_ch_member_team')->references('id')->on('championship_teams')->cascadeOnDelete();
                $table->foreign('user_id', 'fk_ch_member_user')->references('id')->on('users')->cascadeOnDelete();
                $table->foreign('invited_by_user_id', 'fk_ch_member_inviter')->references('id')->on('users')->nullOnDelete();
            });
        }

        if (!Schema::hasTable('championship_team_invitations')) {
            Schema::create('championship_team_invitations', function (Blueprint $table) {
                $table->id();
                $table->unsignedBigInteger('championship_id');
                $table->unsignedBigInteger('championship_team_id');
                $table->unsignedBigInteger('invited_user_id');
                $table->unsignedBigInteger('invited_by_user_id');
                $table->string('token', 100)->unique();
                $table->enum('status', ['pending', 'accepted', 'rejected', 'revoked', 'expired'])->default('pending');
                $table->dateTime('expires_at')->nullable();
                $table->dateTime('responded_at')->nullable();
                $table->timestamps();

                $table->index(['invited_user_id', 'status'], 'idx_ch_invited_status');
                $table->index(['championship_id', 'status'], 'idx_ch_invitation_status');
                $table->foreign('championship_id', 'fk_ch_inv_ch')->references('id')->on('championships')->cascadeOnDelete();
                $table->foreign('championship_team_id', 'fk_ch_inv_team')->references('id')->on('championship_teams')->cascadeOnDelete();
                $table->foreign('invited_user_id', 'fk_ch_inv_user')->references('id')->on('users')->cascadeOnDelete();
                $table->foreign('invited_by_user_id', 'fk_ch_inv_by')->references('id')->on('users')->cascadeOnDelete();
            });
        }

        if (!Schema::hasTable('championship_matchdays')) {
            Schema::create('championship_matchdays', function (Blueprint $table) {
                $table->id();
                $table->unsignedBigInteger('championship_id');
                $table->unsignedSmallInteger('number');
                $table->string('name', 100)->nullable();
                $table->date('match_date')->nullable();
                $table->dateTime('starts_at')->nullable();
                $table->dateTime('ends_at')->nullable();
                $table->enum('status', ['draft', 'scheduled', 'in_progress', 'completed', 'cancelled'])->default('draft');
                $table->timestamps();

                $table->unique(['championship_id', 'number'], 'uq_ch_matchday_number');
                $table->index(['championship_id', 'status'], 'idx_ch_matchday_status');
                $table->foreign('championship_id', 'fk_ch_matchday_ch')->references('id')->on('championships')->cascadeOnDelete();
            });
        }

        if (!Schema::hasTable('championship_matches')) {
            Schema::create('championship_matches', function (Blueprint $table) {
                $table->id();
                $table->unsignedBigInteger('championship_id');
                $table->unsignedBigInteger('matchday_id')->nullable();
                $table->unsignedBigInteger('home_team_id')->nullable();
                $table->unsignedBigInteger('away_team_id')->nullable();
                $table->unsignedBigInteger('pichanga_id')->nullable();
                $table->unsignedInteger('field_id')->nullable();
                $table->unsignedInteger('cancha_id')->nullable();
                $table->unsignedSmallInteger('round_number')->nullable();
                $table->unsignedSmallInteger('fixture_order')->nullable();
                $table->enum('phase', ['league', 'knockout', 'playoff'])->default('league');
                $table->unsignedSmallInteger('bracket_round')->nullable();
                $table->unsignedSmallInteger('bracket_position')->nullable();
                $table->dateTime('starts_at')->nullable();
                $table->dateTime('ends_at')->nullable();
                $table->unsignedSmallInteger('duration_minutes')->default(60);
                $table->enum('status', ['scheduled', 'live', 'pending_result', 'finished', 'postponed', 'cancelled'])->default('scheduled');
                $table->unsignedSmallInteger('home_score')->nullable();
                $table->unsignedSmallInteger('away_score')->nullable();
                $table->unsignedBigInteger('result_confirmed_by')->nullable();
                $table->dateTime('result_confirmed_at')->nullable();
                $table->text('notes')->nullable();
                $table->timestamps();

                $table->index(['championship_id', 'status', 'starts_at'], 'idx_ch_match_status_start');
                $table->index(['matchday_id', 'fixture_order'], 'idx_ch_matchday_order');
                $table->index(['home_team_id', 'away_team_id'], 'idx_ch_match_teams');
                $table->foreign('championship_id', 'fk_ch_match_ch')->references('id')->on('championships')->cascadeOnDelete();
                $table->foreign('matchday_id', 'fk_ch_match_day')->references('id')->on('championship_matchdays')->nullOnDelete();
                $table->foreign('home_team_id', 'fk_ch_match_home')->references('id')->on('championship_teams')->cascadeOnDelete();
                $table->foreign('away_team_id', 'fk_ch_match_away')->references('id')->on('championship_teams')->cascadeOnDelete();
                $table->foreign('result_confirmed_by', 'fk_ch_match_confirmer')->references('id')->on('users')->nullOnDelete();
            });
        }

        if (!Schema::hasTable('championship_match_squads')) {
            Schema::create('championship_match_squads', function (Blueprint $table) {
                $table->id();
                $table->unsignedBigInteger('championship_match_id');
                $table->unsignedBigInteger('championship_team_id');
                $table->unsignedBigInteger('user_id');
                $table->enum('status', ['called', 'starter', 'substitute', 'played', 'withdrawn'])->default('called');
                $table->unsignedSmallInteger('minutes_played')->default(0);
                $table->timestamps();

                $table->unique(['championship_match_id', 'user_id'], 'uq_ch_squad_user');
                $table->index(['championship_team_id', 'status'], 'idx_ch_squad_team_status');
                $table->foreign('championship_match_id', 'fk_ch_squad_match')->references('id')->on('championship_matches')->cascadeOnDelete();
                $table->foreign('championship_team_id', 'fk_ch_squad_team')->references('id')->on('championship_teams')->cascadeOnDelete();
                $table->foreign('user_id', 'fk_ch_squad_user')->references('id')->on('users')->cascadeOnDelete();
            });
        }

        if (!Schema::hasTable('championship_match_events')) {
            Schema::create('championship_match_events', function (Blueprint $table) {
                $table->id();
                $table->unsignedBigInteger('championship_match_id');
                $table->unsignedBigInteger('championship_team_id')->nullable();
                $table->unsignedBigInteger('player_user_id')->nullable();
                $table->unsignedBigInteger('secondary_player_user_id')->nullable();
                $table->unsignedBigInteger('created_by_user_id');
                $table->enum('event_type', ['goal', 'own_goal', 'assist', 'yellow_card', 'red_card', 'substitution_in', 'substitution_out'])->default('goal');
                $table->unsignedSmallInteger('minute')->nullable();
                $table->json('metadata_json')->nullable();
                $table->timestamps();

                $table->index(['championship_match_id', 'created_at'], 'idx_ch_event_match_created');
                $table->index(['player_user_id', 'event_type'], 'idx_ch_event_player_type');
                $table->foreign('championship_match_id', 'fk_ch_event_match')->references('id')->on('championship_matches')->cascadeOnDelete();
                $table->foreign('championship_team_id', 'fk_ch_event_team')->references('id')->on('championship_teams')->nullOnDelete();
                $table->foreign('player_user_id', 'fk_ch_event_player')->references('id')->on('users')->nullOnDelete();
                $table->foreign('secondary_player_user_id', 'fk_ch_event_secondary')->references('id')->on('users')->nullOnDelete();
                $table->foreign('created_by_user_id', 'fk_ch_event_creator')->references('id')->on('users')->cascadeOnDelete();
            });
        }

        if (!Schema::hasTable('championship_match_substitutions')) {
            Schema::create('championship_match_substitutions', function (Blueprint $table) {
                $table->id();
                $table->unsignedBigInteger('championship_match_id');
                $table->unsignedBigInteger('championship_team_id');
                $table->unsignedBigInteger('player_out_user_id');
                $table->unsignedBigInteger('player_in_user_id');
                $table->unsignedSmallInteger('minute')->nullable();
                $table->unsignedBigInteger('created_by_user_id');
                $table->timestamps();

                $table->index(['championship_match_id', 'minute'], 'idx_ch_sub_match_minute');
                $table->foreign('championship_match_id', 'fk_ch_sub_match')->references('id')->on('championship_matches')->cascadeOnDelete();
                $table->foreign('championship_team_id', 'fk_ch_sub_team')->references('id')->on('championship_teams')->cascadeOnDelete();
                $table->foreign('player_out_user_id', 'fk_ch_sub_out')->references('id')->on('users')->cascadeOnDelete();
                $table->foreign('player_in_user_id', 'fk_ch_sub_in')->references('id')->on('users')->cascadeOnDelete();
                $table->foreign('created_by_user_id', 'fk_ch_sub_creator')->references('id')->on('users')->cascadeOnDelete();
            });
        }

        if (!Schema::hasTable('championship_result_audits')) {
            Schema::create('championship_result_audits', function (Blueprint $table) {
                $table->id();
                $table->unsignedBigInteger('championship_match_id');
                $table->unsignedBigInteger('actor_user_id');
                $table->string('action', 60);
                $table->json('before_json')->nullable();
                $table->json('after_json')->nullable();
                $table->text('reason')->nullable();
                $table->timestamps();

                $table->index(['championship_match_id', 'created_at'], 'idx_ch_audit_match_created');
                $table->foreign('championship_match_id', 'fk_ch_audit_match')->references('id')->on('championship_matches')->cascadeOnDelete();
                $table->foreign('actor_user_id', 'fk_ch_audit_actor')->references('id')->on('users')->cascadeOnDelete();
            });
        }

        if (!Schema::hasTable('championship_player_stats')) {
            Schema::create('championship_player_stats', function (Blueprint $table) {
                $table->id();
                $table->unsignedBigInteger('championship_id');
                $table->unsignedBigInteger('user_id');
                $table->unsignedBigInteger('current_team_id')->nullable();
                $table->unsignedInteger('matches_played')->default(0);
                $table->unsignedInteger('minutes_played')->default(0);
                $table->unsignedInteger('goals')->default(0);
                $table->unsignedInteger('assists')->default(0);
                $table->unsignedInteger('goals_conceded')->default(0);
                $table->unsignedInteger('clean_sheets')->default(0);
                $table->unsignedInteger('yellow_cards')->default(0);
                $table->unsignedInteger('red_cards')->default(0);
                $table->timestamps();

                $table->unique(['championship_id', 'user_id'], 'uq_ch_player_stat');
                $table->index(['championship_id', 'goals'], 'idx_ch_player_goals');
                $table->foreign('championship_id', 'fk_ch_stat_ch')->references('id')->on('championships')->cascadeOnDelete();
                $table->foreign('user_id', 'fk_ch_stat_user')->references('id')->on('users')->cascadeOnDelete();
                $table->foreign('current_team_id', 'fk_ch_stat_team')->references('id')->on('championship_teams')->nullOnDelete();
            });
        }

        if (Schema::hasTable('group_pichangas')) {
            // Championship matches can be open to players outside a group.
            // Keep regular pichangas compatible while allowing a null club.
            if (Schema::hasColumn('group_pichangas', 'club_id')) {
                DB::statement("ALTER TABLE group_pichangas MODIFY club_id BIGINT UNSIGNED NULL");
            }
            if (!Schema::hasColumn('group_pichangas', 'championship_id')) {
                Schema::table('group_pichangas', function (Blueprint $table) {
                    $table->unsignedBigInteger('championship_id')->nullable()->after('club_id');
                    $table->index(['championship_id', 'starts_at'], 'idx_gp_championship_starts');
                });
            }
            if (!Schema::hasColumn('group_pichangas', 'championship_match_id')) {
                Schema::table('group_pichangas', function (Blueprint $table) {
                    $table->unsignedBigInteger('championship_match_id')->nullable()->after('championship_id');
                    $table->index('championship_match_id', 'idx_gp_championship_match');
                });
            }

            // The legacy enum predates official championship matches. Add or
            // expand it without rewriting existing regular/challenge rows.
            if (Schema::hasColumn('group_pichangas', 'match_context')) {
                DB::statement("ALTER TABLE group_pichangas MODIFY match_context ENUM('regular','club_challenge','championship') NOT NULL DEFAULT 'regular'");
            } else {
                Schema::table('group_pichangas', function (Blueprint $table) {
                    $table->enum('match_context', ['regular', 'club_challenge', 'championship'])
                        ->default('regular')
                        ->after('cancha_id');
                    $table->index(['match_context', 'starts_at'], 'idx_gp_match_context_starts');
                });
            }
        }
    }

    public function down(): void
    {
        if (Schema::hasTable('group_pichangas')) {
            $drop = array_values(array_filter([
                Schema::hasColumn('group_pichangas', 'championship_match_id') ? 'championship_match_id' : null,
                Schema::hasColumn('group_pichangas', 'championship_id') ? 'championship_id' : null,
            ]));
            if ($drop) {
                Schema::table('group_pichangas', function (Blueprint $table) use ($drop) {
                    $table->dropColumn($drop);
                });
            }
        }

        foreach ([
            'championship_player_stats',
            'championship_result_audits',
            'championship_match_substitutions',
            'championship_match_events',
            'championship_match_squads',
            'championship_matches',
            'championship_matchdays',
            'championship_team_invitations',
            'championship_team_members',
            'championship_teams',
            'championship_admins',
            'championships',
        ] as $table) {
            Schema::dropIfExists($table);
        }
    }
};
