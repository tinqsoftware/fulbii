import 'dart:async';
import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'config/app_config.dart';
import 'features/auth/presentation/onboarding_screen.dart';
import 'features/auth/session_controller.dart';
import 'features/auth/session_state.dart';
import 'features/clubs/presentation/join_club_by_link_screen.dart';
import 'features/clubs/presentation/club_detail_screen.dart';
import 'features/home/main_shell.dart';
import 'features/pichangas/presentation/pichanga_detail_screen.dart';
import 'features/pichangas/presentation/pichanga_widget_share_screen.dart';
import 'features/pichangas/data/pichangas_repository.dart';
import 'services/deep_links/deep_link_service.dart';
import 'services/watch/watch_bridge_service.dart';
import 'services/widget/widget_weekly_service.dart';
import 'core/theme/theme_controller.dart';

final appNavigatorKeyProvider = Provider<GlobalKey<NavigatorState>>(
  (_) => GlobalKey<NavigatorState>(),
);

class FulbiiApp extends ConsumerStatefulWidget {
  const FulbiiApp({super.key});

  @override
  ConsumerState<FulbiiApp> createState() => _FulbiiAppState();
}

class _FulbiiAppState extends ConsumerState<FulbiiApp>
    with WidgetsBindingObserver {
  bool _deepLinksInitialized = false;
  bool _openingJoin = false;
  bool _openingPichanga = false;
  bool _openingClub = false;
  bool _openingWidgetShare = false;
  bool _openingPichangasScreen = false;
  String? _lastWatchToken;
  int? _lastWatchUserId;
  bool _watchSyncInFlight = false;
  bool _pendingWatchSync = false;
  bool _pendingWatchClear = false;
  List<Map<String, dynamic>> _lastWatchConfirmedMatches = const [];
  List<Map<String, dynamic>> _lastWatchPendingMatches = const [];
  String? _pendingJoinCode;
  int? _pendingPichangaId;
  int? _pendingClubId;
  WidgetDeepLinkAction? _pendingWidgetAction;
  bool _pendingOpenPichangas = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncWatchAuth(ref.read(sessionControllerProvider), force: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionControllerProvider);
    final themeMode = ref.watch(themeModeProvider);
    final navigatorKey = ref.watch(appNavigatorKeyProvider);
    _syncWatchAuth(session);

    if (!_deepLinksInitialized) {
      _deepLinksInitialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(deepLinkServiceProvider)
            .initialize(
              onJoinCode: _handleJoinCode,
              onClubId: _handleClubLink,
              onPichangaId: _handlePichangaLink,
              onWidgetAction: _handleWidgetAction,
              onOpenPichangas: _handleOpenPichangas,
            );
      });
    }

    if (_pendingJoinCode != null &&
        !_openingJoin &&
        session.initialized &&
        session.isAuthenticated &&
        !session.needsOnboarding) {
      final code = _pendingJoinCode!;
      _pendingJoinCode = null;
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _openJoinScreen(code),
      );
    }

    if (_pendingPichangaId != null &&
        !_openingPichanga &&
        session.initialized &&
        session.isAuthenticated &&
        !session.needsOnboarding) {
      final pichangaId = _pendingPichangaId!;
      _pendingPichangaId = null;
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _openPichangaDetail(pichangaId),
      );
    }

    if (_pendingClubId != null &&
        !_openingClub &&
        session.initialized &&
        !session.needsOnboarding) {
      final clubId = _pendingClubId!;
      _pendingClubId = null;
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _openClubDetail(clubId),
      );
    }

    if (_pendingWidgetAction != null &&
        !_openingWidgetShare &&
        session.initialized &&
        session.isAuthenticated &&
        !session.needsOnboarding) {
      final action = _pendingWidgetAction!;
      _pendingWidgetAction = null;
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _openWidgetAction(action),
      );
    }

    if (_pendingOpenPichangas &&
        !_openingPichangasScreen &&
        session.initialized &&
        session.isAuthenticated &&
        !session.needsOnboarding) {
      _pendingOpenPichangas = false;
      WidgetsBinding.instance.addPostFrameCallback((_) => _openPichangas());
    }

    return MaterialApp(
      title: 'Fulbii',
      debugShowCheckedModeBanner: false,
      locale: const Locale('es'),
      supportedLocales: const [Locale('es'), Locale('en')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      navigatorKey: navigatorKey,
      themeMode: themeMode,
      theme: _fulbiiTheme(Brightness.light),
      darkTheme: _fulbiiTheme(Brightness.dark),
      builder: (context, child) {
        final config = ref.watch(appConfigProvider);
        if (!kDebugMode || config.env != AppEnv.dev) {
          return child ?? const SizedBox.shrink();
        }
        return Stack(
          children: [
            child ?? const SizedBox.shrink(),
            const IgnorePointer(
              child: SafeArea(
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: Padding(
                    padding: EdgeInsets.only(right: 10, bottom: 10),
                    child: _DevelopmentEnvironmentBadge(),
                  ),
                ),
              ),
            ),
          ],
        );
      },
      home: Builder(
        builder: (context) {
          if (!session.initialized ||
              session.loading && !session.isAuthenticated) {
            return const _SplashScreen();
          }

          if (session.isAuthenticated && session.needsOnboarding) {
            return const OnboardingScreen();
          }

          return const MainShell();
        },
      ),
    );
  }

  void _syncWatchAuth(SessionState session, {bool force = false}) {
    if (session.isAuthenticated &&
        session.token != null &&
        session.user != null &&
        session.user!.id > 0) {
      final token = session.token!;
      final userId = session.user!.id;
      _pendingWatchClear = false;
      final alreadySynced =
          _lastWatchToken == token && _lastWatchUserId == userId;
      if (alreadySynced && !_pendingWatchSync && !force) {
        return;
      }
      if (_watchSyncInFlight) {
        return;
      }
      _pendingWatchSync = true;
      unawaited(
        _pushWatchContextAndTrack(
          userId: userId,
          token: token,
          userNick: session.user?.nick,
          userName: session.user?.name,
        ),
      );
      return;
    }

    final shouldClear =
        _lastWatchToken != null ||
        _lastWatchUserId != null ||
        _pendingWatchClear;
    if (!shouldClear) {
      return;
    }
    if (_watchSyncInFlight) {
      _pendingWatchClear = true;
      return;
    }
    _pendingWatchClear = true;
    unawaited(_clearWatchContextAndTrack());
  }

  Future<void> _pushWatchContextAndTrack({
    required int userId,
    required String token,
    String? userNick,
    String? userName,
  }) async {
    if (_watchSyncInFlight) {
      return;
    }
    _watchSyncInFlight = true;
    final success = await _pushWatchContext(
      userId: userId,
      token: token,
      userNick: userNick,
      userName: userName,
    );
    if (success) {
      _lastWatchToken = token;
      _lastWatchUserId = userId;
      _pendingWatchSync = false;
      debugPrint('[WatchBridge] Sync success user=$userId');
    } else {
      _pendingWatchSync = true;
      _scheduleWatchSyncRetry();
      debugPrint('[WatchBridge] Sync pending retry user=$userId');
    }
    _watchSyncInFlight = false;
  }

  Future<void> _clearWatchContextAndTrack() async {
    if (_watchSyncInFlight) {
      return;
    }
    _watchSyncInFlight = true;
    final success = await ref
        .read(watchBridgeServiceProvider)
        .clearAuthContext();
    if (success) {
      _lastWatchToken = null;
      _lastWatchUserId = null;
      _pendingWatchClear = false;
      _pendingWatchSync = false;
      _lastWatchConfirmedMatches = const [];
      _lastWatchPendingMatches = const [];
    } else {
      _pendingWatchClear = true;
      _scheduleWatchSyncRetry();
      debugPrint('[WatchBridge] Clear pending retry');
    }
    _watchSyncInFlight = false;
  }

  Future<bool> _pushWatchContext({
    required int userId,
    required String token,
    String? userNick,
    String? userName,
  }) async {
    final service = ref.read(watchBridgeServiceProvider);
    final repository = ref.read(pichangasRepositoryProvider);
    final appConfig = ref.read(appConfigProvider);
    var confirmedMatches = List<Map<String, dynamic>>.from(
      _lastWatchConfirmedMatches,
    );
    var pendingMatches = List<Map<String, dynamic>>.from(
      _lastWatchPendingMatches,
    );
    String? resolvedUserNick = userNick;
    String? resolvedUserName = userName;

    try {
      final feed = await repository.watchHomeFeed(days: 7);
      final confirmedRaw = feed['confirmed_matches'] is List
          ? feed['confirmed_matches'] as List
          : const [];
      final pendingRaw = feed['pending_matches'] is List
          ? feed['pending_matches'] as List
          : const [];
      confirmedMatches = confirmedRaw
          .whereType<Map>()
          .map((item) => item.cast<String, dynamic>())
          .map(_toWatchMatchPayload)
          .whereType<Map<String, dynamic>>()
          .toList(growable: false);
      pendingMatches = pendingRaw
          .whereType<Map>()
          .map((item) => item.cast<String, dynamic>())
          .map(_toWatchMatchPayload)
          .whereType<Map<String, dynamic>>()
          .toList(growable: false);
      if (confirmedMatches.isEmpty && _lastWatchConfirmedMatches.isNotEmpty) {
        // Avoid destructive fallback when backend feed is temporarily empty/inconsistent.
        confirmedMatches = List<Map<String, dynamic>>.from(
          _lastWatchConfirmedMatches,
        );
      }
      debugPrint(
        '[WatchBridge] Feed loaded confirmed=${confirmedMatches.length} pending=${pendingMatches.length}',
      );

      final userMap = feed['user'] is Map
          ? (feed['user'] as Map).cast<String, dynamic>()
          : const <String, dynamic>{};
      resolvedUserNick ??= _readString(userMap['nick']);
      resolvedUserName ??= _readString(userMap['name']);
    } catch (_) {
      // Preserve last valid confirmed list to avoid losing in-progress matches.
      debugPrint('[WatchBridge] home-feed failed, keeping last confirmed list');
    }

    if (confirmedMatches.isEmpty) {
      try {
        final nowUtc = DateTime.now().toUtc();
        final history = await repository.pichangaHistory(limit: 50);
        final historyConfirmed = history
            .where((item) => _shouldIncludeConfirmedForWatch(item, nowUtc))
            .map(_toWatchMatchPayload)
            .whereType<Map<String, dynamic>>()
            .toList(growable: false);
        if (historyConfirmed.isNotEmpty) {
          confirmedMatches = historyConfirmed;
          debugPrint(
            '[WatchBridge] fallback history confirmed=${confirmedMatches.length}',
          );
        }
      } catch (_) {
        debugPrint('[WatchBridge] history fallback failed');
      }
    }

    if (confirmedMatches.isEmpty && _lastWatchConfirmedMatches.isNotEmpty) {
      confirmedMatches = List<Map<String, dynamic>>.from(
        _lastWatchConfirmedMatches,
      );
      debugPrint(
        '[WatchBridge] using cached confirmed=${confirmedMatches.length}',
      );
    }

    try {
      final available = await repository.available(days: 7);
      final confirmedIds = confirmedMatches
          .map((item) => _toInt(item['id']))
          .whereType<int>()
          .toSet();
      final pendingFromAvailable = available
          .where((item) {
            final status = _readString(
              item['me_participant_status'],
            ).toLowerCase().trim();
            return status != 'confirmed';
          })
          .map(_toWatchMatchPayload)
          .whereType<Map<String, dynamic>>()
          .where((item) {
            final id = _toInt(item['id']);
            return id != null && !confirmedIds.contains(id);
          })
          .toList(growable: false);
      pendingMatches = pendingFromAvailable;
      debugPrint(
        '[WatchBridge] pending from available loaded=${pendingMatches.length}',
      );
    } catch (_) {
      debugPrint('[WatchBridge] pending available fetch failed');
    }

    _lastWatchConfirmedMatches = List<Map<String, dynamic>>.from(
      confirmedMatches,
    );
    _lastWatchPendingMatches = List<Map<String, dynamic>>.from(pendingMatches);

    return service.pushAuthContext(
      userId: userId,
      token: token,
      confirmedMatches: confirmedMatches,
      pendingMatches: pendingMatches,
      userNick: resolvedUserNick,
      userName: resolvedUserName,
      apiBaseUrl: appConfig.apiBaseUrl,
    );
  }

  void _scheduleWatchSyncRetry() {
    Future<void>.delayed(const Duration(seconds: 2), () {
      if (!mounted) {
        return;
      }
      _syncWatchAuth(ref.read(sessionControllerProvider), force: true);
    });
  }

  Map<String, dynamic>? _toWatchMatchPayload(Map<String, dynamic> item) {
    final id = _toInt(item['id']);
    final fieldId = _toInt(item['field_id'] ?? item['cancha_id']) ?? 0;
    final duration = _toInt(item['duration_minutes']) ?? 90;
    final startRaw = _readString(item['start_at'] ?? item['starts_at']);
    final startAt = DateTime.tryParse(startRaw)?.toUtc();
    final title = _readString(item['title']).isEmpty
        ? 'Pichanga Fulbii'
        : _readString(item['title']);
    final centerName = _firstNonEmpty([
      _readString(item['center_name']),
      _readString(item['polideportivo_name']),
      _readString(item['polideportivo_nombre']),
      _readString(item['field_center_name']),
    ]);
    final fieldName = _firstNonEmpty([
      _readString(item['field_name']),
      _readString(item['cancha_name']),
      _readString(item['cancha_nombre']),
      _readString(item['field_title']),
    ]);
    final teamCodes = <String>[
      if (item['team_codes'] is List)
        ...(item['team_codes'] as List)
            .map((code) => code.toString().trim().toUpperCase())
            .where((code) => code.isNotEmpty),
      if (item['teams'] is List)
        ...(item['teams'] as List)
            .whereType<Map>()
            .map((team) => _readString(team['code']).toUpperCase())
            .where((code) => code.isNotEmpty),
      ...[
        _readString(item['team_a_code']).toUpperCase(),
        _readString(item['team_b_code']).toUpperCase(),
        _readString(item['team_c_code']).toUpperCase(),
        _readString(item['team_d_code']).toUpperCase(),
      ].where((code) => code.isNotEmpty),
    ].toSet().toList(growable: false);

    if (id == null || id <= 0 || startAt == null) {
      return null;
    }

    return {
      'id': id,
      'title': title,
      'center_name': centerName.isEmpty ? 'Centro Deportivo' : centerName,
      'field_id': fieldId > 0 ? fieldId : 0,
      'field_name': fieldName.isEmpty ? 'Cancha' : fieldName,
      'start_at': startAt.toIso8601String(),
      'duration_minutes': duration,
      'team_codes': teamCodes.isEmpty ? const ['A', 'B'] : teamCodes,
      'status': _readString(item['status']).isEmpty
          ? _readString(item['me_participant_status'])
          : _readString(item['status']),
    };
  }

  int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }

  String _readString(dynamic value) => (value ?? '').toString().trim();

  String _firstNonEmpty(List<String> values) {
    for (final value in values) {
      if (value.isNotEmpty) return value;
    }
    return '';
  }

  bool _shouldIncludeConfirmedForWatch(
    Map<String, dynamic> item,
    DateTime nowUtc,
  ) {
    final startsAtRaw = _readString(item['start_at'] ?? item['starts_at']);
    final startsAtUtc = DateTime.tryParse(startsAtRaw)?.toUtc();
    if (startsAtUtc == null) {
      return false;
    }
    final durationMinutes = _toInt(item['duration_minutes']) ?? 90;
    final endsAtUtc = startsAtUtc.add(Duration(minutes: durationMinutes));
    final inProgress =
        (nowUtc.isAtSameMomentAs(startsAtUtc) || nowUtc.isAfter(startsAtUtc)) &&
        (nowUtc.isAtSameMomentAs(endsAtUtc) || nowUtc.isBefore(endsAtUtc));
    if (inProgress) {
      return true;
    }

    final nowLocal = nowUtc.toLocal();
    final startsAtLocal = startsAtUtc.toLocal();
    final todayStart = DateTime(nowLocal.year, nowLocal.month, nowLocal.day);
    final windowEndExclusive = todayStart.add(const Duration(days: 8));
    return !startsAtLocal.isBefore(todayStart) &&
        startsAtLocal.isBefore(windowEndExclusive);
  }

  Future<void> _handleJoinCode(String joinCode) async {
    final session = ref.read(sessionControllerProvider);
    if (session.initialized &&
        session.isAuthenticated &&
        !session.needsOnboarding) {
      await _openJoinScreen(joinCode);
      return;
    }

    _pendingJoinCode = joinCode;
  }

  Future<void> _handlePichangaLink(int pichangaId) async {
    final session = ref.read(sessionControllerProvider);
    if (session.initialized &&
        session.isAuthenticated &&
        !session.needsOnboarding) {
      await _openPichangaDetail(pichangaId);
      return;
    }

    _pendingPichangaId = pichangaId;
  }

  Future<void> _handleClubLink(int clubId) async {
    final session = ref.read(sessionControllerProvider);
    if (session.initialized && !session.needsOnboarding) {
      await _openClubDetail(clubId);
      return;
    }

    _pendingClubId = clubId;
  }

  Future<void> _handleWidgetAction(WidgetDeepLinkAction action) async {
    final session = ref.read(sessionControllerProvider);
    if (session.initialized &&
        session.isAuthenticated &&
        !session.needsOnboarding) {
      await _openWidgetAction(action);
      return;
    }

    _pendingWidgetAction = action;
  }

  Future<void> _handleOpenPichangas() async {
    final session = ref.read(sessionControllerProvider);
    if (session.initialized &&
        session.isAuthenticated &&
        !session.needsOnboarding) {
      await _openPichangas();
      return;
    }

    _pendingOpenPichangas = true;
  }

  Future<void> _openJoinScreen(String joinCode) async {
    if (_openingJoin) {
      return;
    }

    final navigator = ref.read(appNavigatorKeyProvider).currentState;
    if (navigator == null || !mounted) {
      _pendingJoinCode = joinCode;
      return;
    }

    _openingJoin = true;
    try {
      await navigator.push(
        MaterialPageRoute<void>(
          builder: (_) => JoinClubByLinkScreen(initialCode: joinCode),
        ),
      );
    } finally {
      _openingJoin = false;
    }
  }

  Future<void> _openPichangaDetail(int pichangaId) async {
    if (_openingPichanga) {
      return;
    }

    final navigator = ref.read(appNavigatorKeyProvider).currentState;
    if (navigator == null || !mounted) {
      _pendingPichangaId = pichangaId;
      return;
    }

    _openingPichanga = true;
    try {
      await navigator.push(
        MaterialPageRoute<void>(
          builder: (_) => PichangaDetailScreen(pichangaId: pichangaId),
        ),
      );
    } finally {
      _openingPichanga = false;
    }
  }

  Future<void> _openClubDetail(int clubId) async {
    if (_openingClub) {
      return;
    }

    final navigator = ref.read(appNavigatorKeyProvider).currentState;
    if (navigator == null || !mounted) {
      _pendingClubId = clubId;
      return;
    }

    _openingClub = true;
    try {
      await navigator.push(
        MaterialPageRoute<void>(
          builder: (_) => ClubDetailScreen(clubId: clubId),
        ),
      );
    } finally {
      _openingClub = false;
    }
  }

  Future<void> _openPichangas() async {
    if (_openingPichangasScreen) {
      return;
    }

    final navigator = ref.read(appNavigatorKeyProvider).currentState;
    if (navigator == null || !mounted) {
      _pendingOpenPichangas = true;
      return;
    }

    _openingPichangasScreen = true;
    try {
      // Widget launches must land in the app shell, not in a pushed standalone
      // screen. That preserves the bottom navigation the user expects.
      navigator.popUntil((route) => route.isFirst);
      ref.read(mainShellTabProvider.notifier).state = 2;
    } finally {
      _openingPichangasScreen = false;
    }
  }

  Future<void> _openWidgetAction(WidgetDeepLinkAction action) async {
    switch (action.type) {
      case WidgetDeepLinkActionType.select:
        await ref
            .read(widgetWeeklyServiceProvider)
            .selectConfirmedPichanga(action.pichangaId, ignoreErrors: true);
        await _openPichangaDetail(action.pichangaId);
        return;
      case WidgetDeepLinkActionType.shareLink:
        await _openPichangaShare(
          action.pichangaId,
          PichangaWidgetShareInitialAction.shareLink,
        );
        return;
      case WidgetDeepLinkActionType.shareLineup:
        await _openPichangaShare(
          action.pichangaId,
          PichangaWidgetShareInitialAction.shareLineup,
        );
        return;
    }
  }

  Future<void> _openPichangaShare(
    int pichangaId,
    PichangaWidgetShareInitialAction initialAction,
  ) async {
    if (_openingWidgetShare) {
      return;
    }

    final navigator = ref.read(appNavigatorKeyProvider).currentState;
    if (navigator == null || !mounted) {
      _pendingWidgetAction = WidgetDeepLinkAction(
        type: switch (initialAction) {
          PichangaWidgetShareInitialAction.shareLink =>
            WidgetDeepLinkActionType.shareLink,
          PichangaWidgetShareInitialAction.shareLineup =>
            WidgetDeepLinkActionType.shareLineup,
          PichangaWidgetShareInitialAction.none =>
            WidgetDeepLinkActionType.shareLink,
        },
        pichangaId: pichangaId,
      );
      return;
    }

    _openingWidgetShare = true;
    try {
      await navigator.push(
        MaterialPageRoute<void>(
          builder: (_) => PichangaWidgetShareScreen(
            pichangaId: pichangaId,
            initialAction: initialAction,
          ),
        ),
      );
    } finally {
      _openingWidgetShare = false;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ref.read(deepLinkServiceProvider).dispose();
    super.dispose();
  }
}

