<?php

namespace Tests\Feature;

use Tests\TestCase;

class PublicLandingRoutesTest extends TestCase
{
    public function test_public_home_is_the_fulbii_landing_page(): void
    {
        $this->get('/')
            ->assertOk()
            ->assertSee('Juega más.')
            ->assertSee('Abrir Fulbii', false)
            ->assertDontSee('Estamos en <span class="text-current">construcción.', false);
    }

    public function test_legacy_player_pages_are_interstitials_and_not_legacy_workflows(): void
    {
        $this->get('/clubs')
            ->assertOk()
            ->assertSee('Este flujo vive en la app Fulbii')
            ->assertSee('fulbii://pichangas', false);

        $this->post('/clubs/1/calificar', [])
            ->assertGone()
            ->assertJsonPath('message', 'Este flujo web fue retirado. Continúa desde la app Fulbii.');
    }

    public function test_join_link_uses_the_shared_fulbii_link_page(): void
    {
        config()->set('services.app_links.base_url', 'https://fulbii.test');

        $this->get('/join/AB12')
            ->assertOk()
            ->assertSee('fulbii://join/AB12', false)
            ->assertSee('https://fulbii.test/join/AB12', false)
            ->assertSee('Abrir Fulbii');
    }

    public function test_backoffice_login_does_not_link_to_disabled_registration(): void
    {
        $this->get('/login')
            ->assertOk()
            ->assertSee('El acceso al backoffice es solo para cuentas autorizadas.')
            ->assertDontSee('Crear cuenta');
    }
}
