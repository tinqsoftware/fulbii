import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_error.dart';
import '../../challenges/presentation/challenge_detail_screen.dart';
import '../../pichangas/presentation/pichanga_detail_screen.dart';
import '../data/notifications_repository.dart';

final inboxProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>(
  (ref) => ref.watch(notificationsRepositoryProvider).inbox(),
);

final unreadNotificationsCountProvider = FutureProvider<int>((ref) {
  return ref.watch(notificationsRepositoryProvider).unreadCount();
});

class InboxScreen extends ConsumerWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncInbox = ref.watch(inboxProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              FilledButton.icon(
                onPressed: () async {
                  try {
                    await ref
                        .read(notificationsRepositoryProvider)
                        .markAllRead();
                    ref.invalidate(inboxProvider);
                    ref.invalidate(unreadNotificationsCountProvider);
                  } on ApiError catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(e.message)));
                    }
                  }
                },
                icon: const Icon(Icons.done_all),
                label: const Text('Marcar todo leído'),
              ),
            ],
          ),
        ),
        Expanded(
          child: asyncInbox.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) =>
                Center(child: Text('No se pudo cargar inbox: $error')),
            data: (items) {
              if (items.isEmpty) {
                return const Center(child: Text('No hay notificaciones.'));
              }

              return RefreshIndicator(
                onRefresh: () async => ref.invalidate(inboxProvider),
                child: ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: items.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final id = int.tryParse(item['id'].toString()) ?? 0;
                    final isRead = item['is_read'] == true;
                    final title = (item['title'] ?? '').toString();
                    final body = (item['body'] ?? '').toString();
                    final createdAt = (item['created_at'] ?? '')
                        .toString()
                        .replaceFirst('T', ' ');
                    final dataJson =
                        (item['data_json'] as Map?)?.cast<String, dynamic>() ??
                        {};

                    return Card(
                      color: isRead
                          ? null
                          : Theme.of(context).colorScheme.primaryContainer,
                      child: ListTile(
                        title: Text(title),
                        subtitle: Text('$body\n$createdAt'),
                        isThreeLine: true,
                        onTap: () async {
                          if (!isRead) {
                            await ref
                                .read(notificationsRepositoryProvider)
                                .markRead(id);
                            ref.invalidate(inboxProvider);
                            ref.invalidate(unreadNotificationsCountProvider);
                          }

                          final challengeId = int.tryParse(
                            (dataJson['challenge_id'] ?? '').toString(),
                          );
                          if (challengeId != null && context.mounted) {
                            await Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    ChallengeDetailScreen(challengeId: challengeId),
                              ),
                            );
                            ref.invalidate(inboxProvider);
                            ref.invalidate(unreadNotificationsCountProvider);
                            return;
                          }

                          final pichangaId = int.tryParse(
                            (dataJson['pichanga_id'] ??
                                    item['group_pichanga_id'] ??
                                    '')
                                .toString(),
                          );
                          if (pichangaId != null && context.mounted) {
                            await Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    PichangaDetailScreen(pichangaId: pichangaId),
                              ),
                            );
                            ref.invalidate(inboxProvider);
                            ref.invalidate(unreadNotificationsCountProvider);
                          }
                        },
                        trailing: isRead
                            ? null
                            : IconButton(
                                onPressed: () async {
                                  await ref
                                      .read(notificationsRepositoryProvider)
                                      .markRead(id);
                                  ref.invalidate(inboxProvider);
                                  ref.invalidate(unreadNotificationsCountProvider);
                                },
                                icon: const Icon(
                                  Icons.mark_email_read_outlined,
                                ),
                              ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
