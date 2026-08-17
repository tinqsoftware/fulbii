<?php

namespace Database\Seeders;

/**
 * Explicit entry point for disposable development data. Never run this class
 * in production. DatabaseSeeder itself is guarded as an additional safeguard.
 */
class DemoDataSeeder extends DatabaseSeeder
{
    public function run(): void
    {
        $this->runDemo();
    }
}
