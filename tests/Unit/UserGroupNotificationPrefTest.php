<?php

namespace Tests\Unit;

use App\Models\UserGroupNotificationPref;
use Carbon\Carbon;
use Tests\TestCase;

class UserGroupNotificationPrefTest extends TestCase
{
    public function test_muted_until_for_timeboxed_modes(): void
    {
        $base = Carbon::parse('2026-03-19 10:00:00');

        $until24h = UserGroupNotificationPref::mutedUntilForMode(UserGroupNotificationPref::MODE_MUTE_24H, $base);
        $until1w = UserGroupNotificationPref::mutedUntilForMode(UserGroupNotificationPref::MODE_MUTE_1W, $base);

        $this->assertSame('2026-03-20 10:00:00', $until24h?->format('Y-m-d H:i:s'));
        $this->assertSame('2026-03-26 10:00:00', $until1w?->format('Y-m-d H:i:s'));
    }

    public function test_is_muted_true_for_forever(): void
    {
        $pref = new UserGroupNotificationPref([
            'mode' => UserGroupNotificationPref::MODE_MUTE_FOREVER,
        ]);

        $this->assertTrue($pref->isMuted(Carbon::parse('2026-03-19 10:00:00')));
    }

    public function test_is_muted_false_for_always_on(): void
    {
        $pref = new UserGroupNotificationPref([
            'mode' => UserGroupNotificationPref::MODE_ALWAYS_ON,
        ]);

        $this->assertFalse($pref->isMuted(Carbon::parse('2026-03-19 10:00:00')));
    }

    public function test_is_muted_respects_mute_window(): void
    {
        $pref = new UserGroupNotificationPref([
            'mode' => UserGroupNotificationPref::MODE_MUTE_24H,
            'muted_until' => Carbon::parse('2026-03-20 10:00:00'),
        ]);

        $this->assertTrue($pref->isMuted(Carbon::parse('2026-03-19 10:00:00')));
        $this->assertFalse($pref->isMuted(Carbon::parse('2026-03-20 10:00:01')));
    }
}
