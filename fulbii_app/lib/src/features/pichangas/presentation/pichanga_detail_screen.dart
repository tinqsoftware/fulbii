import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_error.dart';
import '../../../services/widget/widget_weekly_service.dart';
import '../data/pichangas_repository.dart';

final pichangaDetailProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, int>((ref, pichangaId) {
      return ref.watch(pichangasRepositoryProvider).detail(pichangaId);
    });

final pichangaFeedProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, int>((ref, pichangaId) {
      return ref.watch(pichangasRepositoryProvider).feed(pichangaId);
    });

final pichangaRatingsProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, int>((ref, pichangaId) {
      return ref.watch(pichangasRepositoryProvider).ratings(pichangaId);
    });

final pichangaExternalRequestsProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, int>((ref, pichangaId) {
      return ref
          .watch(pichangasRepositoryProvider)
          .externalRequests(pichangaId);
    });

final pichangaWatchHeatmapProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, int>((ref, pichangaId) {
      return ref
          .watch(pichangasRepositoryProvider)
          .watchHeatmapByPichangaMe(pichangaId);
    });

final pichangaWatchSessionsProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, int>((ref, pichangaId) {
      return ref
          .watch(pichangasRepositoryProvider)
          .watchSessionsByPichangaMe(pichangaId);
    });

class PichangaDetailScreen extends ConsumerStatefulWidget {
  const PichangaDetailScreen({required this.pichangaId, super.key});

  final int pichangaId;

  @override
  ConsumerState<PichangaDetailScreen> createState() =>
      _PichangaDetailScreenState();
}

class _PichangaDetailScreenState extends ConsumerState<PichangaDetailScreen> {
  String? _selectedTeamCode;
  Timer? _watchAutoRefreshTimer;

