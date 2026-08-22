import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';

class ChampionshipsRepository {
  ChampionshipsRepository(this._api);

  final ApiClient _api;

  Future<List<Map<String, dynamic>>> list() async {
    final response = await _api.getMap('/championships');
    final items = response['items'] is List ? response['items'] as List : [];
    return items
        .whereType<Map>()
        .map((item) => item.cast<String, dynamic>())
        .toList();
  }

  Future<Map<String, dynamic>> detail(int championshipId) async {
    final response = await _api.getMap('/championships/$championshipId');
    return (response['championship'] as Map?)?.cast<String, dynamic>() ?? {};
  }

  Future<List<Map<String, dynamic>>> standings(int championshipId) async {
    final response = await _api.getMap(
      '/championships/$championshipId/standings',
    );
    final items = response['items'] is List ? response['items'] as List : [];
    return items
        .whereType<Map>()
        .map((item) => item.cast<String, dynamic>())
        .toList();
  }

  Future<List<Map<String, dynamic>>> fixture(int championshipId) async {
    final response = await _api.getMap(
      '/championships/$championshipId/fixture',
    );
    final items = response['items'] is List ? response['items'] as List : [];
    return items
        .whereType<Map>()
        .map((item) => item.cast<String, dynamic>())
        .toList();
  }

  Future<List<Map<String, dynamic>>> playerStats(int championshipId) async {
    final response = await _api.getMap(
      '/championships/$championshipId/player-stats',
    );
    final items = response['items'] is List ? response['items'] as List : [];
    return items
        .whereType<Map>()
        .map((item) => item.cast<String, dynamic>())
        .toList();
  }

  Future<List<Map<String, dynamic>>> teamMembers(int teamId) async {
    final response = await _api.getMap('/championship-teams/$teamId/members');
    final items = response['items'] is List ? response['items'] as List : [];
    return items
        .whereType<Map>()
        .map((item) => item.cast<String, dynamic>())
        .toList();
  }

  Future<List<Map<String, dynamic>>> teamInvitations(int teamId) async {
    final response = await _api.getMap(
      '/championship-teams/$teamId/invitations',
    );
    final items = response['items'] is List ? response['items'] as List : [];
    return items
        .whereType<Map>()
        .map((item) => item.cast<String, dynamic>())
        .toList();
  }

  Future<Map<String, dynamic>> inviteTeamMember(
    int teamId, {
    required String nick,
  }) {
    return _api.postMap(
      '/championship-teams/$teamId/members/invite',
      data: {'nick': nick.trim()},
    );
  }

  Future<Map<String, dynamic>> removeTeamMember(int teamId, int userId) {
    return _api.deleteMap('/championship-teams/$teamId/members/$userId');
  }

  Future<Map<String, dynamic>> setCaptain(int teamId, int userId) {
    return _api.postMap(
      '/championship-teams/$teamId/captain',
      data: {'user_id': userId},
    );
  }

  Future<Map<String, dynamic>> respondInvitation(
    int invitationId, {
    required bool accept,
  }) {
    return _api.postMap(
      '/championship-team-invitations/$invitationId/respond',
      data: {'decision': accept ? 'accept' : 'reject'},
    );
  }

  Future<List<Map<String, dynamic>>> myInvitations() async {
    final response = await _api.getMap('/me/championship-invitations');
    final items = response['items'] is List ? response['items'] as List : [];
    return items
        .whereType<Map>()
        .map((item) => item.cast<String, dynamic>())
        .toList();
  }
}

final championshipsRepositoryProvider = Provider<ChampionshipsRepository>((
  ref,
) {
  return ChampionshipsRepository(ref.watch(apiClientProvider));
});
