<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (!Schema::hasTable('championship_matches')) {
            return;
        }

        // The base migration already creates nullable slots. These guarded
        // alterations keep environments that ran an earlier draft compatible.
        DB::statement('ALTER TABLE championship_matches MODIFY home_team_id BIGINT UNSIGNED NULL');
        DB::statement('ALTER TABLE championship_matches MODIFY away_team_id BIGINT UNSIGNED NULL');

        Schema::table('championship_matches', function (Blueprint $table): void {
            if (!Schema::hasColumn('championship_matches', 'phase')) {
                $table->enum('phase', ['league', 'knockout', 'playoff'])
                    ->default('league')
                    ->after('fixture_order');
            }
            if (!Schema::hasColumn('championship_matches', 'bracket_round')) {
                $table->unsignedSmallInteger('bracket_round')->nullable()->after('phase');
            }
            if (!Schema::hasColumn('championship_matches', 'bracket_position')) {
                $table->unsignedSmallInteger('bracket_position')->nullable()->after('bracket_round');
            }
        });

        Schema::table('championship_matches', function (Blueprint $table): void {
            $table->index(
                ['championship_id', 'phase', 'bracket_round', 'bracket_position'],
                'idx_ch_bracket_position'
            );
        });
    }

    public function down(): void
    {
        if (!Schema::hasTable('championship_matches')) {
            return;
        }
        Schema::table('championship_matches', function (Blueprint $table): void {
            $table->dropIndex('idx_ch_bracket_position');
            foreach (['bracket_position', 'bracket_round', 'phase'] as $column) {
                if (Schema::hasColumn('championship_matches', $column)) {
                    $table->dropColumn($column);
                }
            }
        });
    }
};
