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
        if (!Schema::hasTable('clubs') || !Schema::hasTable('users')) {
            return;
        }

        Schema::create('group_pichangas', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('club_id');
            $table->unsignedBigInteger('created_by_user_id');
            $table->string('title', 160)->nullable();
            $table->text('description')->nullable();
            $table->unsignedInteger('field_id')->nullable();
            $table->string('address', 255)->nullable();
            $table->dateTime('starts_at');
            $table->unsignedSmallInteger('duration_minutes')->default(60);
            $table->unsignedSmallInteger('capacity');
            $table->enum('status', ['published', 'confirmed', 'cancelled', 'completed'])->default('published');
            $table->enum('confirmation_mode', ['auto_by_capacity', 'manual_paid'])->default('auto_by_capacity');
            $table->boolean('is_open')->default(false);
            $table->unsignedTinyInteger('notify_degree')->default(1);
            $table->boolean('allow_external_requests')->default(false);
            $table->dateTime('withdraw_until')->nullable();

            // Audience filters
            $table->enum('audience_sex', ['M', 'F'])->nullable();
            $table->unsignedTinyInteger('audience_age_min')->nullable();
            $table->unsignedTinyInteger('audience_age_max')->nullable();
            $table->unsignedTinyInteger('skill_fisico_min')->nullable();
            $table->unsignedTinyInteger('skill_arquero_min')->nullable();
            $table->unsignedTinyInteger('skill_delantero_min')->nullable();
            $table->unsignedTinyInteger('skill_mediocampo_min')->nullable();
            $table->unsignedTinyInteger('skill_defensa_min')->nullable();

            $table->dateTime('last_renotify_at')->nullable();
            $table->unsignedSmallInteger('renotify_sent_count')->default(0);
            $table->timestamps();

            $table->index(['club_id', 'starts_at'], 'idx_gp_club_starts');
            $table->index(['status', 'starts_at'], 'idx_gp_status_starts');
            $table->index(['is_open', 'starts_at'], 'idx_gp_open_starts');

            $table->foreign('club_id', 'fk_gp_club')->references('id')->on('clubs')->cascadeOnDelete();
            $table->foreign('created_by_user_id', 'fk_gp_creator')->references('id')->on('users')->cascadeOnDelete();
        });

        Schema::create('group_pichanga_participants', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('pichanga_id');
            $table->unsignedBigInteger('user_id');
            $table->enum('origin', ['member', 'external'])->default('member');
            $table->enum('status', ['confirmed', 'withdrawn', 'removed'])->default('confirmed');
            $table->dateTime('confirmed_at')->nullable();
            $table->dateTime('withdrawn_at')->nullable();
            $table->unsignedBigInteger('removed_by_user_id')->nullable();
            $table->timestamps();

            $table->unique(['pichanga_id', 'user_id'], 'uq_gpp_pichanga_user');
            $table->index(['pichanga_id', 'status'], 'idx_gpp_status');

            $table->foreign('pichanga_id', 'fk_gpp_pichanga')->references('id')->on('group_pichangas')->cascadeOnDelete();
            $table->foreign('user_id', 'fk_gpp_user')->references('id')->on('users')->cascadeOnDelete();
        });

        Schema::create('group_pichanga_external_requests', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('pichanga_id');
            $table->unsignedBigInteger('user_id');
            $table->enum('status', ['pending', 'accepted', 'rejected', 'expired'])->default('pending');
            $table->unsignedTinyInteger('origin_degree')->nullable();
            $table->unsignedBigInteger('relation_user_id')->nullable();
            $table->unsignedBigInteger('decided_by_user_id')->nullable();
            $table->dateTime('requested_at')->nullable();
            $table->dateTime('decided_at')->nullable();
            $table->string('note', 255)->nullable();
            $table->timestamps();

            $table->unique(['pichanga_id', 'user_id'], 'uq_gper_pichanga_user');
            $table->index(['pichanga_id', 'status'], 'idx_gper_status');

            $table->foreign('pichanga_id', 'fk_gper_pichanga')->references('id')->on('group_pichangas')->cascadeOnDelete();
            $table->foreign('user_id', 'fk_gper_user')->references('id')->on('users')->cascadeOnDelete();
        });

        Schema::create('group_pichanga_notification_batches', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('pichanga_id');
            $table->unsignedBigInteger('triggered_by_user_id');
            $table->enum('batch_type', ['initial', 'manual_renotify'])->default('manual_renotify');
            $table->unsignedTinyInteger('target_degree')->default(1);
            $table->json('filters_json')->nullable();
            $table->unsignedInteger('target_count')->default(0);
            $table->unsignedInteger('muted_skipped_count')->default(0);
            $table->unsignedInteger('sent_count')->default(0);
            $table->timestamps();

            $table->index(['pichanga_id', 'created_at'], 'idx_gpb_pichanga_created');

            $table->foreign('pichanga_id', 'fk_gpb_pichanga')->references('id')->on('group_pichangas')->cascadeOnDelete();
            $table->foreign('triggered_by_user_id', 'fk_gpb_user')->references('id')->on('users')->cascadeOnDelete();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('group_pichanga_notification_batches');
        Schema::dropIfExists('group_pichanga_external_requests');
        Schema::dropIfExists('group_pichanga_participants');
        Schema::dropIfExists('group_pichangas');
    }
};
