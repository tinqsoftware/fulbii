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
    'trusted_mode' => (bool) env('SOCIAL_AUTH_TRUSTED_MODE', true),
];