  @override
  void initState() {
    super.initState();
    _watchAutoRefreshTimer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (!mounted) return;
      ref.invalidate(pichangaWatchHeatmapProvider(widget.pichangaId));
      ref.invalidate(pichangaWatchSessionsProvider(widget.pichangaId));
    });
  }

  @override
  void dispose() {
    _watchAutoRefreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    final detailAsync = ref.watch(pichangaDetailProvider(widget.pichangaId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle pichanga'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(pichangaDetailProvider(widget.pichangaId));
              ref.invalidate(pichangaFeedProvider(widget.pichangaId));
              ref.invalidate(pichangaRatingsProvider(widget.pichangaId));
              ref.invalidate(
                pichangaExternalRequestsProvider(widget.pichangaId),
              );
              ref.invalidate(pichangaWatchHeatmapProvider(widget.pichangaId));
              ref.invalidate(pichangaWatchSessionsProvider(widget.pichangaId));
            },
          ),
        ],
      ),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text('No se pudo cargar la pichanga: $error')),
        data: (data) {
          final pichanga =
              (data['pichanga'] as Map?)?.cast<String, dynamic>() ?? {};
          final me = (data['me'] as Map?)?.cast<String, dynamic>() ?? {};
          final isAdmin = me['is_admin'] == true;
          final isMember = me['is_member'] == true;
          final participantStatus = me['participant_status']?.toString();
          final externalStatus = me['external_request_status']?.toString();
          final meTeamCode = me['participant_team_code']?.toString();
          final teamsRaw = pichanga['teams'] is List
              ? (pichanga['teams'] as List).whereType<Map>().toList()
              : <Map>[];
          final teams = teamsRaw
              .map((item) => item.cast<String, dynamic>())
              .toList();
          final validCodes = teams
              .map((team) => team['code']?.toString() ?? '')
              .where((code) => code.isNotEmpty)
              .toSet();
          if (_selectedTeamCode != null &&
              !validCodes.contains(_selectedTeamCode)) {
            _selectedTeamCode = null;
          }
          final selectedTeamCode =
              _selectedTeamCode ??
              (meTeamCode != null && validCodes.contains(meTeamCode)
                  ? meTeamCode
                  : (teams.isNotEmpty
                        ? teams.first['code']?.toString()
                        : null));

          final title = (pichanga['title'] ?? 'Pichanga #${widget.pichangaId}')
              .toString();
          final startsAt = _formatLocalDateTime(pichanga['starts_at']);
          final spotsLeft = pichanga['spots_left']?.toString() ?? '-';
          final status = (pichanga['status'] ?? '').toString();
          final autoEnabled = pichanga['auto_reminder_enabled'] == true;
          final auto48SentAt = (pichanga['auto_reminder_48h_sent_at'] ?? '')
              .toString();
          final auto24SentAt = (pichanga['auto_reminder_24h_sent_at'] ?? '')
              .toString();

          return ListView(
            padding: const EdgeInsets.all(14),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text('Inicio: $startsAt'),
                      Text('Estado: $status'),
                      Text('Cupos disponibles: $spotsLeft'),
                      if ((pichanga['match_format'] ?? '')
                          .toString()
                          .isNotEmpty)
                        Text(
                          'Formato: ${(pichanga['match_format'] ?? '').toString()} '
                          '• ${pichanga['players_per_team'] ?? '-'} por equipo',
                        ),
                      if ((pichanga['address'] ?? '').toString().isNotEmpty)
                        Text('Dirección: ${pichanga['address']}'),
                      const SizedBox(height: 12),
                      _buildTeamBoardCard(
                        context,
                        ref,
                        teams: teams,
                        participantStatus: participantStatus,
                        isMember: isMember,
                        selectedTeamCode: selectedTeamCode,
                        myTeamCode: meTeamCode,
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          OutlinedButton.icon(
                            onPressed: !isMember && externalStatus != 'pending'
                                ? () => _requestExternal(context, ref)
                                : null,
                            icon: const Icon(Icons.how_to_reg),
                            label: Text(
                              externalStatus == 'pending'
                                  ? 'Solicitud enviada'
                                  : 'Solicitar cupo',
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: isMember
                                ? () => _openRenotifyDialog(context, ref)
                                : null,
                            icon: const Icon(
                              Icons.notifications_active_outlined,
                            ),
                            label: const Text('Avisar de nuevo'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Mi estado: ${participantStatus ?? '-'}'
                        '${meTeamCode != null ? ' • equipo: $meTeamCode' : ''}'
                        '${externalStatus != null ? ' • solicitud: $externalStatus' : ''}',
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Avisos automáticos: ${autoEnabled ? 'activos' : 'desactivados'}',
                      ),
                      Text(
                        'Ola 48h: ${auto48SentAt.isEmpty ? 'pendiente' : _formatLocalDateTime(auto48SentAt)}',
                      ),
                      Text(
                        'Ola 24h: ${auto24SentAt.isEmpty ? 'pendiente' : _formatLocalDateTime(auto24SentAt)}',
                      ),
                    ],
                  ),
                ),
              ),
              _buildWatchActivityCard(context, ref),
              if (isAdmin) _buildExternalRequestsCard(context, ref),
              _buildFeedCard(context, ref),
              _buildRatingsCard(context, ref),
            ],
          );
        },
      ),
    );
  }

  Widget _buildWatchActivityCard(BuildContext context, WidgetRef ref) {
    final heatmapAsync = ref.watch(
      pichangaWatchHeatmapProvider(widget.pichangaId),
    );
    final sessionsAsync = ref.watch(
      pichangaWatchSessionsProvider(widget.pichangaId),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Mi actividad watch',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            heatmapAsync.when(
              loading: () => const LinearProgressIndicator(minHeight: 2),
              error: (error, _) {
                if (error is ApiError && error.statusCode == 404) {
                  return const Text(
                    'Sin sesión watch subida aún para esta pichanga.',
                  );
                }
                return Text('Sin datos watch aún: $error');
              },
              data: (heatmap) {
                final session =
                    (heatmap['session'] as Map?)?.cast<String, dynamic>() ?? {};
                final projected =
                    (heatmap['projected_points'] as List?)
                        ?.whereType<Map>()
                        .map((e) => e.cast<String, dynamic>())
                        .toList() ??
                    const <Map<String, dynamic>>[];
                final raw =
                    (heatmap['raw_normalized_points'] as List?)
                        ?.whereType<Map>()
                        .map((e) => e.cast<String, dynamic>())
                        .toList() ??
                    const <Map<String, dynamic>>[];
                final points = projected.isNotEmpty ? projected : raw;
                final mode = (heatmap['projection_mode'] ?? 'raw').toString();
                final distance = (session['distance_meters'] ?? 0).toString();
                final start = _formatLocalDateTime(session['start_time']);
                final end = _formatLocalDateTime(session['end_time']);
                final hasSamples = points.isNotEmpty;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Distancia: $distance m'),
                    if (start.isNotEmpty) Text('Inicio: $start'),
                    if (end.isNotEmpty) Text('Fin: $end'),
                    Text(
                      'Modo: ${mode == 'projected' ? 'Heatmap cancha' : 'Ruta GPS'}',
                    ),
                    if (session.isNotEmpty && !hasSamples)
                      const Padding(
                        padding: EdgeInsets.only(top: 6),
                        child: Text('Sesión recibida, sincronizando recorrido…'),
                      ),
                    const SizedBox(height: 8),
                    _WatchHeatmapMini(points: points),
                    const SizedBox(height: 8),
                    sessionsAsync.when(
                      loading: () => const SizedBox.shrink(),
                      error: (_, _) => const SizedBox.shrink(),
                      data: (items) {
                        if (items.isEmpty) {
                          return const Text(
                            'Sin sesiones watch sincronizadas.',
                          );
                        }
                        final latest = items.first;
                        final goals = latest['goals_count'] ?? 0;
                        final assists = latest['assists_count'] ?? 0;
                        final finished = items.where((session) {
                          final status = (session['status'] ?? '')
                              .toString()
                              .toLowerCase();
                          return status == 'finished' || status == 'auto_finished';
                        }).toList();
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Goles: $goals • Asistencias: $assists'),
                            if (finished.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              const Text(
                                'Sesiones terminadas',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 4),
                              ...finished.take(3).map((session) {
                                final started = _formatLocalDateTime(
                                  session['start_time'],
                                );
                                final ended = _formatLocalDateTime(
                                  session['end_time'],
                                );
                                final distanceMeters = (session['distance_meters'] ?? 0)
                                    .toString();
                                final goalsCount = session['goals_count'] ?? 0;
                                final assistsCount = session['assists_count'] ?? 0;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Text(
                                    '$started • $distanceMeters m • ⚽ $goalsCount • 🅰️ $assistsCount'
                                    '${ended != '-' ? ' • fin $ended' : ''}',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                );
                              }),
                            ],
                          ],
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatLocalDateTime(dynamic raw) {
    final value = (raw ?? '').toString().trim();
    if (value.isEmpty) {
      return '-';
    }
    final parsed = DateTime.tryParse(value);
    if (parsed == null) {
      return value.replaceFirst('T', ' ');
    }
    final local = parsed.toLocal();
    final dd = local.day.toString().padLeft(2, '0');
    final mm = local.month.toString().padLeft(2, '0');
    final yyyy = local.year.toString();
    final hh = local.hour.toString().padLeft(2, '0');
    final min = local.minute.toString().padLeft(2, '0');
    return '$dd/$mm/$yyyy $hh:$min';
  }

  Widget _buildExternalRequestsCard(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(
      pichangaExternalRequestsProvider(widget.pichangaId),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Solicitudes externas',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            requestsAsync.when(
              loading: () => const LinearProgressIndicator(minHeight: 2),
              error: (error, _) => Text('Error: $error'),
              data: (items) {
                if (items.isEmpty) {
                  return const Text('No hay solicitudes.');
                }

                return Column(
                  children: items.map((item) {
                    final id = int.tryParse(item['id'].toString()) ?? 0;
                    final user =
                        (item['user'] as Map?)?.cast<String, dynamic>() ?? {};
                    final name = (user['nick'] ?? user['name'] ?? '')
                        .toString();
                    final status = (item['status'] ?? '').toString();
                    final degree = item['origin_degree']?.toString() ?? '-';

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('$name (grado $degree)'),
                      subtitle: Text('Estado: $status'),
                      trailing: status == 'pending'
                          ? Wrap(
                              spacing: 4,
                              children: [
                                IconButton(
                                  onPressed: () => _decideExternal(
                                    context,
                                    ref,
                                    requestId: id,
                                    action: 'accept',
                                  ),
                                  icon: const Icon(
                                    Icons.check,
                                    color: Colors.green,
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => _decideExternal(
                                    context,
                                    ref,
                                    requestId: id,
                                    action: 'reject',
                                  ),
                                  icon: const Icon(
                                    Icons.close,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            )
                          : null,
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedCard(BuildContext context, WidgetRef ref) {
    final feedAsync = ref.watch(pichangaFeedProvider(widget.pichangaId));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Feed',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _addPostDialog(context, ref),
                  icon: const Icon(Icons.add_comment_outlined),
                  label: const Text('Publicar'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            feedAsync.when(
              loading: () => const LinearProgressIndicator(minHeight: 2),
              error: (error, _) => Text('Error feed: $error'),
              data: (items) {
                if (items.isEmpty) {
                  return const Text('Sin publicaciones aún.');
                }

                return Column(
                  children: items.map((post) {
                    final postId = int.tryParse(post['id'].toString()) ?? 0;
                    final user =
                        (post['user'] as Map?)?.cast<String, dynamic>() ?? {};
                    final author = (user['nick'] ?? user['name'] ?? 'usuario')
                        .toString();
                    final content = (post['content'] ?? '').toString();
                    final photoUrl = (post['photo_url'] ?? '').toString();
                    final comments = post['comments'] is List
                        ? post['comments'] as List
                        : [];

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(author),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (content.isNotEmpty) Text(content),
                              if (photoUrl.isNotEmpty)
                                Text(
                                  'Foto: $photoUrl',
                                  style: const TextStyle(fontSize: 12),
                                ),
                            ],
                          ),
                        ),
                        if (comments.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(left: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: comments.whereType<Map>().map((
                                comment,
                              ) {
                                final commentUser =
                                    (comment['user'] as Map?)
                                        ?.cast<String, dynamic>() ??
                                    {};
                                final commentAuthor =
                                    (commentUser['nick'] ??
                                            commentUser['name'] ??
                                            'usr')
                                        .toString();
                                return Text(
                                  '• $commentAuthor: ${(comment['content'] ?? '').toString()}',
                                  style: const TextStyle(fontSize: 13),
                                );
                              }).toList(),
                            ),
                          ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton(
                            onPressed: () =>
                                _addCommentDialog(context, ref, postId: postId),
                            child: const Text('Comentar'),
                          ),
                        ),
                        const Divider(),
                      ],
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingsCard(BuildContext context, WidgetRef ref) {
    final ratingsAsync = ref.watch(pichangaRatingsProvider(widget.pichangaId));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Calificaciones',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _addRatingDialog(context, ref),
                  icon: const Icon(Icons.star_border),
                  label: const Text('Calificar'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ratingsAsync.when(
              loading: () => const LinearProgressIndicator(minHeight: 2),
              error: (error, _) => Text('Error ratings: $error'),
              data: (items) {
                if (items.isEmpty) {
                  return const Text('Sin calificaciones todavía.');
                }

                return Column(
                  children: items.map((item) {
                    final rater =
                        (item['rater'] as Map?)?.cast<String, dynamic>() ?? {};
                    final rated =
                        (item['rated'] as Map?)?.cast<String, dynamic>() ?? {};
                    final raterName = (rater['nick'] ?? rater['name'] ?? '')
                        .toString();
                    final ratedName = (rated['nick'] ?? rated['name'] ?? '')
                        .toString();

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('$raterName -> $ratedName'),
                      subtitle: Text(
                        'F:${item['fisico']} A:${item['arquero']} D:${item['delantero']} '
                        'M:${item['mediocampo']} Def:${item['defensa']}',
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamBoardCard(
    BuildContext context,
    WidgetRef ref, {
    required List<Map<String, dynamic>> teams,
    required String? participantStatus,
    required bool isMember,
    required String? selectedTeamCode,
    required String? myTeamCode,
  }) {
    if (teams.isEmpty) {
      return const SizedBox.shrink();
    }

    Widget buildTeamCard(Map<String, dynamic> team) {
      final code = (team['code'] ?? '').toString();
      final label = (team['label'] ?? 'Equipo $code').toString();
      final avgRating = team['avg_rating'];
      final avgText = avgRating == null ? '-' : avgRating.toString();
      final confirmedCount =
          int.tryParse((team['confirmed_count'] ?? 0).toString()) ?? 0;
      final baseSize = int.tryParse((team['base_size'] ?? 0).toString()) ?? 0;
      final slots = team['slots'] is List
          ? (team['slots'] as List)
                .whereType<Map>()
                .map((e) => e.cast<String, dynamic>())
                .toList()
          : <Map<String, dynamic>>[];
      final selected = selectedTeamCode == code;

      return InkWell(
        onTap: isMember
            ? () => setState(() {
                _selectedTeamCode = code;
              })
            : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).dividerColor,
              width: selected ? 2 : 1,
            ),
            color: selected
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.06)
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 4),
              Text('Promedio: $avgText'),
              Text('Confirmados: $confirmedCount / $baseSize'),
              const Divider(height: 14),
              Expanded(
                child: ListView.builder(
                  itemCount: slots.length,
                  itemBuilder: (context, index) {
                    final row = slots[index];
                    final slot =
                        int.tryParse((row['slot'] ?? 0).toString()) ?? 0;
                    final user = row['user'] is Map
                        ? (row['user'] as Map).cast<String, dynamic>()
                        : null;
                    final isMe = user?['is_me'] == true;
                    final displayName = user == null
                        ? '—'
                        : ((user['nick'] ?? user['name'] ?? 'Jugador')
                              .toString());

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        '$slot. $displayName',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: isMe ? FontWeight.w700 : FontWeight.w400,
                          color: isMe
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    }

    final cards = teams.map(buildTeamCard).toList();
    final teamBoard = teams.length <= 2
        ? Row(
            children: [
              for (var index = 0; index < cards.length; index++) ...[
                Expanded(child: SizedBox(height: 290, child: cards[index])),
                if (index < cards.length - 1) const SizedBox(width: 8),
              ],
            ],
          )
        : SizedBox(
            height: 290,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: cards.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                return SizedBox(
                  width: MediaQuery.of(context).size.width * 0.44,
                  child: cards[index],
                );
              },
            ),
          );

    final isConfirmed = participantStatus == 'confirmed';
    final canConfirm = isMember && selectedTeamCode != null && !isConfirmed;
    final canMove =
        isMember &&
        isConfirmed &&
        selectedTeamCode != null &&
        selectedTeamCode != myTeamCode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Selecciona un equipo para confirmar',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        teamBoard,
        const SizedBox(height: 10),
        if (canConfirm)
          FilledButton.icon(
            onPressed: () => _confirmInTeam(
              context,
              ref,
              selectedTeamCode: selectedTeamCode,
            ),
            icon: const Icon(Icons.check_circle_outline),
            label: Text('Confirmar en equipo $selectedTeamCode'),
          ),
        if (canMove)
          FilledButton.icon(
            onPressed: () => _confirmInTeam(
              context,
              ref,
              selectedTeamCode: selectedTeamCode,
            ),
            icon: const Icon(Icons.swap_horiz),
            label: Text('Cambiar al equipo $selectedTeamCode'),
          ),
        if (isConfirmed) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _withdraw(context, ref),
            icon: const Icon(Icons.exit_to_app),
            style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
            label: const Text('Darme de baja'),
          ),
        ],
      ],
    );
  }

  Future<void> _confirmInTeam(
    BuildContext context,
    WidgetRef ref, {
    required String? selectedTeamCode,
  }) async {
    if (selectedTeamCode == null) {
      return;
    }

    await _runAction(
      context,
      ref,
      action: () => ref
          .read(pichangasRepositoryProvider)
          .confirm(widget.pichangaId, selectedTeamCode),
      successMessage: 'Asistencia confirmada en equipo $selectedTeamCode.',
    );
  }

  Future<void> _withdraw(BuildContext context, WidgetRef ref) async {
    await _runAction(
      context,
      ref,
      action: () =>
          ref.read(pichangasRepositoryProvider).withdraw(widget.pichangaId),
      successMessage: 'Te diste de baja.',
    );
  }

  Future<void> _requestExternal(BuildContext context, WidgetRef ref) async {
    await _runAction(
      context,
      ref,
      action: () => ref
          .read(pichangasRepositoryProvider)
          .externalRequest(widget.pichangaId),
      successMessage: 'Solicitud enviada al admin.',
    );
  }

  Future<void> _decideExternal(
    BuildContext context,
    WidgetRef ref, {
    required int requestId,
    required String action,
  }) async {
    await _runAction(
      context,
      ref,
      action: () => ref
          .read(pichangasRepositoryProvider)
          .decideExternalRequest(widget.pichangaId, requestId, action),
      successMessage: action == 'accept'
          ? 'Solicitud aceptada.'
          : 'Solicitud rechazada.',
    );
    ref.invalidate(pichangaExternalRequestsProvider(widget.pichangaId));
  }

  Future<void> _openRenotifyDialog(BuildContext context, WidgetRef ref) async {
    final degreeController = TextEditingController(text: '2');
    final ageMinController = TextEditingController();
    final ageMaxController = TextEditingController();
    final fisicoController = TextEditingController();
    final defensaController = TextEditingController();

    String? sexo;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Avisar de nuevo'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: degreeController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Grado 1/2/3',
                      ),
                    ),
                    DropdownButtonFormField<String?>(
                      initialValue: sexo,
                      decoration: const InputDecoration(labelText: 'Sexo'),
                      items: const [
                        DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Todos'),
                        ),
                        DropdownMenuItem<String?>(
                          value: 'M',
                          child: Text('Hombres'),
                        ),
                        DropdownMenuItem<String?>(
                          value: 'F',
                          child: Text('Mujeres'),
                        ),
                      ],
                      onChanged: (value) => setState(() => sexo = value),
                    ),
                    TextField(
                      controller: ageMinController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Edad mínima',
                      ),
                    ),
                    TextField(
                      controller: ageMaxController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Edad máxima',
                      ),
                    ),
                    TextField(
                      controller: fisicoController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Skill físico mín',
                      ),
                    ),
                    TextField(
                      controller: defensaController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Skill defensa mín',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancelar'),
                ),
                OutlinedButton(
                  onPressed: () async {
                    final body = {
                      'target_degree': int.tryParse(
                        degreeController.text.trim(),
                      ),
                      'audience_sex': sexo,
                      'audience_age_min': int.tryParse(
                        ageMinController.text.trim(),
                      ),
                      'audience_age_max': int.tryParse(
                        ageMaxController.text.trim(),
                      ),
                      'skill_fisico_min': int.tryParse(
                        fisicoController.text.trim(),
                      ),
                      'skill_defensa_min': int.tryParse(
                        defensaController.text.trim(),
                      ),
                    };

                    try {
                      final preview = await ref
                          .read(pichangasRepositoryProvider)
                          .renotifyPreview(widget.pichangaId, body);
                      if (context.mounted) {
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          SnackBar(
                            content: Text(preview['message'].toString()),
                          ),
                        );
                      }
                    } on ApiError catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(
                          dialogContext,
                        ).showSnackBar(SnackBar(content: Text(e.message)));
                      }
                    }
                  },
                  child: const Text('Preview'),
                ),
                FilledButton(
                  onPressed: () async {
                    final body = {
                      'target_degree': int.tryParse(
                        degreeController.text.trim(),
                      ),
                      'audience_sex': sexo,
                      'audience_age_min': int.tryParse(
                        ageMinController.text.trim(),
                      ),
                      'audience_age_max': int.tryParse(
                        ageMaxController.text.trim(),
                      ),
                      'skill_fisico_min': int.tryParse(
                        fisicoController.text.trim(),
                      ),
                      'skill_defensa_min': int.tryParse(
                        defensaController.text.trim(),
                      ),
                    };

                    try {
                      final result = await ref
                          .read(pichangasRepositoryProvider)
                          .renotifySend(widget.pichangaId, body);
                      if (context.mounted) {
                        Navigator.of(dialogContext).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(result['message'].toString())),
                        );
                        ref.invalidate(
                          pichangaDetailProvider(widget.pichangaId),
                        );
                      }
                    } on ApiError catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(
                          dialogContext,
                        ).showSnackBar(SnackBar(content: Text(e.message)));
                      }
                    }
                  },
                  child: const Text('Enviar'),
                ),
              ],
            );
          },
        );
      },
    );

    if (context.mounted) {
      degreeController.dispose();
      ageMinController.dispose();
      ageMaxController.dispose();
      fisicoController.dispose();
      defensaController.dispose();
    }
  }

  Future<void> _addPostDialog(BuildContext context, WidgetRef ref) async {
    final contentController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Nueva publicación'),
          content: TextField(
            controller: contentController,
            decoration: const InputDecoration(labelText: 'Contenido'),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () async {
                final text = contentController.text.trim();
                if (text.isEmpty) {
                  return;
                }

                await _runAction(
                  context,
                  ref,
                  action: () => ref
                      .read(pichangasRepositoryProvider)
                      .addTextPost(widget.pichangaId, text),
                  successMessage: 'Publicación agregada.',
                );
                ref.invalidate(pichangaFeedProvider(widget.pichangaId));
                if (context.mounted) {
                  Navigator.of(dialogContext).pop();
                }
              },
              child: const Text('Publicar'),
            ),
          ],
        );
      },
    );

    if (context.mounted) {
      contentController.dispose();
    }
  }

  Future<void> _addCommentDialog(
    BuildContext context,
    WidgetRef ref, {
    required int postId,
  }) async {
    final contentController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Comentar publicación'),
          content: TextField(
            controller: contentController,
            decoration: const InputDecoration(labelText: 'Comentario'),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () async {
                final text = contentController.text.trim();
                if (text.isEmpty) {
                  return;
                }
                await _runAction(
                  context,
                  ref,
                  action: () => ref
                      .read(pichangasRepositoryProvider)
                      .addComment(widget.pichangaId, postId, text),
                  successMessage: 'Comentario agregado.',
                );
                ref.invalidate(pichangaFeedProvider(widget.pichangaId));
                if (context.mounted) {
                  Navigator.of(dialogContext).pop();
                }
              },
              child: const Text('Comentar'),
            ),
          ],
        );
      },
    );

    if (context.mounted) {
      contentController.dispose();
    }
  }

  Future<void> _addRatingDialog(BuildContext context, WidgetRef ref) async {
    final userIdController = TextEditingController();
    double fisico = 7;
    double arquero = 7;
    double delantero = 7;
    double mediocampo = 7;
    double defensa = 7;
    final comentarioController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            Widget sliderRow(
              String title,
              double value,
              ValueChanged<double> onChanged,
            ) {
              return Row(
                children: [
                  SizedBox(width: 96, child: Text(title)),
                  Expanded(
                    child: Slider(
                      value: value,
                      min: 0,
                      max: 10,
                      divisions: 100,
                      label: value.toStringAsFixed(1),
                      onChanged: onChanged,
                    ),
                  ),
                ],
              );
            }

            return AlertDialog(
              title: const Text('Calificar jugador'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: userIdController,
                      decoration: const InputDecoration(
                        labelText: 'ID del jugador',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    sliderRow(
                      'Físico',
                      fisico,
                      (v) => setState(
                        () => fisico = double.parse(v.toStringAsFixed(1)),
                      ),
                    ),
                    sliderRow(
                      'Arquero',
                      arquero,
                      (v) => setState(
                        () => arquero = double.parse(v.toStringAsFixed(1)),
                      ),
                    ),
                    sliderRow(
                      'Delantero',
                      delantero,
                      (v) => setState(
                        () => delantero = double.parse(v.toStringAsFixed(1)),
                      ),
                    ),
                    sliderRow(
                      'Mediocampo',
                      mediocampo,
                      (v) => setState(
                        () => mediocampo = double.parse(v.toStringAsFixed(1)),
                      ),
                    ),
                    sliderRow(
                      'Defensa',
                      defensa,
                      (v) => setState(
                        () => defensa = double.parse(v.toStringAsFixed(1)),
                      ),
                    ),
                    TextField(
                      controller: comentarioController,
                      decoration: const InputDecoration(
                        labelText: 'Comentario',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () async {
                    final ratedUserId = int.tryParse(
                      userIdController.text.trim(),
                    );
                    if (ratedUserId == null) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(
                          content: Text('ID de jugador inválido.'),
                        ),
                      );
                      return;
                    }

                    await _runAction(
                      context,
                      ref,
                      action: () => ref
                          .read(pichangasRepositoryProvider)
                          .addOrUpdateRating(
                            widget.pichangaId,
                            ratedUserId: ratedUserId,
                            fisico: fisico,
                            arquero: arquero,
                            delantero: delantero,
                            mediocampo: mediocampo,
                            defensa: defensa,
                            comentario: comentarioController.text.trim(),
                          ),
                      successMessage: 'Calificación guardada.',
                    );

                    ref.invalidate(pichangaRatingsProvider(widget.pichangaId));
                    if (context.mounted) {
                      Navigator.of(dialogContext).pop();
                    }
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );

    if (context.mounted) {
      userIdController.dispose();
      comentarioController.dispose();
    }
  }

  Future<void> _runAction(
    BuildContext context,
    WidgetRef ref, {
    required Future<void> Function() action,
    required String successMessage,
  }) async {
    try {
      await action();
      ref.invalidate(pichangaDetailProvider(widget.pichangaId));
      await ref.read(widgetWeeklyServiceProvider).syncAll(ignoreErrors: true);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(successMessage)));
      }
    } on ApiError catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}

class _WatchHeatmapMini extends StatelessWidget {
  const _WatchHeatmapMini({required this.points});

  final List<Map<String, dynamic>> points;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.black12,
      ),
      child: CustomPaint(painter: _WatchHeatmapPainter(points)),
    );
  }
}

class _WatchHeatmapPainter extends CustomPainter {
  _WatchHeatmapPainter(this.points);

  final List<Map<String, dynamic>> points;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) {
      return;
    }

    final paint = Paint()
      ..color = const Color(0xFF0D7A3F)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    final path = Path();

    for (var i = 0; i < points.length; i++) {
      final rawX = (points[i]['x'] is num)
          ? (points[i]['x'] as num).toDouble()
          : 0.0;
      final rawY = (points[i]['y'] is num)
          ? (points[i]['y'] as num).toDouble()
          : 0.0;
      final x = rawX.clamp(0.0, 1.0) * size.width;
      final y = (1 - rawY.clamp(0.0, 1.0)) * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _WatchHeatmapPainter oldDelegate) {
    return oldDelegate.points != points;
  }
}
