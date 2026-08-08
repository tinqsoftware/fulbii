import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fulbii_app/src/config/app_config.dart';
import 'package:fulbii_app/src/features/auth/session_controller.dart';
import 'package:fulbii_app/src/features/auth/session_state.dart';
import 'package:fulbii_app/src/features/clubs/presentation/clubs_screen.dart';

class _AuthenticatedSessionController extends SessionController {
  _AuthenticatedSessionController(super.ref) {
    state = const SessionState(
      initialized: true,
      loading: false,
      token: 'test-token',
    );
  }

  @override
  Future<void> bootstrap() async {}
}

void main() {
  testWidgets('renders compact group activity badges in one row', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(
            const AppConfig(
              env: AppEnv.stg,
              apiBaseUrl: 'https://fulbii.com/api/v1',
              appLinkBaseUrl: 'https://fulbii.com',
              googleWebClientId: '',
              appName: 'Fulbii',
            ),
          ),
          sessionControllerProvider.overrideWith(
            _AuthenticatedSessionController.new,
          ),
          mineClubsProvider('').overrideWith(
            (ref) async => [
              {
                'id': 7,
                'nombre': 'Cazadores de Goles',
                'miembros_count': 12,
                'pending_pichangas_count': 5,
                'my_confirmed_pichangas_count': 2,
                'has_my_confirmed_pichanga': true,
              },
            ],
          ),
          discoverClubsProvider('').overrideWith((ref) async => const []),
          myInvitationsProvider.overrideWith((ref) async => const []),
        ],
        child: const MaterialApp(home: Scaffold(body: ClubsScreen())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('5 pichangas'), findsOneWidget);
    expect(find.text('Asistiré a 2'), findsOneWidget);
    expect(find.textContaining('pendientes'), findsNothing);
    expect(find.text('Confirmaste'), findsNothing);

    final pichangasBadge = find.byKey(const ValueKey('club-pichangas-badge-7'));
    final attendingBadge = find.byKey(const ValueKey('club-attending-badge-7'));
    expect(
      tester.getTopLeft(pichangasBadge).dy,
      tester.getTopLeft(attendingBadge).dy,
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('club-photo-7'))).height,
      greaterThan(80),
    );
  });
}
