import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';

class PichangasAvailableResponse {
  const PichangasAvailableResponse({
    required this.items,
    required this.monthlyPlayedCount,
  });

  final List<Map<String, dynamic>> items;
  final int monthlyPlayedCount;
}

class PichangasRepository {
  PichangasRepository(this._api);

  final ApiClient _api;

  Future<PichangasAvailableResponse> availableWithMeta({int? days}) async {
    final queryParameters = <String, dynamic>{};
    if (days != null && days > 0) {
      queryParameters['days'] = days;
    }

    final response = await _api.getMap(
      '/pichangas/available',
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
    );
    final itemsRaw = response['items'] is List ? response['items'] as List : [];
    final items = itemsRaw
        .whereType<Map>()
        .map((item) => item.cast<String, dynamic>())
        .toList();

    final meta = response['meta'] is Map
        ? (response['meta'] as Map).cast<String, dynamic>()
        : const <String, dynamic>{};

    final monthlyPlayedCount = switch (meta['monthly_played_count']) {
      int value => value,
      String value => int.tryParse(value) ?? 0,
      _ => 0,
    };

    return PichangasAvailableResponse(
      items: items,
      monthlyPlayedCount: monthlyPlayedCount,
    );
  }

  Future<List<Map<String, dynamic>>> available({int? days}) async {
    return (await availableWithMeta(days: days)).items;
  }

  Future<Map<String, dynamic>> myBoard({
    int days = 7,
    int terminatedLimit = 200,
    int page = 1,
  }) {
    final safeDays = days <= 0 ? 7 : days;
    final safeLimit = terminatedLimit <= 0 ? 200 : terminatedLimit;
    final safePage = page <= 0 ? 1 : page;
    return _api.getMap(
      '/pichangas/my-board',
      queryParameters: {
        'days': safeDays,
        'terminated_limit': safeLimit,
        'page': safePage,
      },
    );
  }

  Future<List<Map<String, dynamic>>> confirmedNextWidget({
    int limit = 3,
  }) async {
    final safeLimit = limit <= 0 ? 3 : limit;
    final response = await _api.getMap(
      '/pichangas/widget/confirmed-next',
      queryParameters: {'limit': safeLimit},
    );
    final items = response['items'] is List ? response['items'] as List : [];
    return items
        .whereType<Map>()
        .map((item) => item.cast<String, dynamic>())
        .toList();
  }

  Future<Map<String, dynamic>> watchHomeFeed({int days = 7}) {
    final safeDays = days <= 0 ? 7 : days;
    return _api.getMap(
      '/watch/pichangas/home-feed',
      queryParameters: {'days': safeDays},
    );
  }

  Future<List<Map<String, dynamic>>> pichangaHistory({int limit = 50}) async {
    final safeLimit = limit <= 0 ? 50 : limit;
    final response = await _api.getMap(
      '/me/pichangas/history',
      queryParameters: {'limit': safeLimit},
    );
    final items = response['items'] is List ? response['items'] as List : [];
    return items
        .whereType<Map>()
        .map((item) => item.cast<String, dynamic>())
        .toList();
  }

  Future<List<Map<String, dynamic>>> byClub(int clubId) async {
    final response = await _api.getMap('/clubs/$clubId/pichangas');
    final items = response['items'] is List ? response['items'] as List : [];
    return items
        .whereType<Map>()
        .map((item) => item.cast<String, dynamic>())
        .toList();
  }

  Future<Map<String, dynamic>> create(
    int clubId,
    Map<String, dynamic> payload,
  ) {
    return _api.postMap('/clubs/$clubId/pichangas', data: payload);
  }

  Future<Map<String, dynamic>> detail(int pichangaId) {
    return _api.getMap('/pichangas/$pichangaId');
  }

  Future<Map<String, dynamic>> watchActiveSession() {
    return _api.getMap('/watch/match-sessions/my-active');
  }

  Future<List<Map<String, dynamic>>> watchSessionsByPichangaMe(
    int pichangaId,
  ) async {
    final response = await _api.getMap(
      '/watch/pichangas/$pichangaId/sessions/me',
    );
    final items = response['items'] is List ? response['items'] as List : [];
    return items
        .whereType<Map>()
        .map((item) => item.cast<String, dynamic>())
        .toList();
  }

  Future<Map<String, dynamic>> watchHeatmapByPichangaMe(int pichangaId) {
    return _api.getMap('/watch/pichangas/$pichangaId/heatmap/me');
  }

