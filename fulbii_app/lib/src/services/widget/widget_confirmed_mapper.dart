class WidgetConfirmedMapper {
  static const int maxItems = 3;
  static const String loginMessage = 'Inicia sesión';

  static Map<String, dynamic> buildPayload(
    List<Map<String, dynamic>> rawItems, {
    int? selectedPichangaId,
    bool isLoggedIn = true,
    DateTime? now,
  }) {
    final generatedAt = (now ?? DateTime.now()).toLocal().toIso8601String();
    final items = isLoggedIn
        ? rawItems.take(maxItems).map(_mapItem).whereType<Map<String, dynamic>>().toList()
        : <Map<String, dynamic>>[];

    final validIds = items
        .map((item) => item['id'])
        .whereType<int>()
        .toSet();
    final resolvedSelectedId = selectedPichangaId != null && validIds.contains(selectedPichangaId)
        ? selectedPichangaId
        : (items.isNotEmpty ? items.first['id'] as int : null);

    return {
      'generated_at': generatedAt,
      'is_logged_in': isLoggedIn,
      'login_message': loginMessage,
      'selected_pichanga_id': resolvedSelectedId,
      'items': items,
    };
  }

  static Map<String, dynamic> buildLoggedOutPayload({DateTime? now}) {
    return buildPayload(
      const [],
      isLoggedIn: false,
      now: now,
    );
  }

  static Map<String, dynamic>? selectedItemFromPayload(Map<String, dynamic> payload) {
    final items = payload['items'] is List
        ? (payload['items'] as List).whereType<Map>().map((item) => item.cast<String, dynamic>()).toList()
        : <Map<String, dynamic>>[];
    if (items.isEmpty) {
      return null;
    }

    final selectedId = _toInt(payload['selected_pichanga_id']);
    if (selectedId == null) {
      return items.first;
    }

    for (final item in items) {
      if (_toInt(item['id']) == selectedId) {
        return item;
      }
    }

    return items.first;
  }

  static bool applySelection(Map<String, dynamic> payload, int pichangaId) {
    final items = payload['items'] is List
        ? (payload['items'] as List).whereType<Map>().map((item) => item.cast<String, dynamic>()).toList()
        : <Map<String, dynamic>>[];
    final exists = items.any((item) => _toInt(item['id']) == pichangaId);
    if (!exists) {
      return false;
    }
    payload['selected_pichanga_id'] = pichangaId;
    return true;
  }

  static String buildShareText(Map<String, dynamic> pichanga) {
    final title = (pichanga['title'] ?? 'Pichanga').toString();
    final startsAt = DateTime.tryParse((pichanga['starts_at'] ?? '').toString())?.toLocal();
    final startsLabel = startsAt == null
        ? '-'
        : '${startsAt.day.toString().padLeft(2, '0')} ${_monthShortEs(startsAt.month)} ${startsAt.year} - ${startsAt.hour.toString().padLeft(2, '0')}:${startsAt.minute.toString().padLeft(2, '0')}';
    final playersPerTeam = _toInt(pichanga['players_per_team']) ?? 0;
    final durationMinutes = _toInt(pichanga['duration_minutes']) ?? 0;
    final formatLine = playersPerTeam > 0
        ? '${playersPerTeam}vs$playersPerTeam - ${durationMinutes}min'
        : '${(pichanga['match_format'] ?? '-').toString()} - ${durationMinutes}min';

    final teams = pichanga['teams'] is List
        ? (pichanga['teams'] as List).whereType<Map>().map((item) => item.cast<String, dynamic>()).toList()
        : <Map<String, dynamic>>[];

    final buffer = StringBuffer()
      ..writeln(title)
      ..writeln('Fecha: $startsLabel')
      ..writeln('Formato: $formatLine')
      ..writeln('')
      ..writeln('Confirmados:');

    if (teams.isEmpty) {
      buffer.writeln('- Sin equipos confirmados todavía');
    } else {
      for (final team in teams) {
        final code = (team['code'] ?? '-').toString();
        final avgRating = team['avg_rating'];
        final ratingLabel = avgRating == null ? '-' : avgRating.toString();
        buffer.writeln('Equipo $code (*$ratingLabel)');

        final slots = team['slots'] is List
            ? (team['slots'] as List).whereType<Map>().map((item) => item.cast<String, dynamic>()).toList()
            : <Map<String, dynamic>>[];

        var index = 1;
        for (final slot in slots) {
          final user = slot['user'] is Map
              ? (slot['user'] as Map).cast<String, dynamic>()
              : null;
          if (user == null) {
            continue;
          }
          final name = _displayName(user);
          if (name.isEmpty) {
            continue;
          }
          buffer.writeln('$index. $name');
          index++;
        }

        if (index == 1) {
          buffer.writeln('- Sin confirmados');
        }

        buffer.writeln('');
      }
    }

    final shareUrl = (pichanga['share_url'] ?? '').toString().trim();
    if (shareUrl.isNotEmpty) {
      buffer.writeln('Ver pichanga: $shareUrl');
    }

    return buffer.toString().trim();
  }

  static Map<String, dynamic>? _mapItem(Map<String, dynamic> raw) {
    final id = _toInt(raw['id']);
    if (id == null) {
      return null;
    }

    final startsAtRaw = (raw['starts_at'] ?? '').toString();
    final startsAt = DateTime.tryParse(startsAtRaw)?.toLocal();
    final startsLabel = startsAt == null
        ? '-'
        : '${startsAt.day} ${_monthShortEs(startsAt.month)} - ${startsAt.hour.toString().padLeft(2, '0')}:${startsAt.minute.toString().padLeft(2, '0')}';

    final playersPerTeam = _toInt(raw['players_per_team']) ?? 0;
    final durationMinutes = _toInt(raw['duration_minutes']) ?? 0;
    final formatLabel = playersPerTeam > 0
        ? '${playersPerTeam}vs$playersPerTeam - ${durationMinutes}min'
        : '${(raw['match_format'] ?? '-').toString()} - ${durationMinutes}min';

    final teams = raw['teams'] is List
        ? (raw['teams'] as List)
            .whereType<Map>()
            .map((item) => item.cast<String, dynamic>())
            .map((team) {
              final slots = team['slots'] is List
                  ? (team['slots'] as List)
                      .whereType<Map>()
                      .map((slot) => slot.cast<String, dynamic>())
                      .map((slot) {
                        final user = slot['user'] is Map
                            ? (slot['user'] as Map).cast<String, dynamic>()
                            : null;
                        return {
                          'slot': _toInt(slot['slot']) ?? 0,
                          'user': user == null
                              ? null
                              : {
                                  'name': user['name']?.toString(),
                                  'nick': user['nick']?.toString(),
                                  'is_me': user['is_me'] == true,
                                },
                          'display_name': user == null ? '' : _displayName(user),
                        };
                      })
                      .toList()
                  : <Map<String, dynamic>>[];

              return {
                'code': (team['code'] ?? '').toString(),
                'avg_rating': team['avg_rating'],
                'slots': slots,
              };
            })
            .toList()
        : <Map<String, dynamic>>[];

    return {
      'id': id,
      'title': (raw['title'] ?? 'Pichanga #$id').toString(),
      'starts_at': startsAtRaw,
      'starts_label': startsLabel,
      'format_label': formatLabel,
      'duration_minutes': durationMinutes,
      'match_format': raw['match_format']?.toString(),
      'team_count': _toInt(raw['team_count']) ?? 0,
      'players_per_team': playersPerTeam,
      'me_participant_status': (raw['me_participant_status'] ?? '').toString(),
      'share_url': (raw['share_url'] ?? '').toString(),
      'teams': teams,
    };
  }

  static int? _toInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  static String _displayName(Map<String, dynamic> user) {
    final nick = (user['nick'] ?? '').toString().trim();
    if (nick.isNotEmpty) {
      return nick;
    }
    return (user['name'] ?? '').toString().trim();
  }

  static String _monthShortEs(int month) {
    const months = <int, String>{
      1: 'Ene',
      2: 'Feb',
      3: 'Mar',
      4: 'Abr',
      5: 'May',
      6: 'Jun',
      7: 'Jul',
      8: 'Ago',
      9: 'Sep',
      10: 'Oct',
      11: 'Nov',
      12: 'Dic',
    };
    return months[month] ?? '';
  }
}
