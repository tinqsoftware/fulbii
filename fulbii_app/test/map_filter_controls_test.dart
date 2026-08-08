import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fulbii_app/src/features/fields/presentation/map_filter_controls.dart';

void main() {
  Widget buildSubject(Widget child) => MaterialApp(
    theme: ThemeData(useMaterial3: true),
    home: Scaffold(
      body: Padding(padding: const EdgeInsets.all(16), child: child),
    ),
  );

  testWidgets('keeps the three pichanga ranges in one compact row', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(375, 812));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      buildSubject(
        PichangaRangeSelector(
          selectedValue: 'custom',
          customLabel: '7–13 ago',
          onSelected: (_) {},
        ),
      ),
    );

    final today = tester.getRect(
      find.byKey(const Key('map-filter-range-today')),
    );
    final tomorrow = tester.getRect(
      find.byKey(const Key('map-filter-range-today_tomorrow')),
    );
    final custom = tester.getRect(
      find.byKey(const Key('map-filter-range-custom')),
    );

    expect(find.text('Hoy y\nmañana'), findsOneWidget);
    expect(find.text('7–13 ago'), findsOneWidget);
    expect(today.top, tomorrow.top);
    expect(tomorrow.top, custom.top);
    expect(today.right, lessThanOrEqualTo(tomorrow.left));
    expect(tomorrow.right, lessThanOrEqualTo(custom.left));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'surface controls expose their icons and retain multi-selection',
    (tester) async {
      final selected = <String>{};
      await tester.pumpWidget(
        buildSubject(
          StatefulBuilder(
            builder: (context, setState) => Row(
              children: [
                for (final surface in [
                  ('losa', 'Losa', Icons.grid_view_rounded),
                  ('sintetico', 'Grass sintético', Icons.grass_rounded),
                  ('natural', 'Grass natural', Icons.park_outlined),
                ])
                  Expanded(
                    child: SizedBox(
                      height: 62,
                      child: CompactFilterChoice(
                        label: surface.$2,
                        icon: surface.$3,
                        selected: selected.contains(surface.$1),
                        controlKey: Key('surface-${surface.$1}'),
                        onTap: () => setState(() => selected.add(surface.$1)),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.grid_view_rounded), findsOneWidget);
      expect(find.byIcon(Icons.grass_rounded), findsOneWidget);
      expect(find.byIcon(Icons.park_outlined), findsOneWidget);

      await tester.tap(find.byKey(const Key('surface-losa')));
      await tester.tap(find.byKey(const Key('surface-natural')));
      await tester.pump();

      expect(selected, {'losa', 'natural'});
    },
  );

  testWidgets('compact choices apply the same format and price values', (
    tester,
  ) async {
    String? format;
    String? price;
    await tester.pumpWidget(
      buildSubject(
        Column(
          children: [
            SizedBox(
              height: 40,
              child: CompactFilterChoice(
                label: '7v7',
                selected: false,
                controlKey: const Key('map-filter-format-7v7'),
                onTap: () => format = '7v7',
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 40,
              child: CompactFilterChoice(
                label: 'S/ 60 - 100',
                selected: false,
                controlKey: const Key('map-filter-price-60 - 100'),
                onTap: () => price = '60 - 100',
              ),
            ),
          ],
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('map-filter-format-7v7')));
    await tester.tap(find.byKey(const Key('map-filter-price-60 - 100')));

    expect(format, '7v7');
    expect(price, '60 - 100');
  });
}
