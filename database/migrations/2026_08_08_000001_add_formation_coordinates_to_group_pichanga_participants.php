<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (!Schema::hasTable('group_pichanga_participants')) {
            return;
        }

        Schema::table('group_pichanga_participants', function (Blueprint $table) {
            if (!Schema::hasColumn('group_pichanga_participants', 'formation_x')) {
                $table->decimal('formation_x', 5, 4)->nullable();
            }
            if (!Schema::hasColumn('group_pichanga_participants', 'formation_y')) {
                $table->decimal('formation_y', 5, 4)->nullable();
            }
        });
    }

    public function down(): void
    {
        if (!Schema::hasTable('group_pichanga_participants')) {
            return;
        }

        $columns = [];
        if (Schema::hasColumn('group_pichanga_participants', 'formation_y')) {
            $columns[] = 'formation_y';
        }
        if (Schema::hasColumn('group_pichanga_participants', 'formation_x')) {
            $columns[] = 'formation_x';
        }
        if ($columns !== []) {
            Schema::table('group_pichanga_participants', fn (Blueprint $table) => $table->dropColumn($columns));
        }
    }
};
