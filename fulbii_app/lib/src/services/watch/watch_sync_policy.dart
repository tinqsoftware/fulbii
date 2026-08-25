import 'package:flutter/foundation.dart';

import '../../features/auth/session_state.dart';

/// Keeps Apple Watch synchronization isolated from unsupported platforms and
/// prevents a native-channel failure from becoming an API request loop.
class WatchSyncPolicy {
  WatchSyncPolicy({TargetPlatform? platform})
    : platform = platform ?? defaultTargetPlatform;

  final TargetPlatform platform;

  bool get isSupported => platform == TargetPlatform.iOS;

  bool shouldSync(SessionState session) {
    final user = session.user;
    return isSupported &&
        session.isAuthenticated &&
        !session.needsOnboarding &&
        session.token != null &&
        session.token!.isNotEmpty &&
        user != null &&
        user.id > 0;
  }

  Duration? retryDelay(int attempt) {
    if (!isSupported) return null;
    return switch (attempt) {
      0 => const Duration(seconds: 2),
      1 => const Duration(seconds: 5),
      2 => const Duration(seconds: 15),
      _ => null,
    };
  }
}
