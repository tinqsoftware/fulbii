import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fulbii_app/src/features/pichangas/presentation/pichangas_screen.dart';

void main() {
  final now = DateTime.now();
  final monthKey =
      '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}';
  final item = <String, dynamic>{
    'id': 7,
    'title': 'Pichanga de prueba',
    'starts_at': now.toIso8601String(),
    'duration_minutes': 90,
    'court_name': 'Cancha Norte',
    'field_name': 'Polideportivo Lima',
    'confirmed_count': 8,
    'capacity': 14,
    'spots_left': 6,
    'calendar_section': 'confirmed',
  };

  testWidgets('renders agenda tabs and switches to calendar', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          pichangasBoardProvider.overrideWith(
            (ref) async => {
              'confirmed_items': [item],
              'pending_items': const [],
              'terminated_items': const [],
            },
          ),
          pichangasCalendarProvider(
            monthKey,
          ).overrideWith((ref) async => [item]),
        ],
        child: const MaterialApp(home: Scaffold(body: PichangasScreen())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Confirmadas (1)'), findsOneWidget);
    expect(find.text('Asistencia confirmada'), findsOneWidget);
    expect(find.text('Pendientes (0)'), findsOneWidget);
    expect(find.textContaining('Cancha Norte'), findsOneWidget);
    expect(find.text('Pichangas'), findsNothing);

    await tester.tap(find.byTooltip('Ver calendario'));
    await tester.pumpAndSettle();

    expect(find.text('Hoy'), findsOneWidget);
    expect(find.text('Lista'), findsOneWidget);
    expect(find.textContaining('Cancha Norte'), findsOneWidget);
    expect(
      find.byKey(
        Key(
          'calendar-day-status-${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
        ),
      ),
      findsOneWidget,
    );
  });

  testWidgets('marks a day with both confirmation states', (tester) async {
    final pending = {...item, 'id': 8, 'calendar_section': 'pending'};
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          pichangasBoardProvider.overrideWith(
            (ref) async => {
              'confirmed_items': const [],
              'pending_items': [pending],
              'terminated_items': const [],
            },
          ),
          pichangasCalendarProvider(
            monthKey,
          ).overrideWith((ref) async => [item, pending]),
        ],
        child: const MaterialApp(home: Scaffold(body: PichangasScreen())),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Ver calendario'));
    await tester.pumpAndSettle();
    expect(find.text('No confirmada'), findsOneWidget);
    expect(
      find.byKey(
        Key(
          'calendar-day-status-${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
        ),
      ),
      findsOneWidget,
    );
  });
}
