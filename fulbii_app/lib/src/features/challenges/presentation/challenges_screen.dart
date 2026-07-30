import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/challenges_repository.dart';
import 'challenge_detail_screen.dart';

final myChallengesProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>(
  (ref) => ref.watch(challengesRepositoryProvider).mine(),
);

class ChallengesScreen extends ConsumerWidget {
  const ChallengesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncItems = ref.watch(myChallengesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Retos')),
      body: asyncItems.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('No se pudo cargar retos: $error')),
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('No tienes retos activos.'));
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(myChallengesProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: items.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = items[index];
                final id = int.tryParse(item['id'].toString()) ?? 0;
                final status = (item['status'] ?? '').toString();
                final challenger =
                    (item['challenger_club'] as Map?)?.cast<String, dynamic>() ?? {};
                final challenged =
                    (item['challenged_club'] as Map?)?.cast<String, dynamic>() ?? {};
                final names =
                    '${challenger['nombre'] ?? 'Grupo A'} vs ${challenged['nombre'] ?? 'Grupo B'}';

                return Card(
                  child: ListTile(
                    title: Text(names),
                    subtitle: Text(
                      'Estado: $status • ${item['team_size'] ?? '-'} vs ${item['team_size'] ?? '-'}',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => ChallengeDetailScreen(challengeId: id),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

