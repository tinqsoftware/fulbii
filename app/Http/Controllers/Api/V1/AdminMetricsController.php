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
        ]);
    }

}
