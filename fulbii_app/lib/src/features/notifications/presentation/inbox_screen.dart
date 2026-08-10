import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_error.dart';
import '../../challenges/presentation/challenge_detail_screen.dart';
import '../../clubs/presentation/club_detail_screen.dart';
import '../../clubs/presentation/club_group_chat_screen.dart';
import '../../pichangas/presentation/pichanga_detail_screen.dart';
import '../../profile/presentation/public_player_profile_screen.dart';
import '../data/notifications_repository.dart';

final inboxProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>(
  (ref) => ref.watch(notificationsRepositoryProvider).inbox(),
);

final unreadNotificationsCountProvider = FutureProvider<int>((ref) {
  return ref.watch(notificationsRepositoryProvider).unreadCount();
});

class InboxScreen extends ConsumerStatefulWidget {
  const InboxScreen({super.key});

  @override
  ConsumerState<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends ConsumerState<InboxScreen> {
  bool _onlyUnread = false;

  @override
  Widget build(BuildContext context) {
    final asyncInbox = ref.watch(inboxProvider);
    return asyncInbox.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) =>
          Center(child: Text('No se pudo cargar notificaciones: $error')),
      data: (allItems) {
        final items = _onlyUnread
            ? allItems.where((item) => item['is_read'] != true).toList()
            : allItems;
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(inboxProvider),
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              16,
              MediaQuery.paddingOf(context).top + 14,
              16,
              28,
            ),
            children: [
              Row(
                children: [
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(value: false, label: Text('Todas')),
                      ButtonSegment(value: true, label: Text('No leídas')),
                    ],
                    selected: {_onlyUnread},
                    onSelectionChanged: (value) =>
                        setState(() => _onlyUnread = value.first),
                    showSelectedIcon: false,
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: allItems.every((item) => item['is_read'] == true)
                        ? null
                        : _markAllRead,
                    icon: const Icon(Icons.done_all, size: 18),
                    label: const Text('Marcar leído'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (items.isEmpty)
                const _InboxEmpty()
              else
                ..._grouped(items).entries.expand(
                  (entry) => [
                    Padding(
                      padding: const EdgeInsets.only(top: 12, bottom: 8),
                      child: Text(
                        entry.key,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    ...entry.value.map(_notificationCard),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  Map<String, List<Map<String, dynamic>>> _grouped(
    List<Map<String, dynamic>> items,
  ) {
    final result = <String, List<Map<String, dynamic>>>{};
    for (final item in items) {
      final date = DateTime.tryParse(
        (item['created_at'] ?? '').toString(),
      )?.toLocal();
      final now = DateTime.now();
      final label = date == null
          ? 'Anteriores'
          : DateUtils.isSameDay(date, now)
          ? 'Hoy'
          : DateUtils.isSameDay(date, now.subtract(const Duration(days: 1)))
          ? 'Ayer'
          : '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
      result.putIfAbsent(label, () => []).add(item);
    }
    return result;
  }

  Widget _notificationCard(Map<String, dynamic> item) {
    final isRead = item['is_read'] == true;
    final type = (item['type'] ?? '').toString();
    final title = (item['title'] ?? 'Notificación').toString();
    final body = (item['body'] ?? '').toString();
    final icon = type.contains('challenge')
        ? Icons.emoji_events_outlined
        : type.contains('pichanga')
        ? Icons.sports_soccer_outlined
        : Icons.notifications_outlined;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: isRead
            ? Theme.of(context).colorScheme.surfaceContainerLowest
            : Theme.of(
                context,
              ).colorScheme.primaryContainer.withValues(alpha: .42),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _open(item),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _NotificationVisual(item: item, icon: icon),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      if (body.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          body,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 6),
                      Text(
                        _relativeTime(item['created_at']),
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ),
                ),
                if (!isRead)
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(top: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _relativeTime(dynamic value) {
    final date = DateTime.tryParse((value ?? '').toString())?.toLocal();
    if (date == null) return '';
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Ahora';
    if (diff.inHours < 1) return 'Hace ${diff.inMinutes} min';
    if (diff.inDays < 1) return 'Hace ${diff.inHours} h';
    return 'Hace ${diff.inDays} d';
  }

  Future<void> _markAllRead() async {
    try {
      await ref.read(notificationsRepositoryProvider).markAllRead();
      ref.invalidate(inboxProvider);
      ref.invalidate(unreadNotificationsCountProvider);
    } on ApiError catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }

  Future<void> _open(Map<String, dynamic> item) async {
    final id = int.tryParse(item['id'].toString()) ?? 0;
    if (item['is_read'] != true && id > 0) {
      await ref.read(notificationsRepositoryProvider).markRead(id);
      ref.invalidate(inboxProvider);
      ref.invalidate(unreadNotificationsCountProvider);
    }
    final data = (item['data_json'] as Map?)?.cast<String, dynamic>() ?? {};
    final challenge = int.tryParse((data['challenge_id'] ?? '').toString());
    final pichanga = int.tryParse(
      (data['pichanga_id'] ?? item['group_pichanga_id'] ?? '').toString(),
    );
    if (!mounted) return;
    if (challenge != null) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ChallengeDetailScreen(challengeId: challenge),
        ),
      );
    } else if (pichanga != null) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => PichangaDetailScreen(pichangaId: pichanga),
        ),
      );
    } else {
      final targetType = (data['target_type'] ?? '').toString();
      final targetId = int.tryParse((data['target_id'] ?? '').toString()) ?? 0;
      final clubId =
          int.tryParse((data['club_id'] ?? item['club_id'] ?? '').toString()) ??
          0;
      if (targetType == 'club_chat' && clubId > 0) {
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ClubGroupChatScreen(
              clubId: clubId,
              clubName: (item['title'] ?? 'Grupo').toString(),
            ),
          ),
        );
      } else if (targetType == 'club_join_request' && clubId > 0) {
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ClubAdministrationScreen(clubId: clubId),
          ),
        );
      } else if (targetType == 'player_rating_history' &&
          clubId > 0 &&
          targetId > 0) {
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) =>
                PublicPlayerProfileScreen(clubId: clubId, userId: targetId),
          ),
        );
      } else if (clubId > 0) {
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ClubDetailScreen(clubId: clubId),
          ),
        );
      }
    }
  }
}

