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
            if (!Schema::hasColumn('group_pichanga_participants', 'formation_role')) {
                $table->string('formation_role', 16)->nullable()->after('team_slot');
            }
            if (!Schema::hasColumn('group_pichanga_participants', 'formation_order')) {
                $table->unsignedSmallInteger('formation_order')->nullable()->after('formation_role');
            }
        });
    }

    public function down(): void
    {
        if (!Schema::hasTable('group_pichanga_participants')) {
            return;
        }

        Schema::table('group_pichanga_participants', function (Blueprint $table) {
            $columns = [];
            if (Schema::hasColumn('group_pichanga_participants', 'formation_order')) {
                $columns[] = 'formation_order';
            }
            if (Schema::hasColumn('group_pichanga_participants', 'formation_role')) {
                $columns[] = 'formation_role';
            }
            if ($columns !== []) {
                $table->dropColumn($columns);
            }
        });
    }
};
