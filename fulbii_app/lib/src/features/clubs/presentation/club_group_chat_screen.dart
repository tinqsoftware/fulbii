import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_error.dart';
import '../../../core/theme/fulbii_snackbar.dart';
import '../../notifications/presentation/report_content_sheet.dart';
import '../data/clubs_repository.dart';

final clubGroupChatProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, int>(
      (ref, clubId) =>
          ref.watch(clubsRepositoryProvider).groupChatMessages(clubId),
    );

class ClubGroupChatScreen extends ConsumerStatefulWidget {
  const ClubGroupChatScreen({
    required this.clubId,
    required this.clubName,
    super.key,
  });

  final int clubId;
  final String clubName;

  @override
  ConsumerState<ClubGroupChatScreen> createState() =>
      _ClubGroupChatScreenState();
}

class _ClubGroupChatScreenState extends ConsumerState<ClubGroupChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _poller;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _poller = Timer.periodic(const Duration(seconds: 12), (_) {
      if (mounted) ref.invalidate(clubGroupChatProvider(widget.clubId));
    });
  }

  @override
  void dispose() {
    _poller?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(clubGroupChatProvider(widget.clubId));
    ref.listen<AsyncValue<List<Map<String, dynamic>>>>(
      clubGroupChatProvider(widget.clubId),
      (_, next) {
        final lastId =
            int.tryParse(
              (next.valueOrNull?.lastOrNull?['id'] ?? '').toString(),
            ) ??
            0;
        if (lastId > 0) {
          ref
              .read(clubsRepositoryProvider)
              .markGroupChatRead(widget.clubId, lastId);
        }
      },
    );

    return Scaffold(
      appBar: AppBar(title: Text('Chat · ${widget.clubName}')),
      body: Column(
        children: [
          Expanded(
            child: messages.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) =>
                  Center(child: Text('No se pudo cargar el chat: $error')),
              data: (items) {
                if (items.isEmpty) {
                  return const Center(
                    child: Text('Aún no hay mensajes. Inicia la conversación.'),
                  );
                }
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  itemCount: items.length,
                  itemBuilder: (_, index) => _MessageBubble(item: items[index]),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 4,
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: (_) => _send(),
                      decoration: const InputDecoration(
                        hintText: 'Escribe un mensaje',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _sending ? null : _send,
                    style: FilledButton.styleFrom(
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(14),
                    ),
                    child: _sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _send() async {
    final body = _controller.text.trim();
    if (body.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await ref
          .read(clubsRepositoryProvider)
          .sendGroupChatMessage(widget.clubId, body);
      _controller.clear();
      ref.invalidate(clubGroupChatProvider(widget.clubId));
    } on ApiError catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          fulbiiSnackBar(error.message, tone: FulbiiSnackBarTone.error),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.item});
  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    final user =
        (item['user'] as Map?)?.cast<String, dynamic>() ??
        const <String, dynamic>{};
    final name = (user['nick'] ?? user['name'] ?? 'Sistema').toString();
    final isSystem = item['type'] == 'system';
    final userId = int.tryParse(user['id'].toString()) ?? 0;
    final messageId = int.tryParse(item['id'].toString()) ?? 0;
    final created = DateTime.tryParse(
      (item['created_at'] ?? '').toString(),
    )?.toLocal();
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints: const BoxConstraints(maxWidth: 330),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSystem
              ? Theme.of(context).colorScheme.surfaceContainerHighest
              : Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 3),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(child: Text((item['body'] ?? '').toString())),
                if (!isSystem && userId > 0 && messageId > 0)
                  IconButton(
                    tooltip: 'Reportar mensaje',
                    icon: const Icon(Icons.flag_outlined, size: 17),
                    visualDensity: VisualDensity.compact,
                    onPressed: () => showReportContentSheet(
                      context,
                      targetType: 'user',
                      targetId: userId,
                      contentType: 'club_group_message',
                      contentId: messageId,
                      title: 'Reportar mensaje',
                    ),
                  ),
              ],
            ),
            if (created != null) ...[
              const SizedBox(height: 4),
              Text(
                '${created.hour.toString().padLeft(2, '0')}:${created.minute.toString().padLeft(2, '0')}',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
