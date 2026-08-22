import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/session_controller.dart';
import '../auth/presentation/login_required_sheet.dart';
import '../../services/push/push_service.dart';
import '../../services/widget/widget_weekly_service.dart';
import '../challenges/presentation/challenge_detail_screen.dart';
import '../clubs/presentation/clubs_screen.dart';
import '../clubs/presentation/club_detail_screen.dart';
import '../clubs/presentation/club_group_chat_screen.dart';
import '../championships/presentation/championships_screen.dart';
import '../championships/presentation/championship_invitations_screen.dart';
import '../notifications/presentation/inbox_screen.dart'
    show InboxScreen, inboxProvider, unreadNotificationsCountProvider;
import '../pichangas/presentation/pichanga_detail_screen.dart';
import '../pichangas/presentation/pichangas_screen.dart';
import '../fields/presentation/map_screen.dart';
import '../fields/presentation/field_detail_screen.dart';
import '../fields/presentation/field_submission_screen.dart';
import '../profile/presentation/profile_screen.dart';
import '../profile/presentation/public_player_profile_screen.dart';

final mainShellTabProvider = StateProvider<int>((ref) => 0);

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell>
    with WidgetsBindingObserver {
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
    final session = ref.watch(sessionControllerProvider);
    final isAuthenticated = session.isAuthenticated;
    if (isAuthenticated && !_pushInitialized) {
      _pushInitialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        _pushService.initialize(
          onOpenPichanga: _openPichanga,
          onOpenChallenge: _openChallenge,
          onOpenNotification: _openPushNotification,
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

    final unreadAsync = isAuthenticated
        ? ref.watch(unreadNotificationsCountProvider)
        : const AsyncData<int>(0);
    final unreadCount = unreadAsync.maybeWhen(
      data: (count) => count,
      orElse: () => 0,
    );

    final pages = [
      MapScreen(onOpenPichanga: _openPichanga, onOpenInbox: _openInboxFromBell),
      const ClubsScreen(),
      isAuthenticated
          ? const PichangasScreen()
          : const _GuestRestrictedPage(
              icon: Icons.sports_soccer_outlined,
              title: 'Inicia sesión para ver tus pichangas',
              action: 'ver las pichangas',
            ),
      isAuthenticated
          ? const InboxScreen()
          : const _GuestRestrictedPage(
              icon: Icons.notifications_none,
              title: 'Inicia sesión para ver tus notificaciones',
              action: 'ver notificaciones',
            ),
      const ProfileScreen(),
    ];

    final currentIndex = ref.watch(mainShellTabProvider);

    return Scaffold(
      appBar: null,
      body: IndexedStack(index: currentIndex, children: pages),
      bottomNavigationBar: _FulbiiBottomNavigation(
        selectedIndex: currentIndex,
        unreadCount: unreadCount,
        onDestinationSelected: (index) async {
          if (!isAuthenticated && (index == 2 || index == 3)) {
            await requireSignIn(
              context,
              ref,
              action: index == 2 ? 'ver las pichangas' : 'ver notificaciones',
            );
            return;
          }
          ref.read(mainShellTabProvider.notifier).state = index;
          if (index == 0) {
            // Approved contributions can add a new centre or court while the
            // app is open; fetch the latest marker summaries when returning.
            ref.invalidate(fieldsProvider);
          }
          if (isAuthenticated && index == 3) {
            ref.invalidate(inboxProvider);
            ref.invalidate(unreadNotificationsCountProvider);
          }
        },
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

  void _openPushNotification(Map<String, dynamic> data) {
    final challengeId = int.tryParse((data['challenge_id'] ?? '').toString());
    if (challengeId != null) {
      _openChallenge(challengeId);
      return;
    }
    final pichangaId = int.tryParse((data['pichanga_id'] ?? '').toString());
    if (pichangaId != null) {
      _openPichanga(pichangaId);
      return;
    }
    final championshipId = int.tryParse(
      (data['championship_id'] ?? '').toString(),
    );
    final targetType = (data['target_type'] ?? '').toString();
    if (targetType == 'championship_team_invitation') {
      Navigator.of(context)
          .push(
            MaterialPageRoute<void>(
              builder: (_) => const ChampionshipInvitationsScreen(),
            ),
          )
          .then((_) {
            ref.invalidate(inboxProvider);
            ref.invalidate(unreadNotificationsCountProvider);
          });
      return;
    }
    if (championshipId != null && championshipId > 0) {
      Navigator.of(context)
          .push(
            MaterialPageRoute<void>(
              builder: (_) =>
                  ChampionshipDetailScreen(championshipId: championshipId),
            ),
          )
          .then((_) {
            ref.invalidate(inboxProvider);
            ref.invalidate(unreadNotificationsCountProvider);
          });
      return;
    }
    if (!mounted) return;
    final clubId = int.tryParse((data['club_id'] ?? '').toString()) ?? 0;
    final targetId = int.tryParse((data['target_id'] ?? '').toString()) ?? 0;
    final fieldId = int.tryParse((data['field_id'] ?? '').toString()) ?? 0;
    if (targetType == 'field' && (fieldId > 0 || targetId > 0)) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) =>
              FieldDetailScreen(fieldId: fieldId > 0 ? fieldId : targetId),
        ),
      );
    } else if (targetType == 'field_submission') {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) =>
              const FieldSubmissionScreen(showMyContributions: true),
        ),
      );
    } else if (targetType == 'club_chat' && clubId > 0) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) =>
              ClubGroupChatScreen(clubId: clubId, clubName: 'Grupo'),
        ),
      );
    } else if (targetType == 'club_join_request' && clubId > 0) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ClubAdministrationScreen(clubId: clubId),
        ),
      );
    } else if (targetType == 'player_rating_history' &&
        clubId > 0 &&
        targetId > 0) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) =>
              PublicPlayerProfileScreen(clubId: clubId, userId: targetId),
        ),
      );
    } else if (clubId > 0) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ClubDetailScreen(clubId: clubId),
        ),
      );
    } else {
      _openInboxFromBell();
    }
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

  Future<void> _openInboxFromBell() async {
    if (!ref.read(sessionControllerProvider).isAuthenticated) {
      await requireSignIn(context, ref, action: 'ver notificaciones');
      return;
    }
    ref.read(mainShellTabProvider.notifier).state = 3;
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
      ref.invalidate(inboxProvider);
      ref.invalidate(unreadNotificationsCountProvider);
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

class _FulbiiBottomNavigation extends StatelessWidget {
  const _FulbiiBottomNavigation({
    required this.selectedIndex,
    required this.unreadCount,
    required this.onDestinationSelected,
  });

  final int selectedIndex;
  final int unreadCount;
  final ValueChanged<int> onDestinationSelected;

  static const _destinations = <({IconData icon, String label})>[
    (icon: Icons.map_outlined, label: 'Canchas'),
    (icon: Icons.groups_outlined, label: 'Grupos'),
    (icon: Icons.sports_soccer_outlined, label: 'Pichangas'),
    (icon: Icons.notifications_none, label: 'Notificaciones'),
    (icon: Icons.person_outline, label: 'Perfil'),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D120F) : colorScheme.surface,
        border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(8, 4, 8, 3),
        child: SizedBox(
          height: 57,
          child: Row(
            children: List.generate(_destinations.length, (index) {
              final destination = _destinations[index];
              final isSelected = selectedIndex == index;
              return Expanded(
                child: _BottomNavigationItem(
                  icon: destination.icon,
                  label: destination.label,
                  selected: isSelected,
                  unreadCount: index == 3 ? unreadCount : 0,
                  onTap: () => onDestinationSelected(index),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _BottomNavigationItem extends StatelessWidget {
  const _BottomNavigationItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.unreadCount,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final int unreadCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final foreground = selected
        ? colorScheme.onPrimary
        : colorScheme.onSurfaceVariant;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 5),
          decoration: BoxDecoration(
            color: selected ? colorScheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(icon, color: foreground, size: 21),
                  if (unreadCount > 0)
                    Positioned(
                      right: -9,
                      top: -7,
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 15),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 3,
                          vertical: 1,
                        ),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.all(Radius.circular(9)),
                        ),
                        child: Text(
                          unreadCount > 99 ? '99+' : '$unreadCount',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 1),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: TextStyle(
                    color: foreground,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GuestRestrictedPage extends ConsumerWidget {
  const _GuestRestrictedPage({
    required this.icon,
    required this.title,
    required this.action,
  });

  final IconData icon;
  final String title;
  final String action;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 58, color: colorScheme.primary),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            const Text(
              'Explora Canchas y Grupos libremente. Para esta acción necesitas una cuenta.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 22),
            FilledButton(
              onPressed: () => requireSignIn(context, ref, action: action),
              child: const Text('Iniciar sesión'),
            ),
          ],
        ),
      ),
    );
  }
}