ThemeData _fulbiiTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final scaffold = isDark ? const Color(0xFF080C0A) : const Color(0xFFF5F8F4);
  final surface = isDark ? const Color(0xFF111613) : Colors.white;
  final outline = isDark ? const Color(0xFF26332B) : const Color(0xFFD1DDD1);
  final green = const Color(0xFF249D31);
  final colorScheme = ColorScheme.fromSeed(
    seedColor: green,
    brightness: brightness,
    surface: surface,
  );
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    scaffoldBackgroundColor: scaffold,
    colorScheme: colorScheme,
    cardTheme: CardThemeData(
      color: surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: outline),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: scaffold,
      foregroundColor: isDark ? Colors.white : const Color(0xFF112014),
      elevation: 0,
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 72,
      backgroundColor: isDark ? const Color(0xFF0D120F) : Colors.white,
      indicatorColor: isDark
          ? const Color(0xFF1B8F24)
          : const Color(0xFFA9E29D),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      labelTextStyle: const WidgetStatePropertyAll(
        TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: isDark ? const Color(0xFF18211B) : Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: outline),
      ),
    ),
  );
}

class _DevelopmentEnvironmentBadge extends StatelessWidget {
  const _DevelopmentEnvironmentBadge();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xCC123D2A),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: const Color(0xFF74DA9B)),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          'DEV · local',
          style: TextStyle(
            color: Color(0xFFE9FFF0),
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text('Cargando Fulbii...'),
          ],
        ),
      ),
    );
  }
}
