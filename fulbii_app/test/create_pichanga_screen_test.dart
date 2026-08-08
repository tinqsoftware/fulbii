import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fulbii_app/src/features/pichangas/presentation/create_pichanga_screen.dart';

void main() {
  Future<void> pumpCreateScreen(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          myClubsForCreateProvider.overrideWith(
            (ref) async => [
              {'id': 4, 'nombre': 'Cazadores de Goles'},
            ],
          ),
        ],
        child: const MaterialApp(
          home: CreatePichangaScreen(
            initialFieldId: 8,
            initialAddress: 'Polideportivo Lince',
          ),
        ),
      ),
    );
  }

  testWidgets('shows contextual venue and duration presets', (tester) async {
    await pumpCreateScreen(tester);
    await tester.pumpAndSettle();

    expect(find.text('Cancha seleccionada'), findsOneWidget);
    expect(find.text('1 hora'), findsOneWidget);
    expect(find.text('1 h 30 min'), findsOneWidget);
    expect(find.text('2 horas'), findsOneWidget);

    await tester.ensureVisible(find.text('1 hora'));
    await tester.tap(find.text('1 hora'));
    await tester.pump();
    expect(find.text('Crear pichanga · 1 hora'), findsOneWidget);
  });

  testWidgets('opens the five-minute custom duration picker', (tester) async {
    await pumpCreateScreen(tester);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Personalizar'));
    await tester.tap(find.text('Personalizar'));
    await tester.pumpAndSettle();

    expect(find.text('Duración personalizada'), findsOneWidget);
    expect(find.text('Usar duración'), findsOneWidget);
  });
}
