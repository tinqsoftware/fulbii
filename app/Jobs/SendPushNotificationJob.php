<?php

namespace App\Jobs;

use App\Models\PushDispatchLog;
use App\Models\PushNotification;
use App\Models\UserChatPresence;
use App\Models\UserDevice;
use App\Services\PushGatewayService;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Schema;

class SendPushNotificationJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public int $tries = 3;
    public array $backoff = [30, 120, 300];

    public function __construct(private readonly int $notificationId)
    {
        $this->onQueue('push');
    }

    public function handle(PushGatewayService $gateway): void
    {
        $notification = PushNotification::find($this->notificationId);
        if (!$notification) {
            return;
        }

        if ($this->shouldSuppressBecauseActiveChat($notification)) {
            PushDispatchLog::create([
                'push_notification_id' => $notification->id,
                'user_device_id' => null,
                'status' => 'failed',
                'provider' => (string) config('push.driver', 'log'),
                'error_message' => 'Suppressed: user active in challenge chat',
            ]);
            return;
        }

        $devices = UserDevice::query()
            ->where('user_id', $notification->user_id)
            ->where('is_active', true)
            ->get();

        if ($devices->isEmpty()) {
            PushDispatchLog::create([
                'push_notification_id' => $notification->id,
                'user_device_id' => null,
                'status' => 'failed',
                'provider' => (string) config('push.driver', 'log'),
                'error_message' => 'No active devices',
            ]);
            return;
        }

        foreach ($devices as $device) {
            $log = PushDispatchLog::create([
                'push_notification_id' => $notification->id,
                'user_device_id' => $device->id,
                'status' => 'queued',
                'provider' => (string) config('push.driver', 'log'),
            ]);

            $result = $gateway->send(
                $device,
                (string) $notification->title,
                (string) $notification->body,
                is_array($notification->data_json) ? $notification->data_json : []
            );

            $log->update([
                'status' => $result['ok'] ? 'sent' : 'failed',
                'provider' => $result['provider'],
                'provider_response' => $result['response'] ?: null,
                'error_message' => $result['error'],
                'sent_at' => now(),
            ]);
        }
    }

    private function shouldSuppressBecauseActiveChat(PushNotification $notification): bool
    {
        if ((string) $notification->type !== 'challenge_chat_message') {
            return false;
        }

        $data = is_array($notification->data_json) ? $notification->data_json : [];
        $challengeId = (int) ($data['challenge_id'] ?? 0);
        if ($challengeId <= 0) {
            return false;
        }
        if (!Schema::hasTable('user_chat_presence')) {
            return false;
        }

        return UserChatPresence::query()
            ->where('user_id', (int) $notification->user_id)
            ->where('challenge_id', $challengeId)
            ->where('is_active', true)
            ->where('last_heartbeat_at', '>=', now()->subSeconds(90))
            ->exists();
    }
}