  Future<Map<String, dynamic>> simulateWatchSessionForPichanga(
    int pichangaId,
  ) async {
    final now = DateTime.now().toUtc();
    final start = now.subtract(const Duration(minutes: 30));

    final storeResponse = await _api.postMap(
      '/watch/match-sessions',
      data: {
        'group_pichanga_id': pichangaId,
        'start_time': start.toIso8601String(),
        'status': 'live',
        'device': 'watchos',
        'source': 'simulated',
      },
    );
    final session =
        (storeResponse['session'] as Map?)?.cast<String, dynamic>() ?? {};
    final sessionId = int.tryParse(session['id'].toString()) ?? 0;
    if (sessionId <= 0) {
      throw Exception('No se pudo crear sesión simulada watch.');
    }

    final samples = List.generate(120, (index) {
      final ratio = index / 119.0;
      final lat = -12.0464 + (0.0002 * math.sin(ratio * 12));
      final lng = -77.0428 + (0.0002 * math.cos(ratio * 12));
      return {
        'timestamp': start.add(Duration(seconds: index * 15)).toIso8601String(),
        'lat': lat,
        'lng': lng,
        'horizontalAccuracy': 8.0,
        'speed': 2.2,
      };
    });

    await _api.postMap(
      '/watch/match-sessions/$sessionId/samples/batch',
      data: {'samples': samples},
    );

    await _api.postMap(
      '/watch/match-sessions/$sessionId/events/batch',
      data: {
        'events': [
          {
            'type': 'goal',
            'timestamp': start
                .add(const Duration(minutes: 9))
                .toIso8601String(),
            'minute': 10,
            'clockTime': '20:09',
          },
          {
            'type': 'assist',
            'timestamp': start
                .add(const Duration(minutes: 19))
                .toIso8601String(),
            'minute': 20,
            'clockTime': '20:19',
          },
        ],
      },
    );

    await _api.postMap(
      '/watch/match-sessions/$sessionId/finish',
      data: {
        'end_time': now.toIso8601String(),
        'status': 'finished',
        'distance_meters': 4200,
      },
    );

    return _api.getMap('/watch/pichangas/$pichangaId/heatmap/me');
  }

  Future<void> confirm(int pichangaId, String teamCode) async {
    await _api.postMap(
      '/pichangas/$pichangaId/confirm',
      data: {'team_code': teamCode},
    );
  }

  Future<void> withdraw(int pichangaId) async {
    await _api.postMap('/pichangas/$pichangaId/withdraw');
  }

  Future<void> externalRequest(int pichangaId) async {
    await _api.postMap('/pichangas/$pichangaId/external-requests');
  }

  Future<List<Map<String, dynamic>>> externalRequests(int pichangaId) async {
    final response = await _api.getMap(
      '/pichangas/$pichangaId/external-requests',
    );
    final items = response['items'] is List ? response['items'] as List : [];
    return items
        .whereType<Map>()
        .map((item) => item.cast<String, dynamic>())
        .toList();
  }

  Future<void> decideExternalRequest(
    int pichangaId,
    int requestId,
    String action, {
    String? note,
  }) async {
    await _api.postMap(
      '/pichangas/$pichangaId/external-requests/$requestId/decision',
      data: {'action': action, 'note': note},
    );
  }

  Future<Map<String, dynamic>> updateAudience(
    int pichangaId,
    Map<String, dynamic> body,
  ) {
    return _api.putMap('/pichangas/$pichangaId/audience', data: body);
  }

  Future<Map<String, dynamic>> renotifyPreview(
    int pichangaId,
    Map<String, dynamic> body,
  ) {
    return _api.postMap('/pichangas/$pichangaId/renotify/preview', data: body);
  }

  Future<Map<String, dynamic>> renotifySend(
    int pichangaId,
    Map<String, dynamic> body,
  ) {
    return _api.postMap('/pichangas/$pichangaId/renotify/send', data: body);
  }

  Future<List<Map<String, dynamic>>> feed(int pichangaId) async {
    final response = await _api.getMap('/pichangas/$pichangaId/feed');
    final items = response['items'] is List ? response['items'] as List : [];
    return items
        .whereType<Map>()
        .map((item) => item.cast<String, dynamic>())
        .toList();
  }

  Future<void> addTextPost(int pichangaId, String content) async {
    await _api.postMap(
      '/pichangas/$pichangaId/feed/posts',
      data: {'post_type': 'text', 'content': content},
    );
  }

  Future<void> addPhotoPost(
    int pichangaId,
    String photoUrl, {
    String? content,
  }) async {
    await _api.postMap(
      '/pichangas/$pichangaId/feed/posts',
      data: {'post_type': 'photo', 'photo_url': photoUrl, 'content': content},
    );
  }

  Future<void> addComment(int pichangaId, int postId, String content) async {
    await _api.postMap(
      '/pichangas/$pichangaId/feed/posts/$postId/comments',
      data: {'content': content},
    );
  }

  Future<List<Map<String, dynamic>>> ratings(int pichangaId) async {
    final response = await _api.getMap('/pichangas/$pichangaId/ratings');
    final items = response['items'] is List ? response['items'] as List : [];
    return items
        .whereType<Map>()
        .map((item) => item.cast<String, dynamic>())
        .toList();
  }

  Future<void> addOrUpdateRating(
    int pichangaId, {
    required int ratedUserId,
    required double fisico,
    required double arquero,
    required double delantero,
    required double mediocampo,
    required double defensa,
    String? comentario,
  }) async {
    await _api.postMap(
      '/pichangas/$pichangaId/ratings',
      data: {
        'rated_user_id': ratedUserId,
        'fisico': double.parse(fisico.toStringAsFixed(1)),
        'arquero': double.parse(arquero.toStringAsFixed(1)),
        'delantero': double.parse(delantero.toStringAsFixed(1)),
        'mediocampo': double.parse(mediocampo.toStringAsFixed(1)),
        'defensa': double.parse(defensa.toStringAsFixed(1)),
        'comentario': comentario,
      },
    );
  }
}

final pichangasRepositoryProvider = Provider<PichangasRepository>((ref) {
  final api = ref.watch(apiClientProvider);
  return PichangasRepository(api);
});
