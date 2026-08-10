import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fulbii_app/src/features/fields/domain/field_model.dart';
import 'package:fulbii_app/src/features/pichangas/presentation/create_pichanga_screen.dart';

void main() {
  const selectedField = FieldModel(
    id: 8,
    nombre: 'Polideportivo Lince',
    x: 0,
    y: 0,
    direccion: 'Av. Arenales 123',
    canchas: [
      FieldCourtModel(
        id: 80,
        nombre: 'Cancha 1',
        surfaceType: 'Grass sintético',
        vsFormat: '7vs7',
      ),
    ],
  );

  Future<void> pumpCreateScreen(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          myClubsForCreateProvider.overrideWith(
            (ref) async => [
              {
                'id': 4,
                'nombre': 'Cazadores de Goles',
                'my_role': 'miembro',
                'pichanga_create_scope': 'members',
              },
              {
                'id': 9,
                'nombre': 'Solo admins FC',
                'my_role': 'miembro',
                'pichanga_create_scope': 'admins',
              },
            ],
          ),
          createPichangaFieldProvider(
            8,
          ).overrideWith((ref) async => selectedField),
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

  testWidgets('shows compact defaults and requires a real court selection', (
    tester,
  ) async {
    await pumpCreateScreen(tester);
    await tester.pumpAndSettle();

    expect(find.text('Polideportivo Lince'), findsOneWidget);
    expect(find.text('Elige una cancha'), findsOneWidget);
    expect(find.byKey(const Key('description_textarea')), findsNothing);
    await tester.tap(find.text('Añadir descripción'));
    await tester.pump();
    expect(find.byKey(const Key('description_textarea')), findsOneWidget);

    await tester.tap(find.byKey(const Key('court_option_80')));
    await tester.pump();
    expect(find.byIcon(Icons.check_circle), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byKey(const Key('players_5')),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.scrollUntilVisible(
      find.byKey(const Key('custom_duration_button')),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('1 hora'), findsWidgets);
    expect(find.byKey(const Key('players_5')), findsOneWidget);
    expect(find.byKey(const Key('players_11')), findsOneWidget);
    expect(find.byKey(const Key('custom_duration_button')), findsOneWidget);
  });

  testWidgets('groups selectable and admin-only groups are separated', (
    tester,
  ) async {
    await pumpCreateScreen(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('group_picker')));
    await tester.pumpAndSettle();

    expect(find.text('Puedes crear pichangas'), findsOneWidget);
    expect(find.text('Solo administradores'), findsWidgets);
    expect(find.byKey(const Key('club_option_4')), findsOneWidget);
    expect(find.byKey(const Key('club_option_9')), findsOneWidget);
    expect(
      tester.widget<ListTile>(find.byKey(const Key('club_option_9'))).enabled,
      isFalse,
    );
  });

  testWidgets('opens the custom duration picker from the compact row', (
    tester,
  ) async {
    await pumpCreateScreen(tester);
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const Key('custom_duration_button')),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('custom_duration_button')));
    await tester.pumpAndSettle();

    expect(find.text('Duración personalizada'), findsOneWidget);
    expect(find.text('Usar duración'), findsOneWidget);
  });
}
