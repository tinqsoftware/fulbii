<?php

namespace App\Services;

use App\Models\User;
use Carbon\Carbon;
use Illuminate\Support\Collection;

class PlayerRankingService
{
    public function __construct(private readonly CombinedSkillRatingService $ratings)
    {
    }

    /** @return array{tabs:array<int,array{key:string,label:string}>,items:array<int,array<string,mixed>>} */
    public function leaderboard(?string $band = null, ?int $viewerId = null): array
    {
        $users = User::query()->select(['id', 'nick', 'name', 'fec_nac'])->get();
        $tabs = $this->bandsFor($users);
        $filtered = $band === null || $band === 'total'
            ? $users
            : $users->filter(fn (User $user) => $this->ageBand($user) === $band)->values();
        $scores = $this->ratings->averagesByUserIds($filtered->pluck('id'));
        $items = $filtered->map(function (User $user) use ($scores, $viewerId) {
            $summary = $scores->has($user->id)
                ? $this->ratings->deriveSummary($scores->get($user->id))
                : null;
            return [
                'user_id' => (int) $user->id,
                'nick' => (string) ($user->nick ?: $user->name ?: 'Jugador'),
                'score' => $summary['stars'] ?? null,
                'is_me' => (int) $user->id === $viewerId,
            ];
        })->sort(function (array $left, array $right) {
            if ($left['score'] === null && $right['score'] !== null) return 1;
            if ($left['score'] !== null && $right['score'] === null) return -1;
            if ($left['score'] !== null && $right['score'] !== null && $left['score'] !== $right['score']) {
                return $right['score'] <=> $left['score'];
            }
            return strcasecmp($left['nick'], $right['nick']);
        })->values()->map(function (array $item, int $index) {
            unset($item['user_id']);
            return ['position' => $index + 1, ...$item];
        })->all();

        return ['tabs' => $tabs, 'items' => $items];
    }

    /** @return array{total:?int,age:?int,age_band:?string,age_band_label:?string} */
    public function summaryForUser(User $user): array
    {
        $total = $this->leaderboard('total', (int) $user->id)['items'];
        $band = $this->ageBand($user);
        $age = $band ? $this->leaderboard($band, (int) $user->id)['items'] : [];
        $find = fn (array $items) => collect($items)->firstWhere('is_me', true)['position'] ?? null;
        return [
            'total' => $find($total),
            'age' => $find($age),
            'age_band' => $band,
            'age_band_label' => $band ? $this->bandLabel($band) : null,
        ];
    }

    /** @param Collection<int,User> $users */
    private function bandsFor(Collection $users): array
    {
        return $users->map(fn (User $user) => $this->ageBand($user))
            ->filter()->unique()->sortBy(fn (string $band) => (int) explode('-', $band)[0])
            ->map(fn (string $band) => ['key' => $band, 'label' => $this->bandLabel($band)])
            ->values()->all();
    }

    private function ageBand(User $user): ?string
    {
        if (!$user->fec_nac) return null;
        $age = min(100, max(0, Carbon::parse($user->fec_nac)->age));
        $start = $age === 0 ? 0 : intdiv($age - 1, 5) * 5 + 1;
        $end = $start === 0 ? 5 : min(100, $start + 4);
        return "$start-$end";
    }

    private function bandLabel(string $band): string
    {
        [$start, $end] = explode('-', $band);
        return "$start–$end años";
    }
}
