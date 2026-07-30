<?php

namespace App\Http\Controllers;

use Illuminate\Http\JsonResponse;

class WellKnownController extends Controller
{
    public function appleAppSiteAssociation(): JsonResponse
    {
        $appIds = (array) config('services.app_links.ios_app_ids', []);
        $paths = (array) config('services.app_links.paths', ['/join/*']);

        $details = collect($appIds)
            ->filter(fn ($appId) => is_string($appId) && trim($appId) !== '')
            ->values()
            ->map(fn ($appId) => [
                'appID' => trim((string) $appId),
                'paths' => array_values($paths),
            ])
            ->all();

        return response()->json([
            'applinks' => [
                'apps' => [],
                'details' => $details,
            ],
        ]);
    }

    public function assetLinks(): JsonResponse
    {
        $packageName = (string) config('services.app_links.android_package_name', '');
        $fingerprints = collect((array) config('services.app_links.android_sha256_cert_fingerprints', []))
            ->filter(fn ($value) => is_string($value) && trim($value) !== '')
            ->map(fn ($value) => strtoupper(trim($value)))
            ->values()
            ->all();

        if ($packageName === '' || empty($fingerprints)) {
            return response()->json([]);
        }

        return response()->json([
            [
                'relation' => ['delegate_permission/common.handle_all_urls'],
                'target' => [
                    'namespace' => 'android_app',
                    'package_name' => $packageName,
                    'sha256_cert_fingerprints' => $fingerprints,
                ],
            ],
        ]);
    }
}
