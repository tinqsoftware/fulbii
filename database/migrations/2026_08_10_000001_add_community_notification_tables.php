<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('club_notification_categories', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('user_id');
            $table->unsignedBigInteger('club_id');
            $table->string('category', 40);
            $table->boolean('is_enabled')->default(true);
            $table->timestamps();
            $table->unique(['user_id', 'club_id', 'category'], 'uq_club_notification_category');
            $table->index(['club_id', 'category', 'is_enabled'], 'idx_club_notification_category_enabled');
            $table->foreign('user_id')->references('id')->on('users')->cascadeOnDelete();
            $table->foreign('club_id')->references('id')->on('clubs')->cascadeOnDelete();
        });

        Schema::create('club_admin_activities', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('club_id');
            $table->unsignedBigInteger('actor_user_id')->nullable();
            $table->unsignedBigInteger('target_user_id')->nullable();
            $table->string('type', 80);
            $table->json('meta_json')->nullable();
            $table->timestamps();
            $table->index(['club_id', 'created_at'], 'idx_club_admin_activity_created');
            $table->foreign('club_id')->references('id')->on('clubs')->cascadeOnDelete();
            $table->foreign('actor_user_id')->references('id')->on('users')->nullOnDelete();
            $table->foreign('target_user_id')->references('id')->on('users')->nullOnDelete();
        });

        Schema::create('club_group_messages', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('club_id');
            $table->unsignedBigInteger('user_id')->nullable();
            $table->enum('type', ['text', 'system'])->default('text');
            $table->text('body');
            $table->json('meta_json')->nullable();
            $table->timestamps();
            $table->index(['club_id', 'id'], 'idx_club_group_message_timeline');
            $table->foreign('club_id')->references('id')->on('clubs')->cascadeOnDelete();
            $table->foreign('user_id')->references('id')->on('users')->nullOnDelete();
        });

        Schema::create('club_group_message_reads', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('club_id');
            $table->unsignedBigInteger('user_id');
            $table->unsignedBigInteger('last_read_message_id')->nullable();
            $table->timestamps();
            $table->unique(['club_id', 'user_id'], 'uq_club_group_message_read');
            $table->foreign('club_id')->references('id')->on('clubs')->cascadeOnDelete();
            $table->foreign('user_id')->references('id')->on('users')->cascadeOnDelete();
        });

        Schema::create('user_blocks', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('blocker_user_id');
            $table->unsignedBigInteger('blocked_user_id');
            $table->timestamps();
            $table->unique(['blocker_user_id', 'blocked_user_id'], 'uq_user_block');
            $table->foreign('blocker_user_id')->references('id')->on('users')->cascadeOnDelete();
            $table->foreign('blocked_user_id')->references('id')->on('users')->cascadeOnDelete();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('user_blocks');
        Schema::dropIfExists('club_group_message_reads');
        Schema::dropIfExists('club_group_messages');
        Schema::dropIfExists('club_admin_activities');
        Schema::dropIfExists('club_notification_categories');
    }
};
