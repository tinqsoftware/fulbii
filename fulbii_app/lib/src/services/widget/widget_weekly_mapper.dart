class WidgetWeeklyMapper {
  static const int windowDays = 7;
  static const String headerTitle = 'Pichangas de la semana';
  static const String headerSubtitle = 'Hoy + 6 días';
  static const String loginMessage = 'Inicia sesión';

  static Map<String, dynamic> buildPayload(
    List<Map<String, dynamic>> items, {
    DateTime? now,
    int monthlyPlayedCount = 0,
    bool isLoggedIn = true,
  }) {
    final localNow = (now ?? DateTime.now()).toLocal();
    final startDay = DateTime(localNow.year, localNow.month, localNow.day);
    final dayBuckets = List.generate(
      windowDays,
      (index) => _DayBucket(
        date: startDay.add(Duration(days: index)),
      ),
    );

    if (isLoggedIn) {
      for (final item in items) {
        final startsAt = DateTime.tryParse((item['starts_at'] ?? '').toString());
        if (startsAt == null) {
          continue;
        }
        final localStart = startsAt.toLocal();
        final eventDay = DateTime(localStart.year, localStart.month, localStart.day);
        final dayIndex = eventDay.difference(startDay).inDays;
        if (dayIndex < 0 || dayIndex >= windowDays) {
          continue;
        }

        final participantStatus =
            (item['me_participant_status'] ?? '').toString().toLowerCase();
        final pendingKind = (item['me_pending_kind'] ?? '').toString().toLowerCase();
        final isConfirmed = participantStatus == 'confirmed';
        final isPending =
            pendingKind == 'pending_group' || pendingKind == 'pending_open';
        if (!isConfirmed && !isPending) {
          continue;
        }

        dayBuckets[dayIndex].addEvent(
          _WidgetEvent(
            pichangaId: _toInt(item['id']),
            startsAt: localStart,
            isConfirmed: isConfirmed,
          ),
        );
      }
    }

    return {
      'generated_at': localNow.toIso8601String(),
      'is_logged_in': isLoggedIn,
      'monthly_played_count': monthlyPlayedCount,
      'header_title': headerTitle,
      'header_subtitle': headerSubtitle,
      'login_message': loginMessage,
      'days': dayBuckets.map((bucket) => bucket.toJson()).toList(),
    };
  }

  static Map<String, dynamic> buildLoggedOutPayload({DateTime? now}) {
    return buildPayload(
      const [],
      now: now,
      monthlyPlayedCount: 0,
      isLoggedIn: false,
    );
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
}

class _WidgetEvent {
  const _WidgetEvent({
    required this.pichangaId,
    required this.startsAt,
    required this.isConfirmed,
  });

  final int? pichangaId;
  final DateTime startsAt;
  final bool isConfirmed;
}

class _DayBucket {
  _DayBucket({required this.date});

  final DateTime date;
  bool hasConfirmed = false;
  bool hasPending = false;
  _WidgetEvent? selected;

  void addEvent(_WidgetEvent event) {
    if (event.isConfirmed) {
      hasConfirmed = true;
    } else {
      hasPending = true;
    }

    if (selected == null) {
      selected = event;
      return;
    }

    if (selected!.isConfirmed != event.isConfirmed) {
      if (event.isConfirmed) {
        selected = event;
      }
      return;
    }

    if (event.startsAt.isBefore(selected!.startsAt)) {
      selected = event;
    }
  }

  String get dayStatus {
    if (hasConfirmed) {
      return 'green';
    }
    if (hasPending) {
      return 'yellow';
    }
    return 'neutral';
  }

  Map<String, dynamic> toJson() {
    return {
      'date': _dateKey(date),
      'weekday_short': _weekdayShortEs(date.weekday),
      'day_number': date.day.toString(),
      'status': dayStatus,
      'pichanga_id': selected?.pichangaId,
      'time': selected != null ? _hhmm(selected!.startsAt) : null,
    };
  }

  String _dateKey(DateTime value) {
    final y = value.year.toString().padLeft(4, '0');
    final m = value.month.toString().padLeft(2, '0');
    final d = value.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  String _hhmm(DateTime value) {
    final h = value.hour.toString().padLeft(2, '0');
    final m = value.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _weekdayShortEs(int weekday) {
    const map = <int, String>{
      DateTime.monday: 'Lun',
      DateTime.tuesday: 'Mar',
      DateTime.wednesday: 'Mié',
      DateTime.thursday: 'Jue',
      DateTime.friday: 'Vie',
      DateTime.saturday: 'Sáb',
      DateTime.sunday: 'Dom',
    };
    return map[weekday] ?? '';
  }
}
