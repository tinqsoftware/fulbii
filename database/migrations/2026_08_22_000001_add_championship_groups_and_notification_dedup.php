<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasTable('championships') && Schema::hasTable('clubs') && !Schema::hasTable('championship_clubs')) {
            Schema::create('championship_clubs', function (Blueprint $table): void {
                $table->id();
                $table->unsignedBigInteger('championship_id');
                $table->unsignedBigInteger('club_id');
                $table->timestamps();

                $table->unique(['championship_id', 'club_id'], 'uq_ch_club');
                $table->index(['club_id', 'championship_id'], 'idx_ch_club_club');
                $table->foreign('championship_id', 'fk_ch_club_ch')
                    ->references('id')->on('championships')->cascadeOnDelete();
                $table->foreign('club_id', 'fk_ch_club_club')
                    ->references('id')->on('clubs')->cascadeOnDelete();
            });

            if (Schema::hasColumn('championships', 'club_id')) {
                DB::table('championships')
                    ->whereNotNull('club_id')
                    ->orderBy('id')
                    ->eachById(function (object $championship): void {
                        DB::table('championship_clubs')->insertOrIgnore([
                            'championship_id' => $championship->id,
                            'club_id' => $championship->club_id,
                            'created_at' => now(),
                            'updated_at' => now(),
                        ]);
                    });
            }
        }

        if (Schema::hasTable('push_notifications')) {
            if (!Schema::hasColumn('push_notifications', 'dedupe_key')) {
                Schema::table('push_notifications', function (Blueprint $table): void {
                    $table->string('dedupe_key', 180)->nullable()->after('type');
                });
            }

            // A notification event must be idempotent per recipient. A
            // nullable unique key keeps legacy rows (NULL) untouched, while
            // retries cannot create a second copy for the same user/event
            // pair. This second guard also repairs installations where an
            // earlier deploy added the column but did not finish the index.
            if (!Schema::hasIndex('push_notifications', 'uq_pn_user_dedupe')) {
                Schema::table('push_notifications', function (Blueprint $table): void {
                    $table->unique(['user_id', 'dedupe_key'], 'uq_pn_user_dedupe');
                });
            }
        }
    }

    public function down(): void
    {
        if (Schema::hasTable('push_notifications') && Schema::hasColumn('push_notifications', 'dedupe_key')) {
            Schema::table('push_notifications', function (Blueprint $table): void {
                if (Schema::hasIndex('push_notifications', 'uq_pn_user_dedupe')) {
                    $table->dropUnique('uq_pn_user_dedupe');
                }
                $table->dropColumn('dedupe_key');
            });
        }

        Schema::dropIfExists('championship_clubs');
    }
};
