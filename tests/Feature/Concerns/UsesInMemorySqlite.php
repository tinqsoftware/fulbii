<?php

namespace Tests\Feature\Concerns;

use Illuminate\Support\Facades\Config;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

trait UsesInMemorySqlite
{
    protected function bootInMemorySqlite(): void
    {
        Config::set('database.default', 'sqlite');
        Config::set('database.connections.sqlite.database', ':memory:');
        DB::purge('sqlite');
        DB::reconnect('sqlite');
        Schema::enableForeignKeyConstraints();
    }
}

