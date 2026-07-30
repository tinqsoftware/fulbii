import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/session_controller.dart';
import '../../services/push/push_service.dart';
import '../../services/widget/widget_weekly_service.dart';
import '../challenges/presentation/challenge_detail_screen.dart';
import '../clubs/presentation/clubs_screen.dart';
import '../notifications/presentation/inbox_screen.dart'
    show InboxScreen, inboxProvider, unreadNotificationsCountProvider;
import '../pichangas/presentation/pichanga_detail_screen.dart';
import '../pichangas/presentation/pichangas_screen.dart';
import '../fields/presentation/map_screen.dart';
import '../profile/presentation/profile_screen.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell>
    with WidgetsBindingObserver {
  int _currentIndex = 0;
  bool _pushInitialized = false;
  bool _widgetSyncScheduled = false;
  late final PushService _pushService;

  @override
  void initState() {
    super.initState();
    _pushService = ref.read(pushServiceProvider);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  Widget build(BuildContext context) {
    if (!_pushInitialized) {
      _pushInitialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        _pushService.initialize(
          onOpenPichanga: _openPichanga,
          onOpenChallenge: _openChallenge,
          onForegroundNotification: _showForegroundNotification,
        );
      });
    }

    if (!_widgetSyncScheduled) {
      _widgetSyncScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _syncWidgets();
        }
      });
    }

    final pages = [
      MapScreen(onOpenPichanga: _openPichanga, onOpenInbox: _openInboxFromBell),
      const ClubsScreen(),
      const PichangasScreen(),
      const InboxScreen(),
      const ProfileScreen(),
    ];

    final titles = [
      'Canchas',
      'Grupos',
      'Pichangas',
      'Notificaciones',
      'Perfil',
    ];
    final unreadAsync = ref.watch(unreadNotificationsCountProvider);
    final unreadCount = unreadAsync.maybeWhen(
      data: (count) => count,
      orElse: () => 0,
    );

    return Scaffold(
      appBar: _currentIndex == 0
          ? null
          : AppBar(
              title: Text(titles[_currentIndex]),
              actions: [
                IconButton(
                  onPressed: _openInboxFromBell,
                  icon: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(Icons.notifications_none),
                      if (unreadCount > 0)
                        Positioned(
                          right: -7,
                          top: -7,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 2,
                            ),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.rectangle,
                              borderRadius: BorderRadius.all(
                                Radius.circular(10),
                              ),
                            ),
                            constraints: const BoxConstraints(minWidth: 18),
                            child: Text(
                              unreadCount > 99 ? '99+' : '$unreadCount',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
          if (index == 0) {
            // Approved contributions can add a new centre or court while the
            // app is open; fetch the latest marker summaries when returning.
            ref.invalidate(fieldsProvider);
          }
          if (index == 3) {
            ref.invalidate(inboxProvider);
            ref.invalidate(unreadNotificationsCountProvider);
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            label: 'Canchas',
          ),
          NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            label: 'Grupos',
          ),
          NavigationDestination(
            icon: Icon(Icons.sports_soccer_outlined),
            label: 'Pichangas',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_none),
            label: 'Inbox',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }

  void _openPichanga(int pichangaId) {
    if (!mounted) {
      return;
    }

    Navigator.of(context)
        .push(
          MaterialPageRoute<void>(
            builder: (_) => PichangaDetailScreen(pichangaId: pichangaId),
          ),
        )
        .then((_) {
          ref.invalidate(inboxProvider);
          ref.invalidate(unreadNotificationsCountProvider);
        });
  }

  void _openChallenge(int challengeId) {
    if (!mounted) {
      return;
    }

    Navigator.of(context)
        .push(
          MaterialPageRoute<void>(
            builder: (_) => ChallengeDetailScreen(challengeId: challengeId),
          ),
        )
        .then((_) {
          ref.invalidate(inboxProvider);
          ref.invalidate(unreadNotificationsCountProvider);
        });
  }

  void _showForegroundNotification(
    String title,
    String body,
    Map<String, dynamic> data,
  ) {
    if (!mounted) {
      return;
    }

    ref.invalidate(inboxProvider);
    ref.invalidate(unreadNotificationsCountProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(body.isEmpty ? title : '$title\n$body'),
        duration: const Duration(seconds: 3),
        action: (data['challenge_id'] ?? '').toString().isNotEmpty
            ? SnackBarAction(
                label: 'Abrir chat',
                onPressed: () {
                  final challengeId = int.tryParse(
                    (data['challenge_id'] ?? '').toString(),
                  );
                  if (challengeId != null) {
                    _openChallenge(challengeId);
                  }
                },
              )
            : null,
      ),
    );
  }

  void _openInboxFromBell() {
    setState(() => _currentIndex = 3);
    ref.invalidate(inboxProvider);
    ref.invalidate(unreadNotificationsCountProvider);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_pushService.dispose());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncWidgets();
    }
  }

  Future<void> _syncWidgets() async {
    if (!mounted) {
      return;
    }

    final session = ref.read(sessionControllerProvider);
    if (!session.isAuthenticated || session.needsOnboarding) {
      return;
    }

    await ref.read(widgetWeeklyServiceProvider).syncAll(ignoreErrors: true);
  }
}
