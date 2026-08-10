<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (!Schema::hasTable('field_submissions')) {
            return;
        }

        Schema::table('field_submissions', function (Blueprint $table) {
            $table->index(['user_id', 'status', 'created_at'], 'field_submissions_user_status_created_idx');
        });

        if (Schema::hasColumn('field_submissions', 'approved_polideportivo_id')) {
            Schema::table('field_submissions', function (Blueprint $table) {
                $table->index('approved_polideportivo_id', 'field_submissions_approved_field_idx');
            });
        }
        if (Schema::hasColumn('field_submissions', 'approved_cancha_id')) {
            Schema::table('field_submissions', function (Blueprint $table) {
                $table->index('approved_cancha_id', 'field_submissions_approved_court_idx');
            });
        }
    }

    public function down(): void
    {
        if (!Schema::hasTable('field_submissions')) {
            return;
        }

        Schema::table('field_submissions', function (Blueprint $table) {
            $table->dropIndex('field_submissions_user_status_created_idx');
        });
        if (Schema::hasColumn('field_submissions', 'approved_polideportivo_id')) {
            Schema::table('field_submissions', function (Blueprint $table) {
                $table->dropIndex('field_submissions_approved_field_idx');
            });
        }
        if (Schema::hasColumn('field_submissions', 'approved_cancha_id')) {
            Schema::table('field_submissions', function (Blueprint $table) {
                $table->dropIndex('field_submissions_approved_court_idx');
            });
        }
    }
};
