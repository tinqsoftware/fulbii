import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formatters/spanish_date_formatter.dart';

import '../../profile/data/profile_repository.dart';
import 'pichanga_detail_screen.dart';

final fullPichangaHistoryProvider = FutureProvider.autoDispose<List<dynamic>>(
  (ref) => ref.watch(profileRepositoryProvider).pichangaHistory(),
);

class PichangaHistoryScreen extends ConsumerWidget {
  const PichangaHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(fullPichangaHistoryProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Historial de pichangas')),
      body: history.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text('No se pudo cargar el historial: $error')),
        data: (items) => items.isEmpty
            ? const Center(
                child: Text('Todavía no tienes pichangas confirmadas.'),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final item = (items[index] as Map).cast<String, dynamic>();
                  final start = DateTime.tryParse(
                    (item['starts_at'] ?? '').toString(),
                  )?.toLocal();
                  final day = start?.day.toString().padLeft(2, '0') ?? '--';
                  final month = start == null
                      ? ''
                      : const [
                          'ENE',
                          'FEB',
                          'MAR',
                          'ABR',
                          'MAY',
                          'JUN',
                          'JUL',
                          'AGO',
                          'SEP',
                          'OCT',
                          'NOV',
                          'DIC',
                        ][start.month - 1];
                  final title = (item['title'] ?? 'Pichanga').toString();
                  final court = [
                    (item['court_name'] ?? '').toString(),
                    (item['field_name'] ?? '').toString(),
                  ].where((value) => value.isNotEmpty).join(' · ');
                  final team = (item['my_team_code'] ?? '').toString();
                  final goals =
                      int.tryParse((item['my_goals'] ?? 0).toString()) ?? 0;
                  final assists =
                      int.tryParse((item['my_assists'] ?? 0).toString()) ?? 0;
                  final id = int.tryParse(item['id'].toString()) ?? 0;
                  return Material(
                    borderRadius: BorderRadius.circular(16),
                    color: Theme.of(context).colorScheme.surfaceContainerLow,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: id <= 0
                          ? null
                          : () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    PichangaDetailScreen(pichangaId: id),
                              ),
                            ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Container(
                              width: 56,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    month,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  Text(
                                    day,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  if (court.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      court,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                  const SizedBox(height: 6),
                                  Wrap(
                                    spacing: 6,
                                    children: [
                                      _HistoryChip(
                                        label: SpanishDateFormatter.status(
                                          (item['status_label'] ??
                                                  item['status'])
                                              ?.toString(),
                                        ),
                                      ),
                                      if (team.isNotEmpty)
                                        _HistoryChip(label: 'Equipo $team'),
                                      if (goals > 0)
                                        _HistoryChip(label: '⚽ $goals'),
                                      if (assists > 0)
                                        _HistoryChip(label: '🅰 $assists'),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class _HistoryChip extends StatelessWidget {
  const _HistoryChip({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(label, style: Theme.of(context).textTheme.labelSmall),
  );
}
