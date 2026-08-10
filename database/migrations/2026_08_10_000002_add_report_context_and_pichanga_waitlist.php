<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('reports', function (Blueprint $table) {
            $table->string('content_type', 50)->nullable()->after('target_id');
            $table->unsignedBigInteger('content_id')->nullable()->after('content_type');
            $table->index(['content_type', 'content_id'], 'idx_reports_content');
        });

        Schema::create('group_pichanga_waitlist', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('pichanga_id');
            $table->unsignedBigInteger('user_id');
            $table->string('team_code', 4)->nullable();
            $table->string('status', 20)->default('waiting');
            $table->dateTime('promoted_at')->nullable();
            $table->dateTime('withdrawn_at')->nullable();
            $table->timestamps();

            $table->unique(['pichanga_id', 'user_id'], 'uq_pichanga_waitlist_user');
            $table->index(['pichanga_id', 'status', 'created_at'], 'idx_pichanga_waitlist_fifo');
            $table->foreign('pichanga_id')->references('id')->on('group_pichangas')->cascadeOnDelete();
            $table->foreign('user_id')->references('id')->on('users')->cascadeOnDelete();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('group_pichanga_waitlist');
        Schema::table('reports', function (Blueprint $table) {
            $table->dropIndex('idx_reports_content');
            $table->dropColumn(['content_type', 'content_id']);
        });
    }
};
