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
        if (!Schema::hasTable('users') || !Schema::hasTable('clubs')) {
            return;
        }

        Schema::create('user_group_notification_prefs', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('user_id');
            $table->unsignedBigInteger('club_id');
            $table->enum('mode', ['always_on', 'mute_24h', 'mute_1w', 'mute_forever'])->default('always_on');
            $table->timestamp('muted_until')->nullable();
            $table->boolean('updated_by_user')->default(true);
            $table->timestamps();

            $table->unique(['user_id', 'club_id'], 'uq_user_club_notification_pref');
            $table->index(['club_id', 'mode'], 'idx_club_mode');
            $table->index('muted_until', 'idx_muted_until');

            $table->foreign('user_id', 'fk_ugnp_user')
                ->references('id')
                ->on('users')
                ->cascadeOnDelete();
            $table->foreign('club_id', 'fk_ugnp_club')
                ->references('id')
                ->on('clubs')
                ->cascadeOnDelete();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('user_group_notification_prefs');
    }
};
