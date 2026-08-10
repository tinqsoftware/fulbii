<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\GroupPichangaNotificationBatch;
use App\Services\AdminAccessService;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\Schema;

class AdminMetricsController extends Controller
{
    public function __construct(private readonly AdminAccessService $adminAccess)
    {
    }

    public function growth(Request $request)
    {
        $auth = $request->user() ?? abort(401);
        $this->adminAccess->ensureBackoffice($auth);

        abort_unless(Schema::hasTable('product_events'), 422, 'La tabla product_events no existe. Ejecuta el SQL incremental.');

        $data = $request->validate([
            'from' => ['nullable', 'date'],
            'to' => ['nullable', 'date'],
        ]);

        $from = !empty($data['from']) ? now()->parse($data['from'])->startOfDay() : now()->copy()->subDays(29)->startOfDay();
        $to = !empty($data['to']) ? now()->parse($data['to'])->endOfDay() : now()->endOfDay();
        abort_if($from->gt($to), 422, 'Rango de fechas inválido.');

        $rows = DB::table('product_events')
            ->selectRaw('DATE(happened_at) as day, event_name, COUNT(*) as total')
            ->whereBetween('happened_at', [$from, $to])
            ->groupByRaw('DATE(happened_at), event_name')
            ->orderBy('day')
            ->get();

        $daily = [];
        foreach ($rows as $row) {
            $day = (string) $row->day;
            if (!isset($daily[$day])) {
                $daily[$day] = [
                    'day' => $day,
                    'club_join_request_created' => 0,
                    'club_join_request_cancelled' => 0,
                    'club_join_request_accepted' => 0,
                    'club_join_request_rejected' => 0,
                    'pichanga_created' => 0,
                    'pichanga_confirmed' => 0,
                    'pichanga_withdrawn' => 0,
                    'pichanga_renotify_sent' => 0,
                    'pichanga_auto_48h_sent' => 0,
                    'pichanga_auto_24h_sent' => 0,
                ];
            }
            $eventName = (string) $row->event_name;
            if (array_key_exists($eventName, $daily[$day])) {
                $daily[$day][$eventName] = (int) $row->total;
            }
        }

        ksort($daily);
        $dailyItems = array_values($daily);

        $totals = [
            'join_requests' => 0,
            'join_accepted' => 0,
            'join_rejected' => 0,
            'join_cancelled' => 0,
            'pichangas_created' => 0,
            'confirmations' => 0,
            'withdrawals' => 0,
            'renotify_sent' => 0,
            'auto_48h_sent' => 0,
            'auto_24h_sent' => 0,
        ];

        foreach ($dailyItems as $item) {
            $totals['join_requests'] += (int) $item['club_join_request_created'];
            $totals['join_accepted'] += (int) $item['club_join_request_accepted'];
            $totals['join_rejected'] += (int) $item['club_join_request_rejected'];
            $totals['join_cancelled'] += (int) $item['club_join_request_cancelled'];
            $totals['pichangas_created'] += (int) $item['pichanga_created'];
            $totals['confirmations'] += (int) $item['pichanga_confirmed'];
            $totals['withdrawals'] += (int) $item['pichanga_withdrawn'];
            $totals['renotify_sent'] += (int) $item['pichanga_renotify_sent'];
            $totals['auto_48h_sent'] += (int) $item['pichanga_auto_48h_sent'];
            $totals['auto_24h_sent'] += (int) $item['pichanga_auto_24h_sent'];
        }

        $fillProxyDenominator = max(1, $totals['pichangas_created']);
        $totals['avg_confirmations_per_pichanga'] = round($totals['confirmations'] / $fillProxyDenominator, 2);

        return response()->json([
            'range' => [
                'from' => $from->toDateString(),
                'to' => $to->toDateString(),
            ],
            'totals' => $totals,
            'daily' => $dailyItems,
        ]);
    }

