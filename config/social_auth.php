<?php

return [
    /*
    |--------------------------------------------------------------------------
    | Trusted Mode
    |--------------------------------------------------------------------------
    |
    | true  => local/dev mode. Backend trusts provider_uid/email from app.
    | false => backend tries provider token validation.
    |
    */
    'trusted_mode' => (bool) env('SOCIAL_AUTH_TRUSTED_MODE', false),

    // Native Apple sign-in sends a SHA-256 nonce. Keep this enabled in every
    // environment that handles real identities.
    'apple_require_nonce' => (bool) env('APPLE_AUTH_REQUIRE_NONCE', true),
    'apple_audiences' => array_values(array_filter(array_map('trim', explode(',', (string) env('APPLE_AUTH_AUDIENCES', ''))))),
    'clock_skew_seconds' => (int) env('SOCIAL_AUTH_CLOCK_SKEW_SECONDS', 300),
];
