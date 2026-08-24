<?php

return [

    /*
    |--------------------------------------------------------------------------
    | Third Party Services
    |--------------------------------------------------------------------------
    |
    | This file is for storing the credentials for third party services such
    | as Mailgun, Postmark, AWS and more. This file provides the de facto
    | location for this type of information, allowing packages to have
    | a conventional file to locate the various service credentials.
    |
    */

    'mailgun' => [
        'domain' => env('MAILGUN_DOMAIN'),
        'secret' => env('MAILGUN_SECRET'),
        'endpoint' => env('MAILGUN_ENDPOINT', 'api.mailgun.net'),
        'scheme' => 'https',
    ],

    'postmark' => [
        'token' => env('POSTMARK_TOKEN'),
    ],

    'ses' => [
        'key' => env('AWS_ACCESS_KEY_ID'),
        'secret' => env('AWS_SECRET_ACCESS_KEY'),
        'region' => env('AWS_DEFAULT_REGION', 'us-east-1'),
    ],

    'google' => [
        'client_id' => env('GOOGLE_CLIENT_ID'),
        // Keep the legacy single value for existing deployments while
        // allowing a migration window where old iOS builds and the new
        // Android Firebase project are both accepted.
        'client_ids' => array_values(array_filter(array_map(
            'trim',
            explode(',', (string) env('GOOGLE_CLIENT_IDS', env('GOOGLE_CLIENT_ID', '')))
        ))),
    ],

    'apple' => [
        'client_id' => env('APPLE_CLIENT_ID'),
    ],

    'geoapify' => [
        'key' => env('GEOAPIFY_API_KEY'),
    ],

    'app_links' => [
        'base_url' => env('APP_LINK_BASE_URL', env('APP_URL', 'http://fulbii.test')),
        'android_store_url' => env('ANDROID_STORE_URL', ''),
        'ios_store_url' => env('IOS_STORE_URL', ''),
        'ios_app_ids' => array_values(array_filter(array_map(
            'trim',
            explode(',', (string) env('APP_LINK_IOS_APP_IDS', env('APP_LINK_IOS_APP_ID', '')))
        ))),
        'android_package_name' => env('APP_LINK_ANDROID_PACKAGE_NAME', 'com.fulbii.fulbii_app'),
        'android_sha256_cert_fingerprints' => array_values(array_filter(array_map(
            'trim',
            explode(',', (string) env('APP_LINK_ANDROID_SHA256_CERT_FINGERPRINTS', ''))
        ))),
        'paths' => ['/join/*', '/pichanga/*', '/club/*'],
    ],

];
