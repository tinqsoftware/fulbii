<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('field_submission_photos', function (Blueprint $table) {
            $table->string('asset_type', 20)->default('court')->after('photo_url');
            $table->unsignedSmallInteger('sort_order')->default(0)->after('asset_type');
            $table->index(['field_submission_id', 'asset_type', 'status'], 'fsp_subject_status_idx');
        });

        Schema::create('polideportivo_photos', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('polideportivo_id');
            $table->string('photo_url', 500);
            $table->unsignedSmallInteger('sort_order')->default(0);
            $table->timestamps();
            $table->index(['polideportivo_id', 'sort_order']);
        });

        Schema::create('cancha_photos', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('cancha_id');
            $table->string('photo_url', 500);
            $table->unsignedSmallInteger('sort_order')->default(0);
            $table->timestamps();
            $table->index(['cancha_id', 'sort_order']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('cancha_photos');
        Schema::dropIfExists('polideportivo_photos');
        Schema::table('field_submission_photos', function (Blueprint $table) {
            $table->dropIndex('fsp_subject_status_idx');
            $table->dropColumn(['asset_type', 'sort_order']);
        });
    }
};
