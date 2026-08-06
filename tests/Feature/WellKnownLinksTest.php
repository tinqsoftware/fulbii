<?php

namespace Tests\Feature;

use Tests\TestCase;

class WellKnownLinksTest extends TestCase
{
    public function test_well_known_endpoints_return_expected_payloads(): void
    {
        config()->set('services.app_links.ios_app_ids', ['H22GQQX4KT.com.fulbii.fulbiiApp']);
        config()->set('services.app_links.android_package_name', 'com.fulbii.fulbii_app');
        config()->set('services.app_links.android_sha256_cert_fingerprints', [
            'AA:BB:CC:DD:EE:FF',
        ]);

        $aasa = $this->get('/.well-known/apple-app-site-association');
        $aasa->assertOk();
        $aasa->assertJsonPath('applinks.details.0.appID', 'H22GQQX4KT.com.fulbii.fulbiiApp');
        $aasa->assertJsonPath('applinks.details.0.paths.0', '/join/*');
        $this->assertContains('/club/*', $aasa->json('applinks.details.0.paths'));

        $assetlinks = $this->get('/.well-known/assetlinks.json');
        $assetlinks->assertOk();
        $assetlinks->assertJsonPath('0.target.package_name', 'com.fulbii.fulbii_app');
        $assetlinks->assertJsonPath('0.target.sha256_cert_fingerprints.0', 'AA:BB:CC:DD:EE:FF');
    }
}
