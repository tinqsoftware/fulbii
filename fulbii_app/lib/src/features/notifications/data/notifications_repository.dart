import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';

class NotificationsRepository {
  NotificationsRepository(this._api);

  final ApiClient _api;

  Future<List<Map<String, dynamic>>> inbox({int limit = 50}) async {
    final response = await _api.getMap(
      '/me/notifications',
      queryParameters: {'limit': limit},
    );
    final items = response['items'] is List ? response['items'] as List : [];
    return items
        .whereType<Map>()
        .map((item) => item.cast<String, dynamic>())
        .toList();
  }

  Future<int> unreadCount() async {
    final response = await _api.getMap(
      '/me/notifications',
      queryParameters: {'limit': 1},
    );
    return int.tryParse((response['unread_count'] ?? 0).toString()) ?? 0;
  }

  Future<void> markRead(int notificationId) async {
    await _api.postMap('/me/notifications/$notificationId/read');
  }

  Future<void> markAllRead() async {
    await _api.postMap('/me/notifications/read-all');
  }

  Future<void> registerDevice({
    required String platform,
    required String token,
    String? appVersion,
    String? deviceName,
  }) async {
    await _api.postMap(
      '/me/devices/register',
      data: {
        'platform': platform,
        'device_token': token,
        'device_name': deviceName,
        'app_version': appVersion,
      },
    );
  }
}

final notificationsRepositoryProvider = Provider<NotificationsRepository>((
  ref,
) {
  final api = ref.watch(apiClientProvider);
  return NotificationsRepository(api);
});
