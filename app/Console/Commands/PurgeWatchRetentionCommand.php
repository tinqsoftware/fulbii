<?php

namespace App\Console\Commands;

use App\Models\WatchMatchEvent;
use App\Models\WatchMatchSession;
use App\Models\WatchPositionSample;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class PurgeWatchRetentionCommand extends Command
{
    protected $signature = 'watch:purge-retained {--days= : Días de retención, por defecto WATCH_RETENTION_DAYS}';
    protected $description = 'Elimina permanentemente sesiones Watch y datos de ubicación fuera de retención.';

    public function handle(): int
    {
        if (!Schema::hasTable('watch_match_sessions')) {
            $this->info('No existen tablas Watch.');
            return self::SUCCESS;
        }

        $days = max(1, (int) ($this->option('days') ?: config('watch.retention_days', 30)));
        $before = now()->subDays($days);
        $deleted = 0;

        WatchMatchSession::query()->where('created_at', '<', $before)->select('id')->orderBy('id')->chunkById(500, function ($sessions) use (&$deleted) {
            $ids = $sessions->pluck('id')->all();
            DB::transaction(function () use ($ids, &$deleted) {
                WatchPositionSample::query()->whereIn('session_id', $ids)->delete();
                WatchMatchEvent::query()->whereIn('session_id', $ids)->delete();
                $deleted += WatchMatchSession::query()->whereIn('id', $ids)->delete();
            });
        });

        $this->info("Sesiones Watch eliminadas: {$deleted} (retención: {$days} días).");
        return self::SUCCESS;
    }
}
