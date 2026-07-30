<?php

namespace App\Models;

use Carbon\CarbonInterface;
use Illuminate\Database\Eloquent\Model;

class UserGroupNotificationPref extends Model
{
    public const MODE_ALWAYS_ON = 'always_on';
    public const MODE_MUTE_24H = 'mute_24h';
    public const MODE_MUTE_1W = 'mute_1w';
    public const MODE_MUTE_FOREVER = 'mute_forever';

    protected $table = 'user_group_notification_prefs';

    protected $fillable = [
        'user_id',
        'club_id',
        'mode',
        'muted_until',
        'updated_by_user',
    ];

    protected $casts = [
        'muted_until' => 'datetime',
        'updated_by_user' => 'boolean',
    ];

    public static function validModes(): array
    {
        return [
            self::MODE_ALWAYS_ON,
            self::MODE_MUTE_24H,
            self::MODE_MUTE_1W,
            self::MODE_MUTE_FOREVER,
        ];
    }

    public static function mutedUntilForMode(string $mode, ?CarbonInterface $base = null): ?CarbonInterface
    {
        $now = $base ?: now();

        return match ($mode) {
            self::MODE_ALWAYS_ON => null,
            self::MODE_MUTE_24H => $now->copy()->addDay(),
            self::MODE_MUTE_1W => $now->copy()->addWeek(),
            self::MODE_MUTE_FOREVER => null,
            default => null,
        };
    }

    public function isMuted(?CarbonInterface $at = null): bool
    {
        $now = $at ?: now();

        if ($this->mode === self::MODE_ALWAYS_ON) {
            return false;
        }

        if ($this->mode === self::MODE_MUTE_FOREVER) {
            return true;
        }

        if (!$this->muted_until) {
            return false;
        }

        return $this->muted_until->greaterThanOrEqualTo($now);
    }

    public function user()
    {
        return $this->belongsTo(User::class, 'user_id');
    }

    public function club()
    {
        return $this->belongsTo(Club::class, 'club_id');
    }
}
