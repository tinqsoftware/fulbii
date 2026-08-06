<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (!Schema::hasTable('group_pichangas')) {
            return;
        }

        Schema::table('group_pichangas', function (Blueprint $table) {
            $table->decimal('skill_fisico_min', 3, 1)->nullable()->change();
            $table->decimal('skill_arquero_min', 3, 1)->nullable()->change();
            $table->decimal('skill_delantero_min', 3, 1)->nullable()->change();
            $table->decimal('skill_mediocampo_min', 3, 1)->nullable()->change();
            $table->decimal('skill_defensa_min', 3, 1)->nullable()->change();
        });
    }

    public function down(): void
    {
        if (!Schema::hasTable('group_pichangas')) {
            return;
        }

        Schema::table('group_pichangas', function (Blueprint $table) {
            $table->unsignedTinyInteger('skill_fisico_min')->nullable()->change();
            $table->unsignedTinyInteger('skill_arquero_min')->nullable()->change();
            $table->unsignedTinyInteger('skill_delantero_min')->nullable()->change();
            $table->unsignedTinyInteger('skill_mediocampo_min')->nullable()->change();
            $table->unsignedTinyInteger('skill_defensa_min')->nullable()->change();
        });
    }
};
