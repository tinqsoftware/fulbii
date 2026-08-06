<?php

namespace App\Services;

use App\Models\GroupPichanga;
use App\Models\GroupPichangaParticipant;
use Illuminate\Support\Facades\Schema;

class PichangaTeamAssignmentService
{
    /**
     * Assigns a confirmed participant to a real team and free slot.
     *
     * The caller must wrap this operation in a transaction. Confirmed rows for
     * the pichanga are locked so concurrent confirmations cannot claim the same
     * slot.
     *
     * @return array{team_code:string,team_slot:int}
     */
    public function assign(GroupPichanga $pichanga, GroupPichangaParticipant $participant, ?string $preferredTeamCode = null): array
    {
        if (!Schema::hasColumn('group_pichanga_participants', 'team_code')
            || !Schema::hasColumn('group_pichanga_participants', 'team_slot')) {
            return ['team_code' => '', 'team_slot' => 0];
        }

        $teamCodes = $this->allowedTeamCodes($this->teamCount($pichanga));
        $rows = GroupPichangaParticipant::query()
            ->where('pichanga_id', $pichanga->id)
            ->where('status', 'confirmed')
            ->lockForUpdate()
            ->get(['id', 'team_code', 'team_slot']);

        $counts = array_fill_keys($teamCodes, 0);
        $usedSlots = array_fill_keys($teamCodes, []);
        foreach ($rows as $row) {
            if ((int) $row->id === (int) $participant->id) {
                continue;
            }
            $code = strtoupper((string) $row->team_code);
            $slot = (int) $row->team_slot;
            if (!in_array($code, $teamCodes, true) || $slot < 1) {
                continue;
            }
            $counts[$code]++;
            $usedSlots[$code][$slot] = true;
        }

        $preferred = strtoupper((string) $preferredTeamCode);
        $teamCode = in_array($preferred, $teamCodes, true)
            ? $preferred
            : $this->leastLoadedTeamCode($teamCodes, $counts);
        $teamSlot = 1;
        while (isset($usedSlots[$teamCode][$teamSlot])) {
            $teamSlot++;
        }

        $participant->update([
            'team_code' => $teamCode,
            'team_slot' => $teamSlot,
        ]);

        return ['team_code' => $teamCode, 'team_slot' => $teamSlot];
    }

    /** @return array<int,string> */
    public function allowedTeamCodes(int $teamCount): array
    {
        return array_slice(['A', 'B', 'C', 'D'], 0, max(2, min(4, $teamCount)));
    }

    private function teamCount(GroupPichanga $pichanga): int
    {
        if (Schema::hasColumn('group_pichangas', 'team_count')) {
            $count = (int) ($pichanga->team_count ?? 0);
            if (in_array($count, [2, 3, 4], true)) {
                return $count;
            }
        }

        if (Schema::hasColumn('group_pichangas', 'match_format')) {
            return match ((string) ($pichanga->match_format ?? 'versus')) {
                'triangular' => 3,
                'cuadrangular' => 4,
                default => 2,
            };
        }

        return 2;
    }

    /** @param array<int,string> $teamCodes @param array<string,int> $counts */
    private function leastLoadedTeamCode(array $teamCodes, array $counts): string
    {
        $best = $teamCodes[0];
        foreach ($teamCodes as $code) {
            if ($counts[$code] < $counts[$best]) {
                $best = $code;
            }
        }

        return $best;
    }
}
