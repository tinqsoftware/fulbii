<?php

namespace App\Services;

use Illuminate\Support\Facades\Storage;

class PublicMediaService
{
    /**
     * Delete only a managed public-storage asset. External URLs and unexpected
     * paths are intentionally ignored to prevent path traversal/deletion bugs.
     *
     * @param array<int,string> $allowedPrefixes
     */
    public function deleteManaged(?string $value, array $allowedPrefixes): bool
    {
        if (!is_string($value) || trim($value) === '') {
            return false;
        }

        $path = parse_url($value, PHP_URL_PATH);
        $path = is_string($path) ? ltrim($path, '/') : ltrim($value, '/');
        $path = preg_replace('#^storage/#', '', $path) ?: '';
        if ($path === '' || str_contains($path, '..')) {
            return false;
        }

        $allowed = collect($allowedPrefixes)->contains(fn (string $prefix) => str_starts_with($path, rtrim($prefix, '/') . '/'));
        if (!$allowed) {
            return false;
        }

        return Storage::disk('public')->delete($path);
    }
}
