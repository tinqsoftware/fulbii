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

        if (!Schema::hasColumn('users', 'nick')) {
            Schema::table('users', function (Blueprint $table) {
                $table->string('nick', 200)->nullable()->after('name');
            });
        }

        if (!Schema::hasColumn('users', 'sexo')) {
            Schema::table('users', function (Blueprint $table) {
                $table->string('sexo', 2)->nullable()->after('nick');
            });
        }

        if (!Schema::hasColumn('users', 'fec_nac')) {
            Schema::table('users', function (Blueprint $table) {
                $table->date('fec_nac')->nullable()->after('email');
            });
        }

        if (!Schema::hasColumn('users', 'altura_cm')) {
            Schema::table('users', function (Blueprint $table) {
                $table->unsignedSmallInteger('altura_cm')->nullable()->after('fec_nac');
            });
        }

        if (!Schema::hasColumn('users', 'estado')) {
            Schema::table('users', function (Blueprint $table) {
                $table->string('estado', 2)->default('1')->after('altura_cm');
            });
        }

        if (!Schema::hasColumn('users', 'auth_provider')) {
            Schema::table('users', function (Blueprint $table) {
                $table->string('auth_provider', 30)->nullable()->after('password');
            });
        }

        if (!Schema::hasColumn('users', 'provider_uid')) {
            Schema::table('users', function (Blueprint $table) {
                $table->string('provider_uid', 191)->nullable()->after('auth_provider');
            });
        }

        if (!Schema::hasColumn('users', 'avatar_url')) {
            Schema::table('users', function (Blueprint $table) {
                $table->string('avatar_url', 500)->nullable()->after('provider_uid');
            });
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        if (!Schema::hasTable('users')) {
            return;
        }

        $columnsToDrop = [];

        foreach (['auth_provider', 'provider_uid', 'avatar_url', 'altura_cm'] as $column) {
            if (Schema::hasColumn('users', $column)) {
                $columnsToDrop[] = $column;
            }
        }

        if (!empty($columnsToDrop)) {
            Schema::table('users', function (Blueprint $table) use ($columnsToDrop) {
                $table->dropColumn($columnsToDrop);
            });
        }
    }
};
