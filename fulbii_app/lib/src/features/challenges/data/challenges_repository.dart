import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';

class ChallengesRepository {
  ChallengesRepository(this._api);

  final ApiClient _api;

  Future<List<Map<String, dynamic>>> mine({String status = 'active'}) async {
    final response = await _api.getMap(
      '/challenges',
      queryParameters: {'status': status},
    );
    final items = response['items'] is List ? response['items'] as List : [];
    return items
        .whereType<Map>()
        .map((item) => item.cast<String, dynamic>())
        .toList();
  }

  Future<List<Map<String, dynamic>>> byClub(
    int clubId, {
    String status = 'active',
  }) async {
    final response = await _api.getMap(
      '/clubs/$clubId/challenges',
      queryParameters: {'status': status},
    );
    final items = response['items'] is List ? response['items'] as List : [];
    return items
        .whereType<Map>()
        .map((item) => item.cast<String, dynamic>())
        .toList();
  }

  Future<Map<String, dynamic>> create({
    required int fromClubId,
    required int challengedClubId,
    required int teamSize,
    required String challengeWindow,
    String? requestedNote,
  }) {
    return _api.postMap(
      '/clubs/$fromClubId/challenges',
      data: {
        'challenged_club_id': challengedClubId,
        'team_size': teamSize,
        'challenge_window': challengeWindow,
        'requested_note': requestedNote,
      },
    );
  }

  Future<Map<String, dynamic>> detail(int challengeId) {
    return _api.getMap('/challenges/$challengeId');
  }

  Future<void> coordinate(int challengeId) async {
    await _api.postMap('/challenges/$challengeId/coordinate');
  }

  Future<void> reject(int challengeId, {String? reason}) async {
    await _api.postMap(
      '/challenges/$challengeId/reject',
      data: {'reason': reason},
    );
  }

  Future<void> cancel(int challengeId, {String? reason}) async {
    await _api.postMap(
      '/challenges/$challengeId/cancel',
      data: {'reason': reason},
    );
  }

  Future<List<Map<String, dynamic>>> messages(
    int challengeId, {
    int limit = 120,
  }) async {
    final response = await _api.getMap(
      '/challenges/$challengeId/messages',
      queryParameters: {'limit': limit},
    );
    final items = response['items'] is List ? response['items'] as List : [];
    return items
        .whereType<Map>()
        .map((item) => item.cast<String, dynamic>())
        .toList();
  }

  Future<Map<String, dynamic>> sendMessage(
    int challengeId,
    String content,
  ) async {
    return _api.postMap(
      '/challenges/$challengeId/messages',
      data: {'content': content},
    );
  }

  Future<List<Map<String, dynamic>>> configurations(int challengeId) async {
    final response = await _api.getMap('/challenges/$challengeId/configurations');
    final items = response['items'] is List ? response['items'] as List : [];
    return items
        .whereType<Map>()
        .map((item) => item.cast<String, dynamic>())
        .toList();
  }

  Future<Map<String, dynamic>> proposeConfiguration(
    int challengeId, {
    required int fieldOptionId,
    required int timeOptionId,
    required bool invitedLinkEnabled,
  }) {
    return _api.postMap(
      '/challenges/$challengeId/configurations/propose',
      data: {
        'field_option_id': fieldOptionId,
        'time_option_id': timeOptionId,
        'invited_link_enabled': invitedLinkEnabled,
      },
    );
  }

  Future<Map<String, dynamic>> decideConfiguration(
    int challengeId,
    int configurationId, {
    required String action,
    String? reason,
    bool? invitedLinkEnabled,
  }) {
    return _api.postMap(
      '/challenges/$challengeId/configurations/$configurationId/decision',
      data: {
        'action': action,
        'reason': reason,
        'invited_link_enabled': invitedLinkEnabled,
      },
    );
  }

  Future<Map<String, dynamic>> proposeFieldOption(
    int challengeId, {
    int? polideportivoId,
    String? fieldName,
    String? fieldAddress,
    double? latitude,
    double? longitude,
  }) {
    return _api.postMap(
      '/challenges/$challengeId/field-options',
      data: {
        'polideportivo_id': polideportivoId,
        'field_name': fieldName,
        'field_address': fieldAddress,
        'latitude': latitude,
        'longitude': longitude,
      },
    );
  }

  Future<Map<String, dynamic>> proposeTimeOption(
    int challengeId, {
    required DateTime startsAt,
    required int durationMinutes,
  }) {
    return _api.postMap(
      '/challenges/$challengeId/time-options',
      data: {
        'starts_at': startsAt.toIso8601String(),
        'duration_minutes': durationMinutes,
      },
    );
  }

  Future<void> updateChatPresence({
    required bool isActive,
    int? challengeId,
  }) async {
    await _api.putMap(
      '/me/presence/chat',
      data: {
        'is_active': isActive,
        'challenge_id': challengeId,
        'updated_at_client': DateTime.now().toIso8601String(),
      },
    );
  }
}

final challengesRepositoryProvider = Provider<ChallengesRepository>((ref) {
  final api = ref.watch(apiClientProvider);
  return ChallengesRepository(api);
});

