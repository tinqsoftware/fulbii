<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasTable('watch_match_sessions')) {
            Schema::table('watch_match_sessions', function (Blueprint $table) {
                if (!Schema::hasColumn('watch_match_sessions', 'external_session_id')) {
                    $table->string('external_session_id', 64)->nullable()->after('id');
                }
                if (!Schema::hasColumn('watch_match_sessions', 'distance_meters_raw')) {
                    $table->decimal('distance_meters_raw', 10, 2)->nullable()->after('distance_meters');
                }
                if (!Schema::hasColumn('watch_match_sessions', 'distance_meters_filtered')) {
                    $table->decimal('distance_meters_filtered', 10, 2)->nullable()->after('distance_meters_raw');
                }
            });

            if (!$this->indexExists('watch_match_sessions', 'idx_watch_session_user_ext')) {
                Schema::table('watch_match_sessions', function (Blueprint $table) {
                    $table->index(['user_id', 'external_session_id'], 'idx_watch_session_user_ext');
                });
            }
        }

        if (Schema::hasTable('watch_position_samples')) {
            Schema::table('watch_position_samples', function (Blueprint $table) {
                if (!Schema::hasColumn('watch_position_samples', 'quality_flag')) {
                    $table->enum('quality_flag', ['good', 'weak', 'rejected'])->nullable()->after('speed');
                }
            });

            if (!$this->indexExists('watch_position_samples', 'idx_watch_samples_session_quality_time')) {
                Schema::table('watch_position_samples', function (Blueprint $table) {
                    $table->index(
                        ['session_id', 'quality_flag', 'sampled_at'],
                        'idx_watch_samples_session_quality_time'
                    );
                });
            }
        }
    }

    public function down(): void
    {
        if (Schema::hasTable('watch_position_samples')) {
            if ($this->indexExists('watch_position_samples', 'idx_watch_samples_session_quality_time')) {
                Schema::table('watch_position_samples', function (Blueprint $table) {
                    $table->dropIndex('idx_watch_samples_session_quality_time');
                });
            }
            if (Schema::hasColumn('watch_position_samples', 'quality_flag')) {
                Schema::table('watch_position_samples', function (Blueprint $table) {
                    $table->dropColumn('quality_flag');
                });
            }
        }

        if (Schema::hasTable('watch_match_sessions')) {
            if ($this->indexExists('watch_match_sessions', 'idx_watch_session_user_ext')) {
                Schema::table('watch_match_sessions', function (Blueprint $table) {
                    $table->dropIndex('idx_watch_session_user_ext');
                });
            }
            $dropColumns = [];
            if (Schema::hasColumn('watch_match_sessions', 'distance_meters_filtered')) {
                $dropColumns[] = 'distance_meters_filtered';
            }
            if (Schema::hasColumn('watch_match_sessions', 'distance_meters_raw')) {
                $dropColumns[] = 'distance_meters_raw';
            }
            if (Schema::hasColumn('watch_match_sessions', 'external_session_id')) {
                $dropColumns[] = 'external_session_id';
            }
            if (!empty($dropColumns)) {
                Schema::table('watch_match_sessions', function (Blueprint $table) use ($dropColumns) {
                    $table->dropColumn($dropColumns);
                });
            }
        }
    }

    private function indexExists(string $table, string $indexName): bool
    {
        $rows = DB::select("SHOW INDEX FROM `{$table}` WHERE Key_name = ?", [$indexName]);
        return !empty($rows);
    }
};

