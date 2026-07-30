<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('field_submissions', function (Blueprint $table) {
            $table->string('submission_type', 40)->default('new_polideportivo')->after('status');
            $table->unsignedBigInteger('existing_polideportivo_id')->nullable()->after('source_type');
            $table->string('cancha_nombre', 250)->nullable()->after('existing_polideportivo_id');
            $table->string('cancha_equiposvs', 10)->nullable()->after('cancha_nombre');
            $table->string('cancha_tipo_superficie', 30)->nullable()->after('cancha_equiposvs');
            $table->string('cancha_anchom2', 50)->nullable()->after('cancha_tipo_superficie');
            $table->string('cancha_largom2', 50)->nullable()->after('cancha_anchom2');
            $table->unsignedBigInteger('approved_cancha_id')->nullable()->after('approved_polideportivo_id');
            $table->index('existing_polideportivo_id');
        });
    }

    public function down(): void
    {
        Schema::table('field_submissions', function (Blueprint $table) {
            $table->dropIndex(['existing_polideportivo_id']);
            $table->dropColumn([
                'submission_type', 'existing_polideportivo_id', 'cancha_nombre',
                'cancha_equiposvs', 'cancha_tipo_superficie', 'cancha_anchom2',
                'cancha_largom2', 'approved_cancha_id',
            ]);
        });
    }
};
