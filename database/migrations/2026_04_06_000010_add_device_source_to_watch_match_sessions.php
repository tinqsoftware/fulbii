<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasTable('watch_match_sessions') && !Schema::hasColumn('watch_match_sessions', 'device')) {
            Schema::table('watch_match_sessions', function (Blueprint $table) {
                $table->enum('device', ['watchos', 'wearos'])->default('watchos')->after('my_goal_side');
                $table->enum('source', ['live', 'simulated'])->default('live')->after('device');
            });
        }
    }

    public function down(): void
    {
        if (Schema::hasTable('watch_match_sessions')) {
            if (Schema::hasColumn('watch_match_sessions', 'source')) {
                Schema::table('watch_match_sessions', function (Blueprint $table) {
                    $table->dropColumn('source');
                });
            }
            if (Schema::hasColumn('watch_match_sessions', 'device')) {
                Schema::table('watch_match_sessions', function (Blueprint $table) {
                    $table->dropColumn('device');
                });
            }
        }
    }
};
