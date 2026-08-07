import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../services/widget/widget_weekly_service.dart';
import '../data/pichangas_repository.dart';
import 'pichanga_detail_screen.dart';
import '../../home/main_shell.dart';
import '../../fields/presentation/map_screen.dart';

final pichangasBoardProvider = FutureProvider.autoDispose<Map<String, dynamic>>(
  (ref) => ref.watch(pichangasRepositoryProvider).myBoard(days: 7),
);

final pichangasCalendarProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, String>((ref, month) {
      final parsed = DateTime.tryParse('$month-01') ?? DateTime.now();
      return ref.watch(pichangasRepositoryProvider).calendarMonth(parsed);
    });

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
  bool _showCalendar = false;
  DateTime _visibleMonth = _firstDayOfMonth(DateTime.now());
  DateTime _selectedDay = _dateOnly(DateTime.now());

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refreshAll() async {
    ref.invalidate(pichangasBoardProvider);
    ref.invalidate(pichangasCalendarProvider(_monthKey(_visibleMonth)));
    await ref.read(widgetWeeklyServiceProvider).syncAll(ignoreErrors: true);
  }

  void _moveMonth(int delta) {
    final next = DateTime(_visibleMonth.year, _visibleMonth.month + delta);
    setState(() {
      _visibleMonth = _firstDayOfMonth(next);
      _selectedDay = DateTime(
        next.year,
        next.month,
        _selectedDay.day.clamp(
          1,
          DateUtils.getDaysInMonth(next.year, next.month),
        ),
      );
    });
  }

  void _goToToday() => setState(() {
    _visibleMonth = _firstDayOfMonth(DateTime.now());
    _selectedDay = _dateOnly(DateTime.now());
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: true,
      bottom: false,
      child: Column(
        children: [
          _ActionHeader(
            isCalendar: _showCalendar,
            onToggleCalendar: () =>
                setState(() => _showCalendar = !_showCalendar),
          ),
          Expanded(child: _showCalendar ? _buildCalendar() : _buildAgenda()),
        ],
      ),
    );
  }

  Widget _buildAgenda() {
    final asyncBoard = ref.watch(pichangasBoardProvider);
    return asyncBoard.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _LoadError(onRetry: _refreshAll, error: error),
      data: (board) {
        final confirmed = _asItems(board['confirmed_items']);
        final pending = _asItems(board['pending_items']);
        final terminated = _asItems(board['terminated_items']);
        return Column(
          children: [
            TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.center,
              dividerColor: Theme.of(context).colorScheme.outlineVariant,
              tabs: [
                Tab(text: 'Confirmadas (${confirmed.length})'),
                Tab(text: 'Pendientes (${pending.length})'),
                Tab(text: 'Terminadas (${terminated.length})'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _AgendaList(
                    items: confirmed,
                    emptyText: 'No tienes pichangas confirmadas esta semana.',
                    onRefresh: _refreshAll,
                    onOpen: _openDetail,
                    showWatch: true,
                  ),
                  _AgendaList(
                    items: pending,
                    emptyText: 'No tienes pichangas pendientes esta semana.',
                    onRefresh: _refreshAll,
                    onOpen: _openDetail,
                    pending: true,
                  ),
                  _AgendaList(
                    items: terminated,
                    emptyText: 'No tienes pichangas terminadas.',
                    onRefresh: _refreshAll,
                    onOpen: _openDetail,
                    terminated: true,
                    showWatch: true,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCalendar() {
    final key = _monthKey(_visibleMonth);
    final asyncItems = ref.watch(pichangasCalendarProvider(key));
    return asyncItems.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _LoadError(onRetry: _refreshAll, error: error),
      data: (items) => _PichangasCalendar(
        month: _visibleMonth,
        selectedDay: _selectedDay,
        items: items,
        onPreviousMonth: () => _moveMonth(-1),
        onNextMonth: () => _moveMonth(1),
        onToday: _goToToday,
        onSelectDay: (date) => setState(() => _selectedDay = _dateOnly(date)),
        onOpen: _openDetail,
      ),
    );
  }

  void _openDetail(int id) {
    if (id <= 0) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PichangaDetailScreen(pichangaId: id),
      ),
    );
  }
}

class _ActionHeader extends StatelessWidget {
  const _ActionHeader({
    required this.isCalendar,
    required this.onToggleCalendar,
  });

  final bool isCalendar;
  final VoidCallback onToggleCalendar;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      child: Align(
        alignment: Alignment.centerRight,
        child: Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: isCalendar ? 'Ver agenda' : 'Ver calendario',
                onPressed: onToggleCalendar,
                icon: Icon(
                  isCalendar
                      ? Icons.view_agenda_outlined
                      : Icons.calendar_month_outlined,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AgendaList extends ConsumerWidget {
  const _AgendaList({
    required this.items,
    required this.emptyText,
    required this.onRefresh,
    required this.onOpen,
    this.pending = false,
    this.terminated = false,
    this.showWatch = false,
  });

  final List<Map<String, dynamic>> items;
  final String emptyText;
  final Future<void> Function() onRefresh;
  final ValueChanged<int> onOpen;
  final bool pending;
  final bool terminated;
  final bool showWatch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Widget mainList;
    if (items.isEmpty) {
      mainList = RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(32),
          children: [
            const SizedBox(height: 96),
            Icon(
              Icons.sports_soccer_outlined,
              size: 38,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 12),
            Text(emptyText, textAlign: TextAlign.center),
          ],
        ),
      );
    } else {
      final groups = <String, List<Map<String, dynamic>>>{};
      for (final item in items) {
        final date = _parseDate(item['starts_at']);
        groups.putIfAbsent(_dateKey(date), () => []).add(item);
      }
      final entries = groups.entries.toList();

      mainList = RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
          itemCount: entries.length,
          itemBuilder: (context, index) {
            final entry = entries[index];
            final date = _parseDate(entry.value.first['starts_at']);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DateGroupLabel(date: date),
                const SizedBox(height: 8),
                ...entry.value.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _PichangaAgendaCard(
                      item: item,
                      pending: pending,
                      terminated: terminated,
                      showWatch: showWatch,
                      onTap: () =>
                          onOpen(int.tryParse(item['id'].toString()) ?? 0),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );
    }

    if (!pending && !terminated) {
      return Column(
        children: [
          Expanded(child: mainList),
          SafeArea(
            top: false,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
              ),
              child: FilledButton.icon(
                onPressed: () {
                  ref.read(mapScreenMessageProvider.notifier).state =
                      'Primero escoge una cancha y dentro de ella podrás crear la pichanga.';
                  ref.read(mainShellTabProvider.notifier).state = 0;
                },
                icon: const Icon(Icons.add_outlined),
                label: const Text('Crear pichanga'),
              ),
            ),
          ),
        ],
      );
    }

    return mainList;
  }
}

class _DateGroupLabel extends StatelessWidget {
  const _DateGroupLabel({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final today = _dateOnly(DateTime.now());
    final tomorrow = today.add(const Duration(days: 1));
    final label = _sameDate(date, today)
        ? 'HOY'
        : _sameDate(date, tomorrow)
        ? 'MAÑANA'
        : '${_weekdayName(date)} ${date.day} ${_monthName(date)}'.toUpperCase();
    return Text(
      label,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: Theme.of(context).colorScheme.primary,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.8,
      ),
    );
  }
}

class _PichangaAgendaCard extends StatelessWidget {
  const _PichangaAgendaCard({
    required this.item,
    required this.onTap,
    this.pending = false,
    this.terminated = false,
    this.showWatch = false,
  });

  final Map<String, dynamic> item;
  final VoidCallback onTap;
  final bool pending;
  final bool terminated;
  final bool showWatch;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final date = _parseDate(item['starts_at']);
    final venue = [item['court_name'], item['field_name'], item['address']]
        .whereType<Object>()
        .map((value) => value.toString().trim())
        .firstWhere(
          (value) => value.isNotEmpty,
          orElse: () => 'Cancha por confirmar',
        );
    final statusBadges = <Widget>[];
    if (item['is_in_progress'] == true) {
      statusBadges.add(
        const _PichangaBadge(text: 'En curso', color: Color(0xFF0A9A4A)),
      );
    }
    if (pending) {
      statusBadges.add(
        const _PichangaBadge(text: 'Pendiente', color: Color(0xFFD88C00)),
      );
    }
    if (terminated) {
      statusBadges.add(
        const _PichangaBadge(text: 'Terminada', color: Color(0xFF7A7F7A)),
      );
    }
    if (showWatch && item['watch_used'] == true) {
      statusBadges.add(
        const _PichangaBadge(text: 'Watch', color: Color(0xFF2F5DFF)),
      );
    }

    return Opacity(
      opacity: terminated ? 0.72 : 1,
      child: Material(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: colors.outlineVariant),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DateRail(date: date, muted: terminated),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (item['title'] ?? 'Pichanga').toString(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '⏱ ${DateFormat('HH:mm').format(date)} · ${item['duration_minutes'] ?? 90} min',
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '⌖ $venue',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 7),
                      Row(
                        children: [
                          Icon(
                            Icons.group_outlined,
                            size: 16,
                            color: colors.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${item['confirmed_count'] ?? 0}/${item['capacity'] ?? '-'} confirmados',
                          ),
                          const Spacer(),
                          if (!terminated)
                            Text(
                              '${item['spots_left'] ?? '-'} cupos',
                              style: TextStyle(
                                color: colors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                        ],
                      ),
                      if (statusBadges.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(spacing: 5, runSpacing: 4, children: statusBadges),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 2),
                Icon(Icons.chevron_right, color: colors.outline),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DateRail extends StatelessWidget {
  const _DateRail({required this.date, required this.muted});

  final DateTime date;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final color = muted
        ? Theme.of(context).colorScheme.outline
        : Theme.of(context).colorScheme.primary;
    return Container(
      width: 48,
      padding: const EdgeInsets.symmetric(vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            _weekdayName(date, short: true).toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            '${date.day}',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          Text(
            _monthName(date, short: true).toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _PichangasCalendar extends StatelessWidget {
  const _PichangasCalendar({
    required this.month,
    required this.selectedDay,
    required this.items,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onToday,
    required this.onSelectDay,
    required this.onOpen,
  });

  final DateTime month;
  final DateTime selectedDay;
  final List<Map<String, dynamic>> items;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final VoidCallback onToday;
  final ValueChanged<DateTime> onSelectDay;
  final ValueChanged<int> onOpen;

  @override
  Widget build(BuildContext context) {
    final byDate = <String, List<Map<String, dynamic>>>{};
    for (final item in items) {
      byDate
          .putIfAbsent(_dateKey(_parseDate(item['starts_at'])), () => [])
          .add(item);
    }
    final selectedItems = byDate[_dateKey(selectedDay)] ?? const [];
    final firstWeekday = DateTime(month.year, month.month).weekday - 1;
    final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: Row(
            children: [
              IconButton(
                onPressed: onPreviousMonth,
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: Text(
                  '${_monthName(month)} ${month.year}',
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
              TextButton(onPressed: onToday, child: const Text('Hoy')),
              IconButton(
                onPressed: onNextMonth,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _Weekday('L'),
              _Weekday('M'),
              _Weekday('X'),
              _Weekday('J'),
              _Weekday('V'),
              _Weekday('S'),
              _Weekday('D'),
            ],
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 270,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: firstWeekday + daysInMonth,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1.15,
              ),
              itemBuilder: (context, index) {
                if (index < firstWeekday) return const SizedBox.shrink();
                final date = DateTime(
                  month.year,
                  month.month,
                  index - firstWeekday + 1,
                );
                return _CalendarDay(
                  date: date,
                  selected: _sameDate(date, selectedDay),
                  today: _sameDate(date, DateTime.now()),
                  items: byDate[_dateKey(date)] ?? const [],
                  onTap: () => onSelectDay(date),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _SelectedDayAgenda(
            items: selectedItems,
            date: selectedDay,
            onOpen: onOpen,
          ),
        ),
      ],
    );
  }
}

class _Weekday extends StatelessWidget {
  const _Weekday(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Center(
      child: Text(
        label,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
      ),
    ),
  );
}

class _CalendarDay extends StatelessWidget {
  const _CalendarDay({
    required this.date,
    required this.selected,
    required this.today,
    required this.items,
    required this.onTap,
  });

  final DateTime date;
  final bool selected;
  final bool today;
  final List<Map<String, dynamic>> items;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final sections = items
        .map((item) => item['calendar_section']?.toString() ?? 'pending')
        .toSet();
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: selected ? colors.primaryContainer : null,
          border: today && !selected ? Border.all(color: colors.primary) : null,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${date.day}',
              style: TextStyle(
                fontWeight: today || selected
                    ? FontWeight.w900
                    : FontWeight.w600,
              ),
            ),
            if (sections.isNotEmpty) ...[
              const SizedBox(height: 4),
              Wrap(
                spacing: 2,
                children: sections
                    .take(3)
                    .map((section) => _CalendarDot(section: section))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CalendarDot extends StatelessWidget {
  const _CalendarDot({required this.section});
  final String section;

  @override
  Widget build(BuildContext context) {
    final color = switch (section) {
      'confirmed' => const Color(0xFF0A9A4A),
      'terminated' => const Color(0xFF7A7F7A),
      _ => const Color(0xFFD88C00),
    };
    return Container(
      width: 5,
      height: 5,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _SelectedDayAgenda extends StatelessWidget {
  const _SelectedDayAgenda({
    required this.items,
    required this.date,
    required this.onOpen,
  });
  final List<Map<String, dynamic>> items;
  final DateTime date;
  final ValueChanged<int> onOpen;

  @override
  Widget build(BuildContext context) {
    final label = '${_weekdayName(date)} ${date.day} ${_monthName(date)}';
    if (items.isEmpty) {
      return Center(child: Text('No hay pichangas el $label.'));
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: items.length + 1,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          );
        }
        final item = items[index - 1];
        final section = item['calendar_section']?.toString();
        return _PichangaAgendaCard(
          item: item,
          pending: section == 'pending',
          terminated: section == 'terminated',
          showWatch: true,
          onTap: () => onOpen(int.tryParse(item['id'].toString()) ?? 0),
        );
      },
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.onRetry, required this.error});
  final Future<void> Function() onRetry;
  final Object error;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_outlined, size: 42),
          const SizedBox(height: 12),
          const Text(
            'No se pudieron cargar tus pichangas.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: const Text('Reintentar')),
        ],
      ),
    ),
  );
}

class _PichangaBadge extends StatelessWidget {
  const _PichangaBadge({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      text,
      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: color),
    ),
  );
}

List<Map<String, dynamic>> _asItems(dynamic raw) => raw is List
    ? raw.whereType<Map>().map((item) => item.cast<String, dynamic>()).toList()
    : const <Map<String, dynamic>>[];

DateTime _parseDate(dynamic raw) =>
    DateTime.tryParse(raw?.toString() ?? '')?.toLocal() ?? DateTime.now();
DateTime _firstDayOfMonth(DateTime value) => DateTime(value.year, value.month);
DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);
String _monthKey(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}';
String _dateKey(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
bool _sameDate(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

const _months = [
  'enero',
  'febrero',
  'marzo',
  'abril',
  'mayo',
  'junio',
  'julio',
  'agosto',
  'septiembre',
  'octubre',
  'noviembre',
  'diciembre',
];
const _weekdays = [
  'lunes',
  'martes',
  'miércoles',
  'jueves',
  'viernes',
  'sábado',
  'domingo',
];

String _monthName(DateTime date, {bool short = false}) {
  final value = _months[date.month - 1];
  return short ? value.substring(0, 3) : value;
}

String _weekdayName(DateTime date, {bool short = false}) {
  final value = _weekdays[date.weekday - 1];
  return short ? value.substring(0, 3) : value;
}
