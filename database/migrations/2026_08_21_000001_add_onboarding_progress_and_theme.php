<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (!Schema::hasTable('users')) {
            return;
        }

        $columns = [];
        if (!Schema::hasColumn('users', 'onboarding_completed_at')) {
            $columns['onboarding_completed_at'] = fn (Blueprint $table) => $table->timestamp('onboarding_completed_at')->nullable();
        }
        if (!Schema::hasColumn('users', 'onboarding_step')) {
            $columns['onboarding_step'] = fn (Blueprint $table) => $table->unsignedTinyInteger('onboarding_step')->default(1);
        }
        if (!Schema::hasColumn('users', 'theme_mode')) {
            $columns['theme_mode'] = fn (Blueprint $table) => $table->string('theme_mode', 10)->nullable();
        }
        if (!Schema::hasColumn('users', 'initial_self_rating_locked')) {
            $columns['initial_self_rating_locked'] = fn (Blueprint $table) => $table->boolean('initial_self_rating_locked')->default(false);
        }

        foreach ($columns as $add) {
            Schema::table('users', $add);
        }
    }

    public function down(): void
    {
        if (!Schema::hasTable('users')) {
            return;
        }
        $drop = array_values(array_filter([
            Schema::hasColumn('users', 'onboarding_completed_at') ? 'onboarding_completed_at' : null,
            Schema::hasColumn('users', 'onboarding_step') ? 'onboarding_step' : null,
            Schema::hasColumn('users', 'theme_mode') ? 'theme_mode' : null,
            Schema::hasColumn('users', 'initial_self_rating_locked') ? 'initial_self_rating_locked' : null,
        ]));
        if ($drop) {
            Schema::table('users', fn (Blueprint $table) => $table->dropColumn($drop));
        }
    }
};
