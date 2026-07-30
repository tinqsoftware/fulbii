<?php

return [
    'auto_suspend_days' => (int) env('MODERATION_AUTO_SUSPEND_DAYS', 30),
    'staff_blocked_revoke_reason_codes' => array_values(array_filter(array_map(
        'trim',
        explode(',', (string) env('MODERATION_STAFF_BLOCKED_REVOKE_REASON_CODES', 'auto_3_strikes,safety_critical,platform_abuse'))
    ))),
];
