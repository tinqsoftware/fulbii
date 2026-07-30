<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;

class GeoController extends Controller
{
    public function suggestions(Request $request)
    {
        $data = $request->validate(['q' => ['required', 'string', 'min:3', 'max:160'], 'lat' => ['nullable', 'numeric', 'between:-90,90'], 'lng' => ['nullable', 'numeric', 'between:-180,180']]);
        return response()->json(['items' => $this->lookup('autocomplete', $data)]);
    }

    public function reverse(Request $request)
    {
        $data = $request->validate(['lat' => ['required', 'numeric', 'between:-90,90'], 'lng' => ['required', 'numeric', 'between:-180,180']]);
        $items = $this->lookup('reverse', $data);
        return response()->json(['item' => $items[0] ?? null]);
    }

    private function lookup(string $kind, array $data): array
    {
        $key = config('services.geoapify.key');
        abort_unless(is_string($key) && $key !== '', 503, 'La búsqueda de direcciones no está configurada.');
        $cacheKey = 'geoapify:' . $kind . ':' . sha1(json_encode($data));
        return Cache::remember($cacheKey, now()->addMinutes(10), function () use ($kind, $data, $key) {
            $query = ['apiKey' => $key, 'limit' => 6, 'filter' => 'countrycode:pe'];
            if ($kind === 'autocomplete') $query['text'] = $data['q'];
            else { $query['lat'] = $data['lat']; $query['lon'] = $data['lng']; }
            if (isset($data['lat'], $data['lng']) && $kind === 'autocomplete') $query['bias'] = 'proximity:' . $data['lng'] . ',' . $data['lat'];
            $response = Http::timeout(8)->get('https://api.geoapify.com/v1/geocode/' . $kind, $query);
            abort_unless($response->successful(), 503, 'No se pudo buscar la dirección.');
            return collect($response->json('features', []))->map(fn ($feature) => [
                'id' => data_get($feature, 'properties.place_id'),
                'address' => data_get($feature, 'properties.formatted'),
                'secondary' => data_get($feature, 'properties.district') ?: data_get($feature, 'properties.city'),
                'lat' => data_get($feature, 'properties.lat'),
                'lng' => data_get($feature, 'properties.lon'),
            ])->filter(fn ($item) => $item['address'] && is_numeric($item['lat']) && is_numeric($item['lng']))->values()->all();
        });
    }
}
