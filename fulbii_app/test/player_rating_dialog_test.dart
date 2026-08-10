import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fulbii_app/src/features/profile/presentation/player_rating_dialog.dart';

void main() {
  testWidgets('shows the unified ratings in order with a live role preview', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              onPressed: () => showPlayerRatingDialog(
                context,
                candidates: const [PlayerRatingCandidate(id: 7, name: 'Ricci')],
                onSubmit: (_, _, _) async {},
              ),
              child: const Text('Abrir'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();

    final labels = ['Delantero', 'Mediocampo', 'Defensa', 'Arquero', 'Físico'];
    for (final label in labels) {
      expect(find.text(label), findsOneWidget);
    }
    expect(
      find.text(
        'Físico potencia tanto el perfil de campo como el de arquero. Tu puntaje principal toma el mejor de ambos.',
      ),
      findsOneWidget,
    );
    expect(find.text('Posición sugerida: Delantero'), findsOneWidget);
    expect(find.byType(Slider), findsNWidgets(5));

    // Arquero alto + físico base supera el promedio de campo.
    final goalkeeperSlider = find.byType(Slider).at(3);
    await tester.ensureVisible(goalkeeperSlider);
    await tester.drag(goalkeeperSlider, const Offset(140, 0));
    await tester.pump();
    expect(find.text('Posición sugerida: Arquero'), findsOneWidget);
  });

  testWidgets('submits the five named skill values for the selected player', (
    tester,
  ) async {
    Map<String, double>? submitted;
    var submittedId = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              onPressed: () => showPlayerRatingDialog(
                context,
                candidates: const [PlayerRatingCandidate(id: 9, name: 'Juan')],
                onSubmit: (id, values, _) async {
                  submittedId = id;
                  submitted = values;
                },
              ),
              child: const Text('Calificar'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Calificar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    expect(submittedId, 9);
    expect(submitted, containsPair('delantero', isA<double>()));
    expect(
      submitted!.keys,
      containsAll(<String>[
        'delantero',
        'mediocampo',
        'defensa',
        'arquero',
        'fisico',
      ]),
    );
  });
}
