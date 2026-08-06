<?php

namespace Tests\Feature;

use Tests\TestCase;

class PichangaShareLinkPageTest extends TestCase
{
    public function test_pichanga_share_page_contains_deep_link(): void
    {
        config()->set('services.app_links.base_url', 'https://fulbii.test');

        $response = $this->get('/pichanga/123');

        $response->assertOk();
        $response->assertSee('fulbii://pichanga/123', false);
        $response->assertSee('https://fulbii.test/pichanga/123', false);
    }
}
