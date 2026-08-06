<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class ResetSkillRatingsCommand extends Command
{
    protected $signature = 'ratings:reset {--force : Confirma la eliminación irreversible de calificaciones}';

    protected $description = 'Elimina calificaciones, calificaciones de pichangas e historial para reiniciar la escala de estrellas 0–5.';

    public function handle(): int
    {
        if (!$this->option('force')) {
            $this->error('Este comando elimina calificaciones de forma irreversible. Úsalo con --force.');
            return self::FAILURE;
        }

        $tables = ['historial_calificacion', 'group_pichanga_ratings', 'calificaciones'];
        $deleted = [];

        DB::transaction(function () use ($tables, &$deleted) {
            foreach ($tables as $table) {
                if (!Schema::hasTable($table)) {
                    $deleted[$table] = 0;
                    continue;
                }
                $deleted[$table] = DB::table($table)->delete();
            }
        });

        foreach ($deleted as $table => $count) {
            $this->line("{$table}: {$count} registros eliminados.");
        }
        $this->info('Reset de calificaciones completado. La escala activa es 0.0–5.0.');

        return self::SUCCESS;
    }
}
