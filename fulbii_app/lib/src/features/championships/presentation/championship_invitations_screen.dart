import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/championships_repository.dart';
import 'championships_screen.dart';

final myChampionshipInvitationsProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, bool>((ref, _) {
      return ref.watch(championshipsRepositoryProvider).myInvitations();
    });

class ChampionshipInvitationsScreen extends ConsumerWidget {
  const ChampionshipInvitationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invitations = ref.watch(myChampionshipInvitationsProvider(true));
    return Scaffold(
      appBar: AppBar(title: const Text('Invitaciones de campeonato')),
      body: invitations.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _InvitationError(
          onRetry: () =>
              ref.invalidate(myChampionshipInvitationsProvider(true)),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const _InvitationEmpty();
          }
          return RefreshIndicator(
            onRefresh: () async =>
                ref.invalidate(myChampionshipInvitationsProvider(true)),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) => _InvitationCard(
                invitation: items[index],
                onResolved: () =>
                    ref.invalidate(myChampionshipInvitationsProvider(true)),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _InvitationCard extends ConsumerStatefulWidget {
  const _InvitationCard({required this.invitation, required this.onResolved});

  final Map<String, dynamic> invitation;
  final VoidCallback onResolved;

  @override
  ConsumerState<_InvitationCard> createState() => _InvitationCardState();
}

class _InvitationCardState extends ConsumerState<_InvitationCard> {
  bool _busy = false;

  Future<void> _respond(bool accept) async {
    setState(() => _busy = true);
    try {
      await ref
          .read(championshipsRepositoryProvider)
          .respondInvitation(_asInt(widget.invitation['id']), accept: accept);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              accept ? 'Te uniste al equipo.' : 'Invitación rechazada.',
            ),
          ),
        );
      }
      widget.onResolved();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('No se pudo resolver: $error')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final team =
        (widget.invitation['team'] as Map?)?.cast<String, dynamic>() ?? {};
    final championship =
        (widget.invitation['championship'] as Map?)?.cast<String, dynamic>() ??
        {};
    final inviter = (widget.invitation['invited_by'] as Map?)
        ?.cast<String, dynamic>();
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InvitationLogo(
                  url: (championship['logo_url'] ?? '').toString(),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (championship['name'] ?? 'Campeonato').toString(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Te invitan a ${team['name'] ?? 'un equipo'}',
                        style: theme.textTheme.bodyMedium,
                      ),
                      if (inviter?['nick'] != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Por @${inviter!['nick']}',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _busy ? null : () => _respond(false),
                    child: const Text('Rechazar'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _busy ? null : () => _respond(true),
                    icon: _busy
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check_rounded),
                    label: const Text('Aceptar'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _busy
                    ? null
                    : () {
                        final id = _asInt(championship['id']);
                        if (id > 0) {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  ChampionshipDetailScreen(championshipId: id),
                            ),
                          );
                        }
                      },
                child: const Text('Ver campeonato'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InvitationLogo extends StatelessWidget {
  const _InvitationLogo({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 24,
      backgroundImage: url.trim().isNotEmpty ? NetworkImage(url) : null,
      child: url.trim().isEmpty ? const Icon(Icons.emoji_events_rounded) : null,
    );
  }
}

class _InvitationEmpty extends StatelessWidget {
  const _InvitationEmpty();

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.mark_email_read_outlined,
            size: 48,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 12),
          const Text(
            'No tienes invitaciones pendientes',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}

class _InvitationError extends StatelessWidget {
  const _InvitationError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: OutlinedButton.icon(
      onPressed: onRetry,
      icon: const Icon(Icons.refresh_rounded),
      label: const Text('Reintentar invitaciones'),
    ),
  );
}

int _asInt(Object? value) => int.tryParse(value?.toString() ?? '') ?? 0;
