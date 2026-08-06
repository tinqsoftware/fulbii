<?php

namespace App\Console\Commands;

use App\Models\GroupPichanga;
use App\Models\GroupPichangaParticipant;
use App\Services\PichangaTeamAssignmentService;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class RepairPichangaTeamAssignmentsCommand extends Command
{
    protected $signature = 'pichangas:repair-team-assignments {--force : Confirma la asignación persistente de participantes históricos}';

    protected $description = 'Asigna equipo y slot a participaciones confirmadas históricas que no los tienen.';

    public function __construct(private readonly PichangaTeamAssignmentService $teamAssignments)
    {
        parent::__construct();
    }

    public function handle(): int
    {
        if (!$this->option('force')) {
            $this->error('Este comando asigna equipos a confirmaciones históricas. Úsalo con --force.');
            return self::FAILURE;
        }

        if (!Schema::hasTable('group_pichanga_participants')
            || !Schema::hasColumn('group_pichanga_participants', 'team_code')
            || !Schema::hasColumn('group_pichanga_participants', 'team_slot')) {
            $this->error('La tabla de participantes no tiene columnas de equipo disponibles.');
            return self::FAILURE;
        }

        $pichangaIds = GroupPichangaParticipant::query()
            ->where('status', 'confirmed')
            ->where(fn ($query) => $query->whereNull('team_code')->orWhereNull('team_slot'))
            ->pluck('pichanga_id')
            ->unique()
            ->values();
        $repaired = 0;

        foreach ($pichangaIds as $pichangaId) {
            $repaired += DB::transaction(function () use ($pichangaId) {
                $pichanga = GroupPichanga::query()->lockForUpdate()->find($pichangaId);
                if (!$pichanga) {
                    return 0;
                }

                $participants = GroupPichangaParticipant::query()
                    ->where('pichanga_id', $pichanga->id)
                    ->where('status', 'confirmed')
                    ->where(fn ($query) => $query->whereNull('team_code')->orWhereNull('team_slot'))
                    ->orderByRaw('COALESCE(confirmed_at, created_at) asc')
                    ->orderBy('id')
                    ->lockForUpdate()
                    ->get();

                foreach ($participants as $participant) {
                    $this->teamAssignments->assign($pichanga, $participant);
                }

                return $participants->count();
            });
        }

        $this->info("Reparación completada: {$repaired} participantes asignados.");
        return self::SUCCESS;
    }
}
