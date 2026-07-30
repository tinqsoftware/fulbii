import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/pichangas_repository.dart';
import '../../../services/widget/widget_weekly_service.dart';
import 'pichanga_detail_screen.dart';

final pichangasBoardProvider = FutureProvider.autoDispose<Map<String, dynamic>>(
  (ref) => ref.watch(pichangasRepositoryProvider).myBoard(days: 7),
);

class PichangasScreen extends ConsumerStatefulWidget {
  const PichangasScreen({super.key});

  @override
  ConsumerState<PichangasScreen> createState() => _PichangasScreenState();
}

class _PichangasScreenState extends ConsumerState<PichangasScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(
    length: 3,
    vsync: this,
  );

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refreshAll() async {
    ref.invalidate(pichangasBoardProvider);
    await ref.read(widgetWeeklyServiceProvider).syncAll(ignoreErrors: true);
  }

  @override
  Widget build(BuildContext context) {
    final asyncBoard = ref.watch(pichangasBoardProvider);

    return asyncBoard.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('No se pudo cargar pichangas: $error'),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _refreshAll,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
      data: (board) {
        final confirmed = _asItems(board['confirmed_items']);
        final pending = _asItems(board['pending_items']);
        final terminated = _asItems(board['terminated_items']);

        return Column(
          children: [
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Confirmados'),
                Tab(text: 'Pendientes'),
                Tab(text: 'Terminados'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildList(
                    items: confirmed,
                    emptyText: 'No tienes pichangas confirmadas vigentes.',
                    onRefresh: _refreshAll,
                    showInProgressBadge: true,
                    showWatchBadge: true,
                  ),
                  _buildList(
                    items: pending,
                    emptyText: 'No tienes pichangas pendientes vigentes.',
                    onRefresh: _refreshAll,
                  ),
                  _buildList(
                    items: terminated,
                    emptyText: 'No tienes pichangas terminadas.',
                    onRefresh: _refreshAll,
                    showWatchBadge: true,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildList({
    required List<Map<String, dynamic>> items,
    required String emptyText,
    required Future<void> Function() onRefresh,
    bool showInProgressBadge = false,
    bool showWatchBadge = false,
  }) {
    if (items.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [Center(child: Text(emptyText))],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: items.length,
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final item = items[index];
          final id = int.tryParse(item['id'].toString()) ?? 0;
          final title = (item['title'] ?? 'Pichanga #$id').toString();
          final startsAt = _formatStartsAt(item['starts_at']?.toString());
          final status = (item['status'] ?? '').toString();
          final spotsLeft = item['spots_left']?.toString() ?? '-';
          final badges = <Widget>[];
          if (showInProgressBadge && item['is_in_progress'] == true) {
            badges.add(
              const _PichangaBadge(
                text: 'En proceso',
                color: Color(0xFF0A9A4A),
              ),
            );
          }
          if (showWatchBadge && item['watch_used'] == true) {
            badges.add(
              const _PichangaBadge(text: 'Watch', color: Color(0xFF2F5DFF)),
            );
          }

          return Card(
            child: ListTile(
              title: Text(title),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$startsAt\nEstado: $status • Cupos: $spotsLeft'),
                  if (badges.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Wrap(spacing: 6, runSpacing: 6, children: badges),
                  ],
                ],
              ),
              isThreeLine: true,
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => PichangaDetailScreen(pichangaId: id),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  List<Map<String, dynamic>> _asItems(dynamic raw) {
    if (raw is! List) return const <Map<String, dynamic>>[];
    return raw
        .whereType<Map>()
        .map((item) => item.cast<String, dynamic>())
        .toList();
  }

  String _formatStartsAt(String? raw) {
    if (raw == null || raw.isEmpty) return '-';
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    return DateFormat('dd/MM/yyyy HH:mm').format(parsed.toLocal());
  }
}

class _PichangaBadge extends StatelessWidget {
  const _PichangaBadge({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
