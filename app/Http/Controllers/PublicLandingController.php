<?php

namespace App\Http\Controllers;

use Illuminate\Contracts\View\View;
use Illuminate\Http\JsonResponse;

class PublicLandingController extends Controller
{
    public function landing(): View
    {
        return view('public.landing', $this->storeLinks());
    }

    public function join(string $joinCode): View
    {
        $code = strtoupper(trim($joinCode));
        abort_if($code === '', 404);

        return view('public.app-link', array_merge($this->storeLinks(), [
            'title' => 'Únete a un grupo en Fulbii',
            'eyebrow' => 'Invitación a grupo',
            'description' => 'Abre Fulbii para revisar la invitación y solicitar tu ingreso al grupo.',
            'appLink' => "fulbii://join/{$code}",
            'canonicalPath' => "/join/{$code}",
        ]));
    }

    public function club(int $clubId): View
    {
        abort_if($clubId <= 0, 404);

        return view('public.app-link', array_merge($this->storeLinks(), [
            'title' => 'Este grupo te espera en Fulbii',
            'eyebrow' => 'Grupo Fulbii',
            'description' => 'Abre la app para ver la actividad del grupo, sus pichangas y miembros.',
            'appLink' => "fulbii://club/{$clubId}",
            'canonicalPath' => "/club/{$clubId}",
        ]));
    }

    public function pichanga(int $pichangaId): View
    {
        abort_if($pichangaId <= 0, 404);

        return view('public.app-link', array_merge($this->storeLinks(), [
            'title' => 'Una pichanga te espera en Fulbii',
            'eyebrow' => 'Pichanga Fulbii',
            'description' => 'Abre la app para confirmar, conversar con el grupo y ver todos los detalles.',
            'appLink' => "fulbii://pichanga/{$pichangaId}",
            'canonicalPath' => "/pichanga/{$pichangaId}",
        ]));
    }

    public function appOnly(): View
    {
        return view('public.app-link', array_merge($this->storeLinks(), [
            'title' => 'Este flujo vive en la app Fulbii',
            'eyebrow' => 'Experiencia móvil',
            'description' => 'Para mantener tus permisos, datos y notificaciones sincronizados, continúa desde la app Fulbii.',
            'appLink' => 'fulbii://pichangas',
            'canonicalPath' => '/',
        ]));
    }

    public function unavailable(): JsonResponse
    {
        return response()->json([
            'message' => 'Este flujo web fue retirado. Continúa desde la app Fulbii.',
        ], 410);
    }

    /** @return array{baseUrl:string,androidStoreUrl:string,iosStoreUrl:string} */
    private function storeLinks(): array
    {
        return [
            'baseUrl' => rtrim((string) config('services.app_links.base_url', config('app.url')), '/'),
            'androidStoreUrl' => trim((string) config('services.app_links.android_store_url', '')),
            'iosStoreUrl' => trim((string) config('services.app_links.ios_store_url', '')),
        ];
    }
}
