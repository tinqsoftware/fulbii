<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasTable('field_submissions') && !Schema::hasColumn('field_submissions', 'metadata_json')) {
            Schema::table('field_submissions', function (Blueprint $table) {
                $table->json('metadata_json')->nullable()->after('source_type');
            });
        }
    }

    public function down(): void
    {
        if (Schema::hasTable('field_submissions') && Schema::hasColumn('field_submissions', 'metadata_json')) {
            Schema::table('field_submissions', function (Blueprint $table) {
                $table->dropColumn('metadata_json');
            });
        }
    }
};
