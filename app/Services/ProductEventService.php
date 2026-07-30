<?php

namespace App\Services;

use App\Models\ProductEvent;
use Illuminate\Support\Facades\Schema;

class ProductEventService
{
    /**
     * @param array<string,mixed> $context
     */
    public function track(
        string $eventName,
        ?int $userId = null,
        ?int $clubId = null,
        ?int $pichangaId = null,
        array $context = [],
        string $source = 'api'
    ): void {
        if (!Schema::hasTable('product_events')) {
            return;
        }

        ProductEvent::create([
            'event_name' => $eventName,
            'user_id' => $userId,
            'club_id' => $clubId,
            'pichanga_id' => $pichangaId,
            'source' => $source,
            'metadata_json' => empty($context) ? null : $context,
            'happened_at' => now(),
        ]);
    }
}

