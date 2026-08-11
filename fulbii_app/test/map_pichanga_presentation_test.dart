import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fulbii_app/src/features/fields/presentation/map_screen.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('es');
  });

  test('weekly map defaults cover today plus six days', () {
    final now = DateTime(2026, 8, 11, 19, 30);
    final range = MapPichangaDefaults.weeklyRange(now);

    expect(MapPichangaDefaults.content, 'pichangas');
    expect(MapPichangaDefaults.range, 'custom');
    expect(range.start, DateTime(2026, 8, 11));
    expect(range.end, DateTime(2026, 8, 17));
  });

  test('map defaults keep every surface selected', () {
    const filter = MapFilterState();

    expect(filter.surfaceTypes, MapPichangaDefaults.surfaceTypes);
    expect(filter.surfaceTypes, ['losa', 'sintetico', 'natural']);
  });

  test('only today and tomorrow receive an urgent map date badge', () {
    final now = DateTime(2026, 8, 11, 10);

    expect(
      mapPichangaUrgencyFor('2026-08-11T19:00:00', now: now),
      MapPichangaUrgency.today,
    );
    expect(
      mapPichangaUrgencyFor('2026-08-12T19:00:00', now: now),
      MapPichangaUrgency.tomorrow,
    );
    expect(
      mapPichangaUrgencyFor('2026-08-13T19:00:00', now: now),
      MapPichangaUrgency.none,
    );
  });

  testWidgets('status tags always use white text in a light theme', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.light(),
        home: const Scaffold(body: MapPichangaStatusTag(label: 'Mi grupo')),
      ),
    );

    final label = tester.widget<Text>(find.text('Mi grupo'));
    expect(label.style?.color, Colors.white);
  });

  testWidgets('today badge keeps an intrinsic compact width', (tester) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day, 19).toIso8601String();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: MapPichangaDateBadge(rawDate: today, selected: false),
          ),
        ),
      ),
    );

    final badge = find.byType(MapPichangaDateBadge);
    expect(tester.getSize(badge).width, lessThan(190));
    expect(find.textContaining('Hoy'), findsOneWidget);
  });

  testWidgets('later dates remain visible without using an urgency badge', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MapPichangaPlainDate(rawDate: '2026-08-13T19:00:00'),
        ),
      ),
    );

    expect(find.byType(MapPichangaDateBadge), findsNothing);
    expect(find.textContaining('13'), findsOneWidget);
  });
}
