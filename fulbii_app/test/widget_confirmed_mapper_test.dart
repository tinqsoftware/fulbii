import 'package:flutter_test/flutter_test.dart';

import 'package:fulbii_app/src/services/widget/widget_confirmed_mapper.dart';

void main() {
  test('buildPayload keeps top 3 and resolves selected id', () {
    final items = <Map<String, dynamic>>[
      {
        'id': 11,
        'title': 'Primera',
        'starts_at': DateTime(2026, 3, 30, 20, 0).toUtc().toIso8601String(),
        'duration_minutes': 60,
        'players_per_team': 7,
        'match_format': 'versus',
        'team_count': 2,
        'me_participant_status': 'confirmed',
        'share_url': 'https://fulbii.com/pichanga/11',
        'teams': const [],
      },
      {
        'id': 22,
        'title': 'Segunda',
        'starts_at': DateTime(2026, 3, 31, 20, 0).toUtc().toIso8601String(),
        'duration_minutes': 60,
        'players_per_team': 7,
        'match_format': 'versus',
        'team_count': 2,
        'me_participant_status': 'confirmed',
        'share_url': 'https://fulbii.com/pichanga/22',
        'teams': const [],
      },
      {
        'id': 33,
        'title': 'Tercera',
        'starts_at': DateTime(2026, 4, 1, 20, 0).toUtc().toIso8601String(),
        'duration_minutes': 60,
        'players_per_team': 7,
        'match_format': 'versus',
        'team_count': 2,
        'me_participant_status': 'confirmed',
        'share_url': 'https://fulbii.com/pichanga/33',
        'teams': const [],
      },
      {
        'id': 44,
        'title': 'Cuarta',
        'starts_at': DateTime(2026, 4, 2, 20, 0).toUtc().toIso8601String(),
        'duration_minutes': 60,
        'players_per_team': 7,
        'match_format': 'versus',
        'team_count': 2,
        'me_participant_status': 'confirmed',
        'share_url': 'https://fulbii.com/pichanga/44',
        'teams': const [],
      },
    ];

    final payload = WidgetConfirmedMapper.buildPayload(
      items,
      selectedPichangaId: 33,
      now: DateTime(2026, 3, 30, 10, 0),
    );
    final mappedItems = (payload['items'] as List).cast<Map<String, dynamic>>();

    expect(mappedItems, hasLength(3));
    expect(mappedItems.map((item) => item['id']), [11, 22, 33]);
    expect(payload['selected_pichanga_id'], 33);
    expect(payload['is_logged_in'], isTrue);
    expect(mappedItems.first['date_label'], '30 Mar');
    expect(mappedItems.first['time_label'], '8:00pm');

    final fallbackSelection = WidgetConfirmedMapper.buildPayload(
      items,
      selectedPichangaId: 999,
      now: DateTime(2026, 3, 30, 10, 0),
    );
    expect(fallbackSelection['selected_pichanga_id'], 11);
  });

  test('buildPayload formats morning hours with a compact am suffix', () {
    final payload = WidgetConfirmedMapper.buildPayload([
      {
        'id': 7,
        'title': 'Mañanera',
        'starts_at': DateTime(2026, 3, 30, 11, 30).toUtc().toIso8601String(),
      },
    ]);

    final item = (payload['items'] as List).single as Map<String, dynamic>;
    expect(item['time_label'], '11:30am');
  });

  test('logged out payload clears items and keeps login message', () {
    final payload = WidgetConfirmedMapper.buildLoggedOutPayload(
      now: DateTime(2026, 3, 30, 10, 0),
    );
    expect(payload['is_logged_in'], isFalse);
    expect(payload['login_message'], 'Inicia sesión');
    expect(payload['items'], isEmpty);
    expect(payload['selected_pichanga_id'], isNull);
  });

  test('applySelection only applies when id exists', () {
    final payload = WidgetConfirmedMapper.buildPayload(const [
      {'id': 7, 'title': 'A', 'starts_at': '2026-03-30T20:00:00Z'},
      {'id': 8, 'title': 'B', 'starts_at': '2026-03-31T20:00:00Z'},
    ], now: DateTime(2026, 3, 30, 10, 0));

    expect(WidgetConfirmedMapper.applySelection(payload, 8), isTrue);
    expect(payload['selected_pichanga_id'], 8);
    expect(WidgetConfirmedMapper.applySelection(payload, 999), isFalse);
    expect(payload['selected_pichanga_id'], 8);
  });
}
