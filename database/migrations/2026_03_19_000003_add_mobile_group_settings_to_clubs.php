<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        if (!Schema::hasTable('clubs')) {
            return;
        }

        if (!Schema::hasColumn('clubs', 'is_visible')) {
            Schema::table('clubs', function (Blueprint $table) {
                $table->boolean('is_visible')->default(true)->after('estado');
            });
        }

        if (!Schema::hasColumn('clubs', 'pichanga_create_scope')) {
            Schema::table('clubs', function (Blueprint $table) {
                $table->enum('pichanga_create_scope', ['admins', 'members'])
                    ->default('admins')
                    ->after('is_visible');
            });
        }

        if (!Schema::hasColumn('clubs', 'renotify_scope')) {
            Schema::table('clubs', function (Blueprint $table) {
                $table->enum('renotify_scope', ['admins', 'members'])
                    ->default('admins')
                    ->after('pichanga_create_scope');
            });
        }

        if (!Schema::hasColumn('clubs', 'renotify_cooldown_minutes')) {
            Schema::table('clubs', function (Blueprint $table) {
                $table->unsignedSmallInteger('renotify_cooldown_minutes')
                    ->default(30)
                    ->after('renotify_scope');
            });
        }

        if (!Schema::hasColumn('clubs', 'renotify_max_per_pichanga')) {
            Schema::table('clubs', function (Blueprint $table) {
                $table->unsignedSmallInteger('renotify_max_per_pichanga')
                    ->default(5)
                    ->after('renotify_cooldown_minutes');
            });
        }

        if (!Schema::hasColumn('clubs', 'audience_max_degree')) {
            Schema::table('clubs', function (Blueprint $table) {
                $table->unsignedTinyInteger('audience_max_degree')
                    ->default(1)
                    ->after('renotify_max_per_pichanga');
            });
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        if (!Schema::hasTable('clubs')) {
            return;
        }

        $columnsToDrop = [];
        foreach ([
            'is_visible',
            'pichanga_create_scope',
            'renotify_scope',
            'renotify_cooldown_minutes',
            'renotify_max_per_pichanga',
            'audience_max_degree',
        ] as $column) {
            if (Schema::hasColumn('clubs', $column)) {
                $columnsToDrop[] = $column;
            }
        }

        if (!empty($columnsToDrop)) {
            Schema::table('clubs', function (Blueprint $table) use ($columnsToDrop) {
                $table->dropColumn($columnsToDrop);
            });
        }
    }
};