class _NotificationVisual extends StatelessWidget {
  const _NotificationVisual({required this.item, required this.icon});

  final Map<String, dynamic> item;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final data = (item['data_json'] as Map?)?.cast<String, dynamic>() ?? {};
    final imageUrl = (data['image_url'] ?? '').toString();
    final secondaryImageUrl = (data['secondary_image_url'] ?? '').toString();
    final color = Theme.of(context).colorScheme.primary;
    Widget photo(String url, {double size = 44}) => ClipOval(
      child: url.isEmpty
          ? Container(
              color: color.withValues(alpha: .13),
              width: size,
              height: size,
            )
          : Image.network(
              url,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                color: color.withValues(alpha: .13),
                width: size,
                height: size,
              ),
            ),
    );
    return SizedBox(
      width: 48,
      height: 48,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (secondaryImageUrl.isNotEmpty)
            Positioned(
              right: 0,
              bottom: 0,
              child: photo(secondaryImageUrl, size: 31),
            ),
          Positioned(left: 0, top: 0, child: photo(imageUrl)),
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).colorScheme.surface,
                  width: 2,
                ),
              ),
              child: Icon(
                icon,
                size: 13,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InboxEmpty extends StatelessWidget {
  const _InboxEmpty();
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.only(top: 90),
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.notifications_none, size: 42),
          SizedBox(height: 12),
          Text('No hay notificaciones aquí.'),
        ],
      ),
    ),
  );
}
