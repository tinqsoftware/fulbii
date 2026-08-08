import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/profile_repository.dart';

final playerRankingsProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>(
      (ref, band) => ref.watch(profileRepositoryProvider).rankings(band: band),
    );

class PlayerRankingsScreen extends ConsumerStatefulWidget {
  const PlayerRankingsScreen({super.key});

  @override
  ConsumerState<PlayerRankingsScreen> createState() =>
      _PlayerRankingsScreenState();
}

class _PlayerRankingsScreenState extends ConsumerState<PlayerRankingsScreen> {
  String _band = 'total';

  @override
  Widget build(BuildContext context) {
    final ranking = ref.watch(playerRankingsProvider(_band));
    return Scaffold(
      appBar: AppBar(title: const Text('Ranking de jugadores')),
      body: ranking.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text('No se pudo cargar el ranking: $error')),
        data: (data) {
          final tabs = (data['tabs'] as List? ?? []).whereType<Map>().toList();
          final items = (data['items'] as List? ?? [])
              .whereType<Map>()
              .toList();
          final validBands = {
            'total',
            ...tabs.map((tab) => tab['key'].toString()),
          };
          if (!validBands.contains(_band)) _band = 'total';
          return Column(
            children: [
              SizedBox(
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  children: [
                    _RankingTab(
                      label: 'Total',
                      selected: _band == 'total',
                      onTap: () => setState(() => _band = 'total'),
                    ),
                    ...tabs.map(
                      (tab) => _RankingTab(
                        label: tab['label'].toString(),
                        selected: _band == tab['key'].toString(),
                        onTap: () =>
                            setState(() => _band = tab['key'].toString()),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 6),
                  itemBuilder: (_, index) {
                    final item = items[index];
                    final isMe = item['is_me'] == true;
                    final score = item['score'];
                    return ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      tileColor: isMe
                          ? Theme.of(context).colorScheme.primaryContainer
                          : null,
                      leading: Text(
                        '#${item['position']}',
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      title: Text(
                        '@${item['nick']}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      trailing: Text(
                        score is num ? score.toStringAsFixed(1) : 'Sin puntaje',
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _RankingTab extends StatelessWidget {
  const _RankingTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    ),
  );
}
