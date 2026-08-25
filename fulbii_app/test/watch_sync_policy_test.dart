import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fulbii_app/src/core/models/app_user.dart';
import 'package:fulbii_app/src/features/auth/session_state.dart';
import 'package:fulbii_app/src/services/watch/watch_sync_policy.dart';

void main() {
  const user = AppUser(id: 42, name: 'Jugador', email: 'jugador@example.com');

  test('Android never syncs Watch during onboarding', () {
    final policy = WatchSyncPolicy(platform: TargetPlatform.android);
    const session = SessionState(
      initialized: true,
      token: 'token',
      user: user,
      needsOnboarding: true,
    );

    expect(policy.shouldSync(session), isFalse);
    expect(policy.retryDelay(0), isNull);
  });

  test('iOS syncs only after onboarding is complete', () {
    final policy = WatchSyncPolicy(platform: TargetPlatform.iOS);
    const onboarding = SessionState(
      initialized: true,
      token: 'token',
      user: user,
      needsOnboarding: true,
    );
    const complete = SessionState(
      initialized: true,
      token: 'token',
      user: user,
      needsOnboarding: false,
    );

    expect(policy.shouldSync(onboarding), isFalse);
    expect(policy.shouldSync(complete), isTrue);
  });

  test('iOS retry schedule is bounded and progressive', () {
    final policy = WatchSyncPolicy(platform: TargetPlatform.iOS);

    expect(policy.retryDelay(0), const Duration(seconds: 2));
    expect(policy.retryDelay(1), const Duration(seconds: 5));
    expect(policy.retryDelay(2), const Duration(seconds: 15));
    expect(policy.retryDelay(3), isNull);
  });
}
