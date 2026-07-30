<?php

return [
    'driver' => env('PUSH_DRIVER', 'log'), // log|fcm

    // FCM HTTP v1 configuration (recommended)
    'fcm_project_id' => env('FCM_PROJECT_ID', ''),
    'fcm_service_account_path' => env('FCM_SERVICE_ACCOUNT_PATH', ''),
    'fcm_scope' => env('FCM_SCOPE', 'https://www.googleapis.com/auth/firebase.messaging'),
    'fcm_token_uri' => env('FCM_TOKEN_URI', 'https://oauth2.googleapis.com/token'),

    // Deprecated: legacy FCM HTTP API key. Kept for backward-compat visibility.
    'fcm_server_key' => env('FCM_SERVER_KEY', ''),
];
