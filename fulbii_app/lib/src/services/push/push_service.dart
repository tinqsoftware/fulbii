import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/notifications/data/notifications_repository.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {
    // ignored
  }
}

class PushService {
  PushService(this._repository);

  final NotificationsRepository _repository;

  StreamSubscription<String>? _tokenRefreshSub;
  StreamSubscription<RemoteMessage>? _openedSub;
  StreamSubscription<RemoteMessage>? _messageSub;
  bool _initialized = false;

  Future<void> initialize({
    required void Function(int pichangaId) onOpenPichanga,
    required void Function(int challengeId) onOpenChallenge,
    void Function(String title, String body, Map<String, dynamic> data)?
    onForegroundNotification,
  }) async {
    if (_initialized) {
      return;
    }

    try {
      await Firebase.initializeApp();
    } catch (_) {
      debugPrint('Firebase no está configurado todavía.');
      return;
    }

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    final messaging = FirebaseMessaging.instance;
    final permission = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    debugPrint(
      'Push permission => status=${permission.authorizationStatus.name} '
      'alert=${permission.alert} badge=${permission.badge} sound=${permission.sound}',
    );

    if (Platform.isIOS) {
      String? apnsToken = await messaging.getAPNSToken();
      if (apnsToken == null || apnsToken.isEmpty) {
        // iOS APNs token may take a short time after first permission grant.
        await Future<void>.delayed(const Duration(seconds: 2));
        apnsToken = await messaging.getAPNSToken();
      }
      debugPrint(
        'APNs token present => ${apnsToken != null && apnsToken.isNotEmpty}',
      );
    }

    String? token = await messaging.getToken();
    if (token == null || token.isEmpty) {
      await Future<void>.delayed(const Duration(seconds: 2));
      token = await messaging.getToken();
    }
    debugPrint('FCM token present => ${token != null && token.isNotEmpty}');
    if (token != null && token.isNotEmpty) {
      await _registerToken(token);
    }

    _tokenRefreshSub = messaging.onTokenRefresh.listen((token) async {
      await _registerToken(token);
    });

    _openedSub = FirebaseMessaging.onMessageOpenedApp.listen((message) {
      final challengeId = int.tryParse(
        (message.data['challenge_id'] ?? '').toString(),
      );
      if (challengeId != null) {
        onOpenChallenge(challengeId);
        return;
      }

      final pichangaId = int.tryParse(
        (message.data['pichanga_id'] ?? '').toString(),
      );
      if (pichangaId != null) {
        onOpenPichanga(pichangaId);
      }
    });

    _messageSub = FirebaseMessaging.onMessage.listen((message) {
      if (onForegroundNotification == null) {
        return;
      }
      final data = Map<String, dynamic>.from(message.data);
      final title = message.notification?.title ?? 'Nueva notificación';
      final body = message.notification?.body ?? '';
      onForegroundNotification(title, body, data);
    });

    final initial = await messaging.getInitialMessage();
    if (initial != null) {
      final challengeId = int.tryParse(
        (initial.data['challenge_id'] ?? '').toString(),
      );
      if (challengeId != null) {
        onOpenChallenge(challengeId);
      } else {
        final pichangaId = int.tryParse(
          (initial.data['pichanga_id'] ?? '').toString(),
        );
        if (pichangaId != null) {
          onOpenPichanga(pichangaId);
        }
      }
    }

    _initialized = true;
  }

  Future<void> dispose() async {
    await _tokenRefreshSub?.cancel();
    await _openedSub?.cancel();
    await _messageSub?.cancel();
    _tokenRefreshSub = null;
    _openedSub = null;
    _messageSub = null;
    _initialized = false;
  }

  Future<void> _registerToken(String token) async {
    final platform = Platform.isIOS ? 'ios' : 'android';
    try {
      await _repository.registerDevice(
        platform: platform,
        token: token,
        appVersion: '1.0.0',
        deviceName: '$platform-device',
      );
      debugPrint('Device token registered successfully => platform=$platform');
    } catch (error) {
      debugPrint('Device token register failed => $error');
    }
  }
}

final pushServiceProvider = Provider<PushService>((ref) {
  final repo = ref.watch(notificationsRepositoryProvider);
  return PushService(repo);
});
