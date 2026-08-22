<?php

namespace App\Services;

use App\Models\Championship;
use App\Models\GroupPichanga;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class ChampionshipDeletionService
{
    public function delete(Championship $championship): void
    {
        DB::transaction(function () use ($championship): void {
            $championship = Championship::query()->lockForUpdate()->findOrFail($championship->id);

            if (Schema::hasTable('group_pichangas') && Schema::hasColumn('group_pichangas', 'championship_id')) {
                GroupPichanga::query()
                    ->where('championship_id', $championship->id)
                    ->get()
                    ->each(fn (GroupPichanga $pichanga) => $this->deletePichanga($pichanga));
            }

            $this->deleteChampionshipNotifications($championship->id);

            $championship->delete();
        });
    }

    private function deletePichanga(GroupPichanga $pichanga): void
    {
        $id = $pichanga->id;
        $postIds = Schema::hasTable('group_pichanga_posts')
            ? DB::table('group_pichanga_posts')->where('pichanga_id', $id)->pluck('id')->all()
            : [];
        $commentIds = Schema::hasTable('group_pichanga_comments')
            ? DB::table('group_pichanga_comments')->where('pichanga_id', $id)->pluck('id')->all()
            : [];

        // Reports and strikes do not have a foreign key to a pichanga, so
        // remove their contextual records explicitly before the content.
        if (Schema::hasTable('reports')) {
            $hasReportContext = Schema::hasColumn('reports', 'content_type')
                && Schema::hasColumn('reports', 'content_id');
            $reportIds = DB::table('reports')
                ->where(function ($query) use ($id, $postIds, $commentIds, $hasReportContext): void {
                    $query->where(function ($target) use ($id): void {
                        $target->where('target_type', 'group_pichanga')->where('target_id', $id);
                    });
                    if ($hasReportContext && ($postIds || $commentIds)) {
                        $query->orWhere(function ($content) use ($postIds, $commentIds): void {
                            if ($postIds) {
                                $content->where(function ($types) use ($postIds): void {
                                    $types->where('content_type', 'pichanga_post')->whereIn('content_id', $postIds);
                                });
                            }
                            if ($commentIds) {
                                $content->orWhere(function ($types) use ($commentIds): void {
                                    $types->where('content_type', 'pichanga_comment')->whereIn('content_id', $commentIds);
                                });
                            }
                        });
                    }
                })
                ->pluck('id')
                ->all();
            if ($reportIds) {
                $this->deleteRows('strikes', fn ($query) => $query->whereIn('report_id', $reportIds));
                $this->deleteRows('reports', fn ($query) => $query->whereIn('id', $reportIds));
            }
        }

        // Watch sessions/events are intentionally not FK-cascaded because
        // they can also represent simulated sessions.  Championship-linked
        // sessions are safe to remove with their pichanga.
        if (Schema::hasTable('watch_match_sessions')) {
            $sessionIds = DB::table('watch_match_sessions')
                ->where('group_pichanga_id', $id)->pluck('id')->all();
            if ($sessionIds) {
                $this->deleteRows('watch_match_events', fn ($query) => $query->whereIn('session_id', $sessionIds));
                $this->deleteRows('watch_position_samples', fn ($query) => $query->whereIn('session_id', $sessionIds));
                $this->deleteRows('watch_match_sessions', fn ($query) => $query->whereIn('id', $sessionIds));
            }
        }

        foreach ([
            'group_pichanga_comments',
            'group_pichanga_posts',
            'group_pichanga_ratings',
            'group_pichanga_participants',
            'group_pichanga_waitlist',
            'group_pichanga_external_requests',
            'group_pichanga_notification_batches',
        ] as $table) {
            $this->deleteRows($table, fn ($query) => $query->where('pichanga_id', $id));
        }

        $this->deleteRows('push_notifications', fn ($query) => $query->where('group_pichanga_id', $id));
        $pichanga->delete();
    }

    private function deleteRows(string $table, callable $where): void
    {
        if (!Schema::hasTable($table)) {
            return;
        }

        $query = DB::table($table);
        $where($query);
        $query->delete();
    }

    private function deleteChampionshipNotifications(int $championshipId): void
    {
        if (!Schema::hasTable('push_notifications')) {
            return;
        }

        $idsByKey = [
            'championship_id' => [$championshipId],
        ];
        foreach ([
            'championship_teams' => ['foreign' => 'championship_id', 'key' => 'championship_team_id'],
            'championship_matchdays' => ['foreign' => 'championship_id', 'key' => 'matchday_id'],
            'championship_matches' => ['foreign' => 'championship_id', 'key' => 'match_id'],
            'championship_team_invitations' => ['foreign' => 'championship_id', 'key' => 'invitation_id'],
        ] as $table => $config) {
            if (!Schema::hasTable($table)) {
                continue;
            }
            if (Schema::hasColumn($table, $config['foreign'])) {
                $idsByKey[$config['key']] = DB::table($table)
                    ->where($config['foreign'], $championshipId)
                    ->pluck('id')
                    ->all();
            }
        }

        $this->deleteRows('push_notifications', function ($query) use ($idsByKey): void {
            $query->where(function ($where) use ($idsByKey): void {
                foreach ($idsByKey as $key => $ids) {
                    foreach ($ids as $id) {
                        $where->orWhere('data_json', 'like', '%"' . $key . '":"' . (int) $id . '"%')
                            ->orWhere('data_json', 'like', '%"' . $key . '":' . (int) $id . '%');
                    }
                }
            });
        });
    }
}
