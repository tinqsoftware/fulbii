<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (!Schema::hasTable('users')) {
            return;
        }

        if (Schema::hasTable('group_pichangas') && !Schema::hasColumn('group_pichangas', 'cancha_id')) {
            Schema::table('group_pichangas', function (Blueprint $table) {
                $table->unsignedInteger('cancha_id')->nullable()->after('field_id');
                $table->index(['cancha_id'], 'idx_gp_cancha');
            });
        }

        if (!Schema::hasTable('field_geometries')) {
            Schema::create('field_geometries', function (Blueprint $table) {
                $table->id();
                $table->unsignedInteger('field_id')->nullable();
                $table->unsignedInteger('cancha_id')->nullable();
                $table->decimal('width_meters', 8, 2);
                $table->decimal('length_meters', 8, 2);
                $table->decimal('rotation_degrees', 8, 2)->default(0);
                $table->json('corners_json')->nullable();
                $table->timestamps();

                $table->unique(['cancha_id'], 'uq_field_geom_cancha');
                $table->index(['field_id'], 'idx_field_geom_field');
            });
        }

        if (!Schema::hasTable('watch_match_sessions')) {
            Schema::create('watch_match_sessions', function (Blueprint $table) {
                $table->id();
                $table->unsignedBigInteger('user_id');
                $table->unsignedBigInteger('group_pichanga_id')->nullable();
                $table->unsignedInteger('field_id')->nullable();
                $table->unsignedInteger('cancha_id')->nullable();
                $table->unsignedBigInteger('field_geometry_id')->nullable();
                $table->dateTime('start_time');
                $table->dateTime('end_time')->nullable();
                $table->enum('status', ['idle', 'live', 'paused', 'finished', 'auto_finished'])->default('live');
                $table->enum('my_goal_side', ['north', 'south', 'east', 'west', 'unknown'])->default('unknown');
                $table->decimal('distance_meters', 10, 2)->nullable();
                $table->json('device_payload_json')->nullable();
                $table->timestamps();

                $table->index(['user_id', 'created_at'], 'idx_watch_session_user_created');
                $table->index(['group_pichanga_id'], 'idx_watch_session_pichanga');
            });
        }

        if (!Schema::hasTable('watch_position_samples')) {
            Schema::create('watch_position_samples', function (Blueprint $table) {
                $table->id();
                $table->unsignedBigInteger('session_id');
                $table->dateTime('sampled_at');
                $table->decimal('lat', 11, 7);
                $table->decimal('lng', 11, 7);
                $table->decimal('horizontal_accuracy', 8, 2)->nullable();
                $table->decimal('speed', 8, 2)->nullable();
                $table->timestamps();

                $table->index(['session_id', 'sampled_at'], 'idx_watch_samples_session_time');
            });
        }

        if (!Schema::hasTable('watch_match_events')) {
            Schema::create('watch_match_events', function (Blueprint $table) {
                $table->id();
                $table->unsignedBigInteger('session_id');
                $table->enum('event_type', ['goal', 'assist', 'pause', 'resume', 'side_change']);
                $table->dateTime('event_at');
                $table->unsignedSmallInteger('minute')->nullable();
                $table->string('clock_time', 20)->nullable();
                $table->json('metadata_json')->nullable();
                $table->timestamps();

                $table->index(['session_id', 'event_at'], 'idx_watch_events_session_time');
            });
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('watch_match_events');
        Schema::dropIfExists('watch_position_samples');
        Schema::dropIfExists('watch_match_sessions');
        Schema::dropIfExists('field_geometries');
        if (Schema::hasTable('group_pichangas') && Schema::hasColumn('group_pichangas', 'cancha_id')) {
            Schema::table('group_pichangas', function (Blueprint $table) {
                $table->dropIndex('idx_gp_cancha');
                $table->dropColumn('cancha_id');
            });
        }
    }
};
