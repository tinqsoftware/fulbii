import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fulbii_app/src/features/fields/domain/field_model.dart';
import 'package:fulbii_app/src/features/fields/presentation/map_screen.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('es');
  });

  test('weekly map defaults cover today plus six days', () {
    final now = DateTime(2026, 8, 11, 19, 30);
    final range = MapPichangaDefaults.weeklyRange(now);

    expect(MapPichangaDefaults.content, 'both');
    expect(MapPichangaDefaults.range, 'custom');
    expect(range.start, DateTime(2026, 8, 11));
    expect(range.end, DateTime(2026, 8, 17));
  });

  test('map defaults keep every surface selected', () {
    const filter = MapFilterState();

    expect(filter.surfaceTypes, MapPichangaDefaults.surfaceTypes);
    expect(filter.surfaceTypes, ['losa', 'sintetico', 'natural']);
  });

  test('filter result label uses a compact singular and plural form', () {
    expect(mapFilterResultsLabel(1), 'Filtro - 1 cancha');
    expect(mapFilterResultsLabel(3), 'Filtro - 3 canchas');
  });

  test(
    'map safe area reserves extra space while the venue preview is open',
    () {
      final carouselInsets = mapCameraSafeInsets(hasSelectedPreview: false);
      final previewInsets = mapCameraSafeInsets(hasSelectedPreview: true);

      expect(carouselInsets.top, greaterThan(0));
      expect(carouselInsets.right, greaterThan(0));
      expect(previewInsets.bottom, greaterThan(carouselInsets.bottom));
    },
  );

  test('pichanga content counts only fields that match the pichanga range', () {
    const fields = [
      FieldModel(id: 1, nombre: 'Uno', x: -12.0, y: -77.0),
      FieldModel(id: 2, nombre: 'Dos', x: -12.1, y: -77.1),
    ];

    expect(
      mapFieldsMatchingContent(
        fields,
        content: 'pichangas',
        pichangaFieldIds: {2},
      ).map((field) => field.id),
      [2],
    );
    expect(
      mapFieldsMatchingContent(
        fields,
        content: 'both',
        pichangaFieldIds: {2},
      ).length,
      2,
    );
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