    public function releaseReadiness(Request $request)
    {
        $auth = $request->user() ?? abort(401);
        $this->adminAccess->ensureBackoffice($auth);

        $queueConnection = (string) config('queue.default', 'sync');
        $jobsPending = 0;
        if (Schema::hasTable('jobs')) {
            $jobsPending = (int) DB::table('jobs')->count();
        }

        $failedJobsCount = 0;
        if (Schema::hasTable('failed_jobs')) {
            $failedJobsCount = (int) DB::table('failed_jobs')->count();
        }

        $lastAutoWaveAt = null;
        if (Schema::hasTable('group_pichanga_notification_batches')) {
            $lastAutoWaveAt = GroupPichangaNotificationBatch::query()
                ->whereIn('batch_type', ['auto_48h', 'auto_24h'])
                ->max('created_at');
        }

        $commands = Artisan::all();
        $autoReminderCommandAvailable = array_key_exists('pichangas:auto-reminders', $commands);

        $pushDriver = (string) config('push.driver', 'log');
        $appLinkBaseUrl = (string) config('services.app_links.base_url', '');
        $fcmV1Ready = $pushDriver !== 'fcm'
            || (
                trim((string) config('push.fcm_project_id', '')) !== ''
                && trim((string) config('push.fcm_service_account_path', '')) !== ''
            );

        $iosAppIds = array_filter((array) config('services.app_links.ios_app_ids', []));
        $androidPackageName = (string) config('services.app_links.android_package_name', '');
        $androidFingerprints = array_filter((array) config('services.app_links.android_sha256_cert_fingerprints', []));

        $wellKnownRoutesPresent = Route::has('well-known.aasa') && Route::has('well-known.assetlinks');
        $wellKnownEndpointsOk = $wellKnownRoutesPresent
            && !empty($iosAppIds)
            && $androidPackageName !== ''
            && !empty($androidFingerprints);

        $push = [
            'active_devices' => 0,
            'inactive_devices' => 0,
            'dispatches_last_24h' => ['sent' => 0, 'failed' => 0, 'queued' => 0],
            'last_error' => null,
        ];
        if (Schema::hasTable('user_devices')) {
            $push['active_devices'] = (int) DB::table('user_devices')->where('is_active', true)->count();
            $push['inactive_devices'] = (int) DB::table('user_devices')->where('is_active', false)->count();
        }
        if (Schema::hasTable('push_dispatch_logs')) {
            $rows = DB::table('push_dispatch_logs')->where('created_at', '>=', now()->subDay())
                ->selectRaw('status, COUNT(*) as total')->groupBy('status')->get();
            foreach ($rows as $row) {
                $push['dispatches_last_24h'][(string) $row->status] = (int) $row->total;
            }
            $push['last_error'] = DB::table('push_dispatch_logs')->whereNotNull('error_message')
                ->orderByDesc('id')->value('error_message');
            $push['recent_deliveries'] = DB::table('push_dispatch_logs as logs')
                ->join('push_notifications as notifications', 'notifications.id', '=', 'logs.push_notification_id')
                ->select('notifications.user_id', 'logs.status', 'logs.provider', 'logs.created_at')
                ->orderByDesc('logs.id')->limit(10)->get()->map(fn ($row) => (array) $row)->all();
        }

        $operations = [
            'groups_without_admin' => 0,
            'challenges_needing_coordinator' => 0,
            'upcoming_pichangas_without_confirmations' => 0,
            'waitlist_entries_waiting' => 0,
            'pending_reports' => Schema::hasTable('reports') ? (int) DB::table('reports')->where('status', 'pending')->count() : 0,
            'active_blocks' => Schema::hasTable('user_blocks') ? (int) DB::table('user_blocks')->count() : 0,
        ];
        if (Schema::hasTable('clubs') && Schema::hasTable('club_user')) {
            $clubs = DB::table('clubs as clubs');
            if (Schema::hasColumn('clubs', 'estado')) {
                $clubs->where('clubs.estado', 1);
            }
            $operations['groups_without_admin'] = (int) $clubs->whereNotExists(function ($query) {
                $query->selectRaw('1')->from('club_user as members')->whereColumn('members.club_id', 'clubs.id')
                    ->where('members.rol', 'admin');
                if (Schema::hasColumn('club_user', 'estado')) {
                    $query->where('members.estado', 1);
                }
            })->count();
        }
        if (Schema::hasTable('club_challenges')) {
            $operations['challenges_needing_coordinator'] = (int) DB::table('club_challenges')
                ->whereIn('status', ['pending', 'negotiating', 'configuring'])
                ->where(function ($query) {
                    $query->whereNull('coordinator_challenger_user_id')->orWhereNull('coordinator_challenged_user_id');
                })->count();
        }
        if (Schema::hasTable('group_pichangas') && Schema::hasTable('group_pichanga_participants')) {
            $operations['upcoming_pichangas_without_confirmations'] = (int) DB::table('group_pichangas as pichangas')
                ->whereIn('pichangas.status', ['published', 'confirmed'])->whereBetween('pichangas.starts_at', [now(), now()->addHours(48)])
                ->whereNotExists(function ($query) {
                    $query->selectRaw('1')->from('group_pichanga_participants as participants')
                        ->whereColumn('participants.pichanga_id', 'pichangas.id')->where('participants.status', 'confirmed');
                })->count();
        }
        if (Schema::hasTable('group_pichanga_waitlist')) {
            $operations['waitlist_entries_waiting'] = (int) DB::table('group_pichanga_waitlist')->where('status', 'waiting')->count();
        }

        return response()->json([
            'queue_connection' => $queueConnection,
            'jobs_pending' => $jobsPending,
            'failed_jobs_count' => $failedJobsCount,
            'auto_reminder_command_available' => $autoReminderCommandAvailable,
            'last_auto_wave_at' => $lastAutoWaveAt ? Carbon::parse($lastAutoWaveAt)->toISOString() : null,
            'product_events_enabled' => Schema::hasTable('product_events'),
            'push_driver' => $pushDriver,
            'fcm_v1_ready' => $fcmV1Ready,
            'app_link_base_url' => $appLinkBaseUrl,
            'well_known_endpoints_ok' => $wellKnownEndpointsOk,
            'push' => $push,
            'operations' => $operations,
        ]);
    }

}
