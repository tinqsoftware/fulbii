import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fulbii_app/src/app.dart';
import 'package:fulbii_app/src/core/theme/fulbii_snackbar.dart';

void main() {
  test('uses a floating snack bar theme in dark and light modes', () {
    final dark = fulbiiTheme(Brightness.dark).snackBarTheme;
    final light = fulbiiTheme(Brightness.light).snackBarTheme;

    expect(dark.behavior, SnackBarBehavior.floating);
    expect(light.behavior, SnackBarBehavior.floating);
    expect(dark.backgroundColor, const Color(0xFF163B24));
    expect(light.backgroundColor, const Color(0xFFE4F5E5));
    expect(dark.actionTextColor, const Color(0xFF70D994));
    expect(light.actionTextColor, const Color(0xFF5FAF70));
    expect(dark.shape, isA<RoundedRectangleBorder>());
    expect(light.shape, isA<RoundedRectangleBorder>());
  });

  testWidgets('renders a two-line message and action with the global style', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: fulbiiTheme(Brightness.dark),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Mensaje principal\nDetalle del mensaje'),
                  action: SnackBarAction(label: 'Abrir', onPressed: () {}),
                ),
              ),
              child: const Text('Mostrar'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Mostrar'));
    await tester.pump();

    expect(find.textContaining('Mensaje principal'), findsOneWidget);
    expect(find.text('Abrir'), findsOneWidget);
    expect(
      Theme.of(tester.element(find.byType(SnackBar))).snackBarTheme.behavior,
      SnackBarBehavior.floating,
    );
  });

  test('uses Fulbii semantic success and error tones', () {
    final success = fulbiiSnackBar(
      'Guardado',
      tone: FulbiiSnackBarTone.success,
    );
    final error = fulbiiSnackBar('Falló', tone: FulbiiSnackBarTone.error);

    expect(success.backgroundColor, const Color(0xFF1B5E2B));
    expect(error.backgroundColor, const Color(0xFF71342E));
  });
}
