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

        if (!Schema::hasColumn('users', 'suspended_until')) {
            Schema::table('users', function (Blueprint $table) {
                $table->dateTime('suspended_until')->nullable()->after('avatar_url');
            });
        }

        if (!Schema::hasColumn('users', 'suspension_reason')) {
            Schema::table('users', function (Blueprint $table) {
                $table->string('suspension_reason', 255)->nullable()->after('suspended_until');
            });
        }

        Schema::create('field_submissions', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('user_id');
            $table->enum('status', ['pending', 'approved', 'rejected'])->default('pending');
            $table->string('nombre', 250);
            $table->string('direccion', 255)->nullable();
            $table->string('x', 50)->nullable();
            $table->string('y', 50)->nullable();
            $table->string('celular', 20)->nullable();
            $table->boolean('wsp')->default(false);
            $table->integer('id_distrito')->nullable();
            $table->string('descripcion', 300)->nullable();
            $table->string('precio_desde', 10)->nullable();
            $table->enum('source_type', ['gps', 'manual_map'])->default('gps');
            $table->unsignedBigInteger('reviewed_by_user_id')->nullable();
            $table->dateTime('reviewed_at')->nullable();
            $table->integer('approved_polideportivo_id')->nullable();
            $table->string('resolution_note', 255)->nullable();
            $table->timestamps();

            $table->index(['status', 'created_at'], 'idx_fs_status_created');
            $table->index(['user_id', 'created_at'], 'idx_fs_user_created');

            $table->foreign('user_id', 'fk_fs_user')->references('id')->on('users')->cascadeOnDelete();
        });

        Schema::create('field_submission_photos', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('field_submission_id');
            $table->string('photo_url', 500);
            $table->enum('status', ['active', 'removed'])->default('active');
            $table->unsignedBigInteger('removed_by_user_id')->nullable();
            $table->string('removed_reason', 255)->nullable();
            $table->timestamps();

            $table->index(['field_submission_id', 'status'], 'idx_fsp_submission_status');

            $table->foreign('field_submission_id', 'fk_fsp_submission')
                ->references('id')
                ->on('field_submissions')
                ->cascadeOnDelete();
        });

        Schema::create('reports', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('reporter_user_id');
            $table->enum('target_type', ['user', 'field', 'field_photo', 'group_pichanga']);
            $table->unsignedBigInteger('target_id');
            $table->string('reason_code', 60);
            $table->string('description', 500)->nullable();
            $table->enum('status', ['pending', 'reviewed', 'dismissed', 'actioned'])->default('pending');
            $table->unsignedBigInteger('resolved_by_user_id')->nullable();
            $table->dateTime('resolved_at')->nullable();
            $table->string('resolution_note', 255)->nullable();
            $table->timestamps();

            $table->index(['status', 'created_at'], 'idx_reports_status_created');
            $table->index(['target_type', 'target_id'], 'idx_reports_target');
            $table->index(['reporter_user_id', 'created_at'], 'idx_reports_reporter_created');

            $table->foreign('reporter_user_id', 'fk_reports_reporter')->references('id')->on('users')->cascadeOnDelete();
        });

        Schema::create('strikes', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('user_id');
            $table->unsignedBigInteger('report_id')->nullable();
            $table->unsignedBigInteger('assigned_by_user_id');
            $table->string('reason_code', 60);
            $table->string('description', 500)->nullable();
            $table->enum('status', ['active', 'revoked'])->default('active');
            $table->dateTime('expires_at')->nullable();
            $table->unsignedBigInteger('revoked_by_user_id')->nullable();
            $table->dateTime('revoked_at')->nullable();
            $table->string('revoked_note', 255)->nullable();
            $table->timestamps();

            $table->index(['user_id', 'status', 'created_at'], 'idx_strikes_user_status_created');
            $table->index(['report_id'], 'idx_strikes_report');

            $table->foreign('user_id', 'fk_strikes_user')->references('id')->on('users')->cascadeOnDelete();
            $table->foreign('assigned_by_user_id', 'fk_strikes_assigned_by')->references('id')->on('users')->cascadeOnDelete();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('strikes');
        Schema::dropIfExists('reports');
        Schema::dropIfExists('field_submission_photos');
        Schema::dropIfExists('field_submissions');
    }
};
