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
        if (!Schema::hasTable('group_pichangas') || !Schema::hasTable('users')) {
            return;
        }

        Schema::create('group_pichanga_posts', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('pichanga_id');
            $table->unsignedBigInteger('user_id');
            $table->enum('post_type', ['text', 'photo'])->default('text');
            $table->string('content', 500)->nullable();
            $table->string('photo_url', 500)->nullable();
            $table->enum('status', ['active', 'removed'])->default('active');
            $table->unsignedBigInteger('removed_by_user_id')->nullable();
            $table->string('removed_reason', 255)->nullable();
            $table->timestamps();

            $table->index(['pichanga_id', 'status', 'created_at'], 'idx_gppost_pichanga_status_created');

            $table->foreign('pichanga_id', 'fk_gppost_pichanga')
                ->references('id')
                ->on('group_pichangas')
                ->cascadeOnDelete();
            $table->foreign('user_id', 'fk_gppost_user')
                ->references('id')
                ->on('users')
                ->cascadeOnDelete();
        });

        Schema::create('group_pichanga_comments', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('post_id');
            $table->unsignedBigInteger('pichanga_id');
            $table->unsignedBigInteger('user_id');
            $table->string('content', 500);
            $table->enum('status', ['active', 'removed'])->default('active');
            $table->unsignedBigInteger('removed_by_user_id')->nullable();
            $table->string('removed_reason', 255)->nullable();
            $table->timestamps();

            $table->index(['post_id', 'status', 'created_at'], 'idx_gpcomment_post_status_created');
            $table->index(['pichanga_id', 'status', 'created_at'], 'idx_gpcomment_pichanga_status_created');

            $table->foreign('post_id', 'fk_gpcomment_post')
                ->references('id')
                ->on('group_pichanga_posts')
                ->cascadeOnDelete();
            $table->foreign('pichanga_id', 'fk_gpcomment_pichanga')
                ->references('id')
                ->on('group_pichangas')
                ->cascadeOnDelete();
            $table->foreign('user_id', 'fk_gpcomment_user')
                ->references('id')
                ->on('users')
                ->cascadeOnDelete();
        });

        Schema::create('group_pichanga_ratings', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('pichanga_id');
            $table->unsignedBigInteger('rater_user_id');
            $table->unsignedBigInteger('rated_user_id');
            $table->decimal('fisico', 3, 1);
            $table->decimal('arquero', 3, 1);
            $table->decimal('delantero', 3, 1);
            $table->decimal('mediocampo', 3, 1);
            $table->decimal('defensa', 3, 1);
            $table->string('comentario', 500)->nullable();
            $table->timestamps();

            $table->unique(['pichanga_id', 'rater_user_id', 'rated_user_id'], 'uq_gprating_pichanga_rater_rated');
            $table->index(['rated_user_id', 'created_at'], 'idx_gprating_rated_created');

            $table->foreign('pichanga_id', 'fk_gprating_pichanga')
                ->references('id')
                ->on('group_pichangas')
                ->cascadeOnDelete();
            $table->foreign('rater_user_id', 'fk_gprating_rater')
                ->references('id')
                ->on('users')
                ->cascadeOnDelete();
            $table->foreign('rated_user_id', 'fk_gprating_rated')
                ->references('id')
                ->on('users')
                ->cascadeOnDelete();
        });

        if (Schema::hasTable('polideportivo')) {
            Schema::create('user_favorite_fields', function (Blueprint $table) {
                $table->id();
                $table->unsignedBigInteger('user_id');
                $table->unsignedInteger('polideportivo_id');
                $table->timestamps();

                $table->unique(['user_id', 'polideportivo_id'], 'uq_uff_user_field');
                $table->index(['polideportivo_id', 'created_at'], 'idx_uff_field_created');

                $table->foreign('user_id', 'fk_uff_user')->references('id')->on('users')->cascadeOnDelete();
            });
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('user_favorite_fields');
        Schema::dropIfExists('group_pichanga_ratings');
        Schema::dropIfExists('group_pichanga_comments');
        Schema::dropIfExists('group_pichanga_posts');
    }
};
