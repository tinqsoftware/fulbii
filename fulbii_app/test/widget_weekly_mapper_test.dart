import 'package:flutter_test/flutter_test.dart';

import 'package:fulbii_app/src/services/widget/widget_weekly_mapper.dart';

void main() {
  test('buildPayload maps 7 days and prioritizes confirmed state', () {
    final now = DateTime(2026, 3, 29, 9, 0);
    final items = <Map<String, dynamic>>[
      {
        'id': 101,
        'title': 'Hoy pendiente',
        'starts_at': DateTime(2026, 3, 29, 20, 0).toUtc().toIso8601String(),
        'me_participant_status': null,
        'me_pending_kind': 'pending_group',
      },
      {
        'id': 102,
        'title': 'Hoy confirmada',
        'starts_at': DateTime(2026, 3, 29, 22, 0).toUtc().toIso8601String(),
        'me_participant_status': 'confirmed',
        'me_pending_kind': null,
      },
      {
        'id': 201,
        'title': 'Dia 1 abierta',
        'starts_at': DateTime(2026, 3, 30, 21, 0).toUtc().toIso8601String(),
        'me_participant_status': null,
        'me_pending_kind': 'pending_open',
      },
      {
        'id': 601,
        'title': 'Fuera de ventana',
        'starts_at': DateTime(2026, 4, 5, 21, 0).toUtc().toIso8601String(),
        'me_participant_status': 'confirmed',
        'me_pending_kind': null,
      },
      {
        'id': 701,
        'title': 'Dia 6 abierta',
        'starts_at': DateTime(2026, 4, 3, 21, 0).toUtc().toIso8601String(),
        'me_participant_status': null,
        'me_pending_kind': 'pending_open',
      },
    ];

    final payload = WidgetWeeklyMapper.buildPayload(
      items,
      now: now,
      monthlyPlayedCount: 10,
    );
    final days = (payload['days'] as List).cast<Map<String, dynamic>>();

    expect(days, hasLength(7));
    expect(payload['monthly_played_count'], 10);
    expect(payload['is_logged_in'], isTrue);
    expect(payload['header_title'], 'Pichangas de la semana');
    expect(payload['header_subtitle'], 'Hoy + 6 días');

    expect(days[0]['status'], 'green');
    expect(days[0]['pichanga_id'], 102);
    expect(days[0]['time'], '22:00');

    expect(days[1]['status'], 'yellow');
    expect(days[1]['pichanga_id'], 201);

    expect(days[2]['status'], 'neutral');
    expect(days[3]['status'], 'neutral');
    expect(days[4]['status'], 'neutral');
    expect(days[5]['status'], 'yellow');
    expect(days[5]['pichanga_id'], 701);
    expect(days[6]['status'], 'neutral');
  });

  test('buildLoggedOutPayload contains no personal data', () {
    final now = DateTime(2026, 3, 29, 9, 0);
    final payload = WidgetWeeklyMapper.buildLoggedOutPayload(now: now);
    final days = (payload['days'] as List).cast<Map<String, dynamic>>();

    expect(payload['is_logged_in'], isFalse);
    expect(payload['monthly_played_count'], 0);
    expect(payload['login_message'], 'Inicia sesión');
    expect(days, hasLength(7));
    expect(days.every((day) => day['time'] == null), isTrue);
    expect(days.every((day) => day['pichanga_id'] == null), isTrue);
  });
}
