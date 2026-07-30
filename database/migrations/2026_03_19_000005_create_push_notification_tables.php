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
        if (!Schema::hasTable('users')) {
            return;
        }

        Schema::create('user_devices', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('user_id');
            $table->enum('platform', ['ios', 'android', 'web']);
            $table->string('device_token', 255);
            $table->string('device_name', 100)->nullable();
            $table->string('app_version', 40)->nullable();
            $table->boolean('is_active')->default(true);
            $table->dateTime('last_seen_at')->nullable();
            $table->timestamps();

            $table->unique(['platform', 'device_token'], 'uq_ud_platform_token');
            $table->index(['user_id', 'is_active'], 'idx_ud_user_active');

            $table->foreign('user_id', 'fk_ud_user')->references('id')->on('users')->cascadeOnDelete();
        });

        Schema::create('push_notifications', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('user_id');
            $table->unsignedBigInteger('club_id')->nullable();
            $table->unsignedBigInteger('group_pichanga_id')->nullable();
            $table->string('type', 80);
            $table->string('title', 140);
            $table->string('body', 500);
            $table->json('data_json')->nullable();
            $table->boolean('is_read')->default(false);
            $table->dateTime('read_at')->nullable();
            $table->timestamps();

            $table->index(['user_id', 'is_read', 'created_at'], 'idx_pn_user_read_created');
            $table->index(['club_id', 'created_at'], 'idx_pn_club_created');
            $table->index(['group_pichanga_id', 'created_at'], 'idx_pn_pichanga_created');

            $table->foreign('user_id', 'fk_pn_user')->references('id')->on('users')->cascadeOnDelete();
        });

        Schema::create('push_dispatch_logs', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('push_notification_id');
            $table->unsignedBigInteger('user_device_id')->nullable();
            $table->enum('status', ['queued', 'sent', 'failed'])->default('queued');
            $table->string('provider', 30)->default('log');
            $table->text('provider_response')->nullable();
            $table->string('error_message', 255)->nullable();
            $table->dateTime('sent_at')->nullable();
            $table->timestamps();

            $table->index(['push_notification_id', 'status'], 'idx_pdl_notification_status');

            $table->foreign('push_notification_id', 'fk_pdl_notification')
                ->references('id')
                ->on('push_notifications')
                ->cascadeOnDelete();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('push_dispatch_logs');
        Schema::dropIfExists('push_notifications');
        Schema::dropIfExists('user_devices');
    }
};
