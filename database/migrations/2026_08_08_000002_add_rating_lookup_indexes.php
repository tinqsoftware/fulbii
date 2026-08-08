<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasTable('calificaciones') && Schema::hasColumn('calificaciones', 'user_calificador_id')) {
            Schema::table('calificaciones', function (Blueprint $table) {
                $table->index(['user_calificador_id', 'user_calificado_id', 'created_at'], 'ratings_weekly_pair_created_idx');
                $table->index(['user_calificado_id', 'created_at'], 'ratings_received_created_idx');
            });
        }
    }

    public function down(): void
    {
        if (Schema::hasTable('calificaciones')) {
            Schema::table('calificaciones', function (Blueprint $table) {
                $table->dropIndex('ratings_weekly_pair_created_idx');
                $table->dropIndex('ratings_received_created_idx');
            });
        }
    }
};
