import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';

class ClubsRepository {
  ClubsRepository(this._api);

  final ApiClient _api;

  Future<List<Map<String, dynamic>>> listClubs({
    String scope = 'mine',
    String q = '',
  }) async {
    final response = await _api.getMap(
      '/clubs',
      queryParameters: {'scope': scope, 'q': q},
    );

    final items = response['items'] is List ? response['items'] as List : [];
    return items
        .whereType<Map>()
        .map((item) => item.cast<String, dynamic>())
        .toList();
  }

  Future<Map<String, dynamic>> createClub(Map<String, dynamic> payload) {
    return _api.postMap('/clubs', data: payload);
  }

  Future<Map<String, dynamic>> clubDetail(int clubId) {
    return _api.getMap('/clubs/$clubId');
  }

  Future<List<Map<String, dynamic>>> members(int clubId) async {
    final response = await _api.getMap('/clubs/$clubId/members');
    final items = response['items'] is List ? response['items'] as List : [];
    return items
        .whereType<Map>()
        .map((item) => item.cast<String, dynamic>())
        .toList();
  }

  Future<Map<String, dynamic>> updateClub(
    int clubId,
    Map<String, dynamic> body,
  ) {
    return _api.putMap('/clubs/$clubId', data: body);
  }

  Future<Map<String, dynamic>> setMemberRole(
    int clubId,
    int userId,
    String role,
  ) {
    return _api.putMap(
      '/clubs/$clubId/members/$userId/role',
      data: {'rol': role},
    );
  }

  Future<void> removeMember(int clubId, int userId) async {
    await _api.deleteMap('/clubs/$clubId/members/$userId');
  }

  Future<Map<String, dynamic>> inviteByNickOrEmail(
    int clubId, {
    String? nick,
    String? email,
  }) {
    return _api.postMap(
      '/clubs/$clubId/invitations',
      data: {'nick': nick, 'email': email},
    );
  }

  Future<List<Map<String, dynamic>>> myInvitations() async {
    final response = await _api.getMap('/invitations');
    final items = response['items'] is List ? response['items'] as List : [];
    return items
        .whereType<Map>()
        .map((item) => item.cast<String, dynamic>())
        .toList();
  }

  Future<void> respondInvitation(int invitationId, String action) async {
    await _api.postMap(
      '/invitations/$invitationId/respond',
      data: {'action': action},
    );
  }

  Future<Map<String, dynamic>> notificationPreference(int clubId) {
    return _api.getMap('/clubs/$clubId/notification-preference');
  }

  Future<Map<String, dynamic>> setNotificationPreference(
    int clubId,
    String mode,
  ) {
    return _api.putMap(
      '/clubs/$clubId/notification-preference',
      data: {'mode': mode},
    );
  }

  Future<Map<String, dynamic>> joinPreviewByCode(String joinCode) {
    return _api.getMap('/clubs/join/$joinCode');
  }

  Future<Map<String, dynamic>> requestJoinByCode(String joinCode) {
    return _api.postMap('/clubs/join/$joinCode/request');
  }

  Future<Map<String, dynamic>> requestJoinBySearch(int clubId) {
    return _api.postMap('/clubs/$clubId/join-requests');
  }

  Future<List<Map<String, dynamic>>> joinRequests(
    int clubId, {
    String status = 'pending',
  }) async {
    final response = await _api.getMap(
      '/clubs/$clubId/join-requests',
      queryParameters: {'status': status},
    );
    final items = response['items'] is List ? response['items'] as List : [];
    return items
        .whereType<Map>()
        .map((item) => item.cast<String, dynamic>())
        .toList();
  }

  Future<Map<String, dynamic>> decideJoinRequest(
    int clubId,
    int requestId, {
    required String action,
    String? note,
  }) {
    return _api.postMap(
      '/clubs/$clubId/join-requests/$requestId/decision',
      data: {'action': action, 'note': note},
    );
  }

  Future<Map<String, dynamic>> cancelJoinRequest(int clubId, int requestId) {
    return _api.postMap('/clubs/$clubId/join-requests/$requestId/cancel');
  }

  Future<Map<String, dynamic>> rotateJoinCode(int clubId) {
    return _api.postMap('/clubs/$clubId/join-code/rotate');
  }
}

final clubsRepositoryProvider = Provider<ClubsRepository>((ref) {
  final api = ref.watch(apiClientProvider);
  return ClubsRepository(api);
});
