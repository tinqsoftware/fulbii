import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fulbii_app/src/features/notifications/presentation/report_content_sheet.dart';

void main() {
  testWidgets('opens a compact report sheet with reason and detail', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              onPressed: () => showReportContentSheet(
                context,
                targetType: 'user',
                targetId: 7,
                title: 'Reportar jugador',
              ),
              child: const Text('Abrir'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();

    expect(find.text('Reportar jugador'), findsOneWidget);
    expect(find.text('Motivo'), findsOneWidget);
    expect(find.text('Detalle opcional'), findsOneWidget);
    expect(find.text('Enviar reporte'), findsOneWidget);
  });
}
