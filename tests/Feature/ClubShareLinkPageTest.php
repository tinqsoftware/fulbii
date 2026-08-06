<?php

namespace Tests\Feature;

use Tests\TestCase;

class ClubShareLinkPageTest extends TestCase
{
    public function test_club_share_page_contains_the_club_deep_link(): void
    {
        config()->set('services.app_links.base_url', 'https://fulbii.test');

        $response = $this->get('/club/123');

        $response->assertOk();
        $response->assertSee('fulbii://club/123', false);
        $response->assertSee('https://fulbii.test/club/123', false);
    }
}
