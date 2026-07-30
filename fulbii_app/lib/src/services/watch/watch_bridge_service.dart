import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

class WatchBridgeService {
  static const MethodChannel _channel = MethodChannel('fulbii/watch_bridge');

  Future<bool> pushAuthContext({
    required int userId,
    required String token,
    List<Map<String, dynamic>> confirmedMatches = const [],
    List<Map<String, dynamic>> pendingMatches = const [],
    String? userNick,
    String? userName,
    String? apiBaseUrl,
  }) async {
    try {
      await _channel.invokeMethod<void>('setWatchAuthContext', {
        'user_id': userId,
        'auth_token': token,
        'confirmed_matches': confirmedMatches,
        'pending_matches': pendingMatches,
        // Backward-compatible alias for older watch builds.
        'upcoming_matches': confirmedMatches,
        'user_nick': userNick,
        'user_name': userName,
        'api_base_url': apiBaseUrl,
      });
      return true;
    } on MissingPluginException {
      debugPrint(
        '[WatchBridge] Channel no disponible aún al enviar auth context',
      );
      return false;
    } on PlatformException {
      debugPrint('[WatchBridge] PlatformException al enviar auth context');
      return false;
    }
  }

  Future<bool> clearAuthContext() async {
    try {
      await _channel.invokeMethod<void>('clearWatchAuthContext');
      return true;
    } on MissingPluginException {
      debugPrint(
        '[WatchBridge] Channel no disponible aún al limpiar auth context',
      );
      return false;
    } on PlatformException {
      debugPrint('[WatchBridge] PlatformException al limpiar auth context');
      return false;
    }
  }
}

final watchBridgeServiceProvider = Provider<WatchBridgeService>(
  (_) => WatchBridgeService(),
);
