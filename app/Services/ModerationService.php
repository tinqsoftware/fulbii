<?php

namespace App\Services;

use App\Models\Strike;
use App\Models\User;
use Carbon\Carbon;

class ModerationService
{
    public function issueStrike(
        User $targetUser,
        User $assignedBy,
        string $reasonCode,
        ?string $description = null,
        ?int $reportId = null,
        ?int $expiresDays = null
    ): Strike {
        $strike = Strike::create([
            'user_id' => $targetUser->id,
            'report_id' => $reportId,
            'assigned_by_user_id' => $assignedBy->id,
            'reason_code' => $reasonCode,
            'description' => $description,
            'status' => 'active',
            'expires_at' => $expiresDays ? now()->addDays($expiresDays) : null,
        ]);

        $this->recalculateSuspension($targetUser);

        return $strike;
    }

    public function revokeStrike(Strike $strike, User $revokedBy, ?string $note = null): void
    {
        if ($strike->status === 'revoked') {
            return;
        }

        $strike->update([
            'status' => 'revoked',
            'revoked_by_user_id' => $revokedBy->id,
            'revoked_at' => now(),
            'revoked_note' => $note,
        ]);

        $targetUser = User::find($strike->user_id);
        if ($targetUser) {
            $this->recalculateSuspension($targetUser);
        }
    }

    public function recalculateSuspension(User $user): void
    {
        $activeCount = Strike::query()
            ->where('user_id', $user->id)
            ->where('status', 'active')
            ->where(function ($q) {
                $q->whereNull('expires_at')->orWhere('expires_at', '>', now());
            })
            ->count();

        if ($activeCount >= 3) {
            $newUntil = now()->addDays((int) config('moderation.auto_suspend_days', 30));
            $until = $user->suspended_until instanceof Carbon ? $user->suspended_until : null;
            if (!$until || $until->lt($newUntil)) {
                $user->suspended_until = $newUntil;
            }
            $user->suspension_reason = 'auto_3_strikes';
            $user->save();
            return;
        }

        if ($user->suspension_reason === 'auto_3_strikes') {
            $user->suspended_until = null;
            $user->suspension_reason = null;
            $user->save();
        }
    }
}
