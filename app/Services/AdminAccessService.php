<?php

namespace App\Services;

use App\Models\Strike;
use App\Models\User;

class AdminAccessService
{
    public function ensureBackoffice(?User $user): void
    {
        abort_unless($user && $user->canAccessBackoffice(), 403);
    }

    public function ensureSuper(?User $user): void
    {
        abort_unless($user && $user->canPerformCriticalAdminActions(), 403);
    }

    public function ensureNotSelfAction(User $actor, int $targetUserId, string $action): void
    {
        abort_if($actor->id === $targetUserId, 422, "No puedes ejecutar {$action} sobre tu propia cuenta.");
    }

    public function ensureCanIssueStrike(User $actor, User $target): void
    {
        if ($actor->canPerformCriticalAdminActions()) {
            return;
        }

        abort_if($target->canAccessBackoffice(), 403, 'Staff no puede aplicar strike a cuentas backoffice.');
    }

    public function ensureCanRevokeStrike(User $actor, Strike $strike): void
    {
        if ($actor->canPerformCriticalAdminActions()) {
            return;
        }

        abort_if($this->isStaffCriticalBlock($actor, $strike), 403, 'Staff no puede revocar este strike crítico.');
    }

    public function isStaffCriticalBlock(User $actor, Strike $strike): bool
    {
        if ($actor->canPerformCriticalAdminActions()) {
            return false;
        }

        $target = $strike->relationLoaded('user')
            ? $strike->user
            : User::find((int) $strike->user_id);

        $targetIsBackoffice = $target?->canAccessBackoffice() ?? false;
        $reason = mb_strtolower((string) $strike->reason_code);
        $criticalReasons = array_map(
            static fn ($item) => mb_strtolower(trim((string) $item)),
            (array) config('moderation.staff_blocked_revoke_reason_codes', ['auto_3_strikes', 'safety_critical', 'platform_abuse'])
        );

        $isCriticalReason = in_array($reason, $criticalReasons, true);

        return $targetIsBackoffice || (empty($strike->report_id) && $isCriticalReason);
    }
}
