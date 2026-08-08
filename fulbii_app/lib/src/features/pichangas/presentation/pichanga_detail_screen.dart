import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/network/api_error.dart';
import '../../../services/widget/widget_weekly_service.dart';
import '../../auth/session_controller.dart';
import '../../fields/presentation/field_detail_screen.dart';
import '../../profile/presentation/public_player_profile_screen.dart';
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
    .family<Map<String, dynamic>, int>((ref, pichangaId) {
      return ref.watch(pichangasRepositoryProvider).ratingsDetail(pichangaId);
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

final pichangaMatchSummaryProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, int>((ref, pichangaId) {
      return ref.watch(pichangasRepositoryProvider).matchSummary(pichangaId);
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
  int _activeDetailTab = 0;
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
      bottomNavigationBar: detailAsync.maybeWhen(
        data: (data) => _buildBottomAction(
          context,
          ref,
          (data['pichanga'] as Map?)?.cast<String, dynamic>() ?? {},
          (data['me'] as Map?)?.cast<String, dynamic>() ?? {},
        ),
        orElse: () => null,
      ),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            _DetailLoadError(onRetry: () => _refreshDetail(ref)),
        data: (data) {
          final pichanga =
              (data['pichanga'] as Map?)?.cast<String, dynamic>() ?? {};
          final isAuthenticated = ref
              .watch(sessionControllerProvider)
              .isAuthenticated;
          final me = (data['me'] as Map?)?.cast<String, dynamic>() ?? {};
          final isAdmin = me['is_admin'] == true;
          final isMember = me['is_member'] == true;
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

          final tabCount = isAdmin ? 3 : 2;
          final activeTab = _activeDetailTab.clamp(0, tabCount - 1);
          final content = switch (activeTab) {
            0 => _buildSummaryTab(
              context,
              ref,
              pichanga: pichanga,
              teams: teams,
              isMember: isMember,
              isAdmin: isAdmin,
              selectedTeamCode: selectedTeamCode,
              myTeamCode: meTeamCode,
            ),
            1 => Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 112),
              child: Column(
                children: [
                  if (isAuthenticated) ...[
                    _buildWatchActivityCard(context, ref),
                    _buildFeedCard(context, ref),
                    _buildRatingsCard(context, ref),
                  ] else
                    const _DetailEmptyState(
                      icon: Icons.lock_outline,
                      text:
                          'Inicia sesión para ver la actividad de esta pichanga.',
                    ),
                ],
              ),
            ),
            _ => Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 112),
              child: Column(
                children: [
                  _buildManagementCard(context, ref, pichanga),
                  _buildExternalRequestsCard(context, ref),
                ],
              ),
            ),
          };
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _PichangaHero(
                  pichanga: pichanga,
                  onBack: () => Navigator.of(context).maybePop(),
                  onShare: () => _sharePichanga(pichanga),
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _PichangaTabsHeader(
                  color: Theme.of(context).colorScheme.surface,
                  topInset: MediaQuery.paddingOf(context).top,
                  activeIndex: activeTab,
                  labels: ['Resumen', 'Actividad', if (isAdmin) 'Gestión'],
                  onSelected: (index) =>
                      setState(() => _activeDetailTab = index),
                  onBack: () => Navigator.of(context).maybePop(),
                ),
              ),
              SliverToBoxAdapter(child: content),
            ],
          );
        },
      ),
    );
  }

  void _refreshDetail(WidgetRef ref) {
    ref.invalidate(pichangaDetailProvider(widget.pichangaId));
    ref.invalidate(pichangaFeedProvider(widget.pichangaId));
    ref.invalidate(pichangaRatingsProvider(widget.pichangaId));
    ref.invalidate(pichangaExternalRequestsProvider(widget.pichangaId));
    ref.invalidate(pichangaWatchHeatmapProvider(widget.pichangaId));
    ref.invalidate(pichangaWatchSessionsProvider(widget.pichangaId));
  }

  Future<void> _sharePichanga(
    Map<String, dynamic> pichanga,
  ) => SharePlus.instance.share(
    ShareParams(
      subject: (pichanga['title'] ?? 'Pichanga').toString(),
      text:
          'Mira esta pichanga en Fulbii: ${(pichanga['share_url'] ?? '').toString()}',
    ),
  );

  Widget _buildSummaryTab(
    BuildContext context,
    WidgetRef ref, {
    required Map<String, dynamic> pichanga,
    required List<Map<String, dynamic>> teams,
    required bool isMember,
    required bool isAdmin,
    required String? selectedTeamCode,
    required String? myTeamCode,
  }) {
    final address = (pichanga['address'] ?? '').toString().trim();
    final court = (pichanga['court_name'] ?? '').toString().trim();
    final field = (pichanga['field_name'] ?? '').toString().trim();
    final venueFieldId =
        int.tryParse(
          (pichanga['venue_field_id'] ?? pichanga['field_id']).toString(),
        ) ??
        0;
    final confirmed = pichanga['confirmed_count'] ?? 0;
    final capacity = pichanga['capacity'] ?? '-';
    final spots = pichanga['spots_left'] ?? 0;
    final startsAt = _formatTextDateTime(pichanga['starts_at']);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 112),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StatusChip(
            label: (pichanga['status_label'] ?? 'Abierta').toString(),
          ),
          const SizedBox(height: 12),
          Text(
            (pichanga['title'] ?? 'Pichanga').toString(),
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          _InfoCard(
            icon: Icons.calendar_month_outlined,
            title: startsAt,
            subtitle:
                '${pichanga['duration_minutes'] ?? 90} min · ${_formatMatchFormat(pichanga)}',
          ),
          if (court.isNotEmpty || field.isNotEmpty || address.isNotEmpty) ...[
            const SizedBox(height: 8),
            _InfoCard(
              icon: Icons.location_on_outlined,
              title: court.isNotEmpty
                  ? court
                  : (field.isNotEmpty ? field : address),
              subtitle: [
                field,
                address,
              ].where((value) => value.isNotEmpty).join(' · '),
              onTap: venueFieldId <= 0
                  ? null
                  : () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            FieldDetailScreen(fieldId: venueFieldId),
                      ),
                    ),
              trailing: venueFieldId <= 0
                  ? null
                  : const Icon(Icons.chevron_right, size: 22),
            ),
          ],
          const SizedBox(height: 14),
          _CapacityStrip(
            confirmed: '$confirmed',
            capacity: '$capacity',
            spots: '$spots',
          ),
          const SizedBox(height: 24),
          _buildTeamBoardCard(
            context,
            teams: teams,
            clubId: int.tryParse(pichanga['club_id'].toString()) ?? 0,
            isMember: isMember,
            isAdmin: isAdmin,
            selectedTeamCode: selectedTeamCode,
            myTeamCode: myTeamCode,
          ),
          if ((pichanga['phase'] ?? '').toString() == 'finished') ...[
            const SizedBox(height: 20),
            _buildMatchSummaryCard(context, ref, pichanga),
          ],
        ],
      ),
    );
  }

  Widget? _buildBottomAction(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> pichanga,
    Map<String, dynamic> me,
  ) {
    final teams = pichanga['teams'] is List
        ? (pichanga['teams'] as List)
              .whereType<Map>()
              .map((team) => team.cast<String, dynamic>())
              .toList()
        : <Map<String, dynamic>>[];
    final selected =
        _selectedTeamCode ??
        me['participant_team_code']?.toString() ??
        (teams.isEmpty ? null : teams.first['code']?.toString());
    final mine = me['participant_team_code']?.toString();
    final confirmed = me['participant_status']?.toString() == 'confirmed';
    final canConfirm = me['can_confirm'] == true && selected != null;
    final canChange =
        me['can_change_team'] == true && selected != null && selected != mine;
    final canWithdraw = me['can_withdraw'] == true;
    final canRequest = me['can_request_external'] == true;
    final pending = me['external_request_status']?.toString() == 'pending';

    if (!canConfirm &&
        !canChange &&
        !canWithdraw &&
        !canRequest &&
        !pending &&
        !confirmed) {
      return null;
    }
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(
            top: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (canConfirm)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () =>
                      _confirmInTeam(context, ref, selectedTeamCode: selected),
                  icon: const Icon(Icons.check_circle_outline),
                  label: Text('Confirmar en Equipo $selected'),
                ),
              )
            else if (canChange && !canWithdraw)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () =>
                      _confirmInTeam(context, ref, selectedTeamCode: selected),
                  icon: const Icon(Icons.swap_horiz),
                  label: Text('Cambiar a Equipo $selected'),
                ),
              )
            else if (canRequest)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _requestExternal(context, ref),
                  icon: const Icon(Icons.person_add_alt_1),
                  label: const Text('Solicitar cupo'),
                ),
              )
            else if (pending)
              const _PendingRequestNotice()
            else if (confirmed)
              _ConfirmedNotice(teamCode: mine),
            if (canWithdraw) ...[
              if (canChange) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: FilledButton.icon(
                        onPressed: () => _confirmInTeam(
                          context,
                          ref,
                          selectedTeamCode: selected,
                        ),
                        icon: const Icon(Icons.swap_horiz),
                        label: Text('Cambiar a Equipo $selected'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: OutlinedButton.icon(
                        onPressed: () => _confirmWithdraw(context, ref),
                        icon: const Icon(Icons.logout, size: 18),
                        label: const Text('Darme de baja'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.error,
                          side: BorderSide(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ] else
                TextButton.icon(
                  onPressed: () => _confirmWithdraw(context, ref),
                  icon: const Icon(Icons.logout, size: 18),
                  label: const Text('Darme de baja'),
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _confirmWithdraw(BuildContext context, WidgetRef ref) async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('¿Darte de baja?'),
        content: const Text('Tu cupo quedará disponible para otro jugador.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Darme de baja'),
          ),
        ],
      ),
    );
    if (accepted == true && context.mounted) {
      await _withdraw(context, ref);
    }
  }

  Widget _buildManagementCard(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> pichanga,
  ) {
    final autoEnabled = pichanga['auto_reminder_enabled'] == true;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Gestión de la pichanga',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'Avisos automáticos ${autoEnabled ? 'activos' : 'desactivados'}.',
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => _openRenotifyDialog(context, ref),
              icon: const Icon(Icons.notifications_active_outlined),
              label: const Text('Avisar de nuevo'),
            ),
          ],
        ),
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
                        child: Text(
                          'Sesión recibida, sincronizando recorrido…',
                        ),
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
                          return status == 'finished' ||
                              status == 'auto_finished';
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
                                final distanceMeters =
                                    (session['distance_meters'] ?? 0)
                                        .toString();
                                final goalsCount = session['goals_count'] ?? 0;
                                final assistsCount =
                                    session['assists_count'] ?? 0;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Text(
                                    '$started • $distanceMeters m • ⚽ $goalsCount • 🅰️ $assistsCount'
                                    '${ended != '-' ? ' • fin $ended' : ''}',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
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

  String _formatTextDateTime(dynamic raw) {
    final value = (raw ?? '').toString().trim();
    if (value.isEmpty) {
      return '-';
    }
    final parsed = DateTime.tryParse(value);
    if (parsed == null) {
      return value.replaceFirst('T', ' ');
    }
    final local = parsed.toLocal();
    const days = [
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo',
    ];
    const months = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre',
    ];
    final dayName = days[local.weekday - 1];
    final monthName = months[local.month - 1];
    final dayNum = local.day;
    final year = local.year;

    final hour = local.hour;
    final period = hour >= 12 ? 'PM' : 'AM';
    final hour12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final minuteStr = local.minute.toString().padLeft(2, '0');
    final hourStr = hour12.toString().padLeft(2, '0');

    return '$dayName, $dayNum de $monthName de $year · $hourStr:$minuteStr $period';
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
    final hour = local.hour;
    final period = hour >= 12 ? 'PM' : 'AM';
    final hour12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final min = local.minute.toString().padLeft(2, '0');
    final hh = hour12.toString().padLeft(2, '0');
    return '$dd/$mm/$yyyy $hh:$min $period';
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
                          trailing: Text(
                            _formatLocalDateTime(post['created_at']),
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
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
                ratingsAsync.when(
                  loading: () => const SizedBox(width: 32, height: 32),
                  error: (_, _) => const SizedBox.shrink(),
                  data: (data) => TextButton.icon(
                    onPressed: data['can_rate'] == true
                        ? () => _addRatingDialog(context, ref)
                        : null,
                    icon: const Icon(Icons.star_border),
                    label: const Text('Calificar'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ratingsAsync.when(
              loading: () => const LinearProgressIndicator(minHeight: 2),
              error: (error, _) => Text('Error ratings: $error'),
              data: (data) {
                final items = data['items'] is List
                    ? data['items'] as List
                    : [];
                final leaders = data['leaders'] is List
                    ? data['leaders'] as List
                    : [];
                if (items.isEmpty) {
                  return const Text(
                    'Aún no hay calificaciones. Cuando termine la pichanga, evalúa a tus compañeros confirmados.',
                  );
                }

                final ratingTiles = items.map((item) {
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
                }).toList();
                return Column(
                  children: [
                    if (leaders.isNotEmpty) ...[
                      ListTile(
                        leading: const Icon(Icons.workspace_premium_outlined),
                        title: Text(
                          'Mejor jugador: ${(leaders.first as Map)['nick'] ?? 'Jugador'}',
                        ),
                        subtitle: Text(
                          '★ ${((leaders.first as Map)['score'] as num?)?.toStringAsFixed(1) ?? '—'} · ${(leaders.first as Map)['votes'] ?? 0} votos',
                        ),
                      ),
                      const Divider(),
                    ],
                    ...ratingTiles,
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchSummaryCard(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> pichanga,
  ) {
    final summary = ref.watch(pichangaMatchSummaryProvider(widget.pichangaId));
    final clubId = int.tryParse(pichanga['club_id'].toString()) ?? 0;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: summary.when(
          loading: () => const LinearProgressIndicator(minHeight: 2),
          error: (error, _) => const Text(
            'El resumen del partido no está disponible para este usuario.',
          ),
          data: (data) {
            final score =
                (data['score'] as List?)
                    ?.whereType<Map>()
                    .map((item) => item.cast<String, dynamic>())
                    .toList() ??
                [];
            final events =
                (data['events'] as List?)
                    ?.whereType<Map>()
                    .map((item) => item.cast<String, dynamic>())
                    .toList() ??
                [];
            if (data['has_watch_data'] != true) {
              return const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Resumen del partido',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Aún no hay eventos Watch sincronizados para este partido.',
                  ),
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Resumen del partido',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 10),
                Text(
                  score
                      .map(
                        (item) =>
                            'Equipo ${item['team_code']} ${item['goals']}',
                      )
                      .join('  ·  '),
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 10),
                ...events.map((event) {
                  final player =
                      (event['player'] as Map?)?.cast<String, dynamic>() ?? {};
                  final name = (player['nick'] ?? player['name'] ?? 'Jugador')
                      .toString();
                  final userId = int.tryParse(player['id'].toString()) ?? 0;
                  final type = event['type'] == 'goal' ? 'Gol' : 'Pase gol';
                  final minute = event['minute'] == null
                      ? ''
                      : "${event['minute']}'";
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      event['type'] == 'goal'
                          ? Icons.sports_soccer
                          : Icons.assistant_outlined,
                    ),
                    title: Text('$type · $name'),
                    subtitle: Text(
                      'Equipo ${event['team_code']} ${minute.isEmpty ? '' : '· $minute'}',
                    ),
                    onTap: clubId <= 0 || userId <= 0
                        ? null
                        : () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => PublicPlayerProfileScreen(
                                clubId: clubId,
                                userId: userId,
                              ),
                            ),
                          ),
                  );
                }),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _openFormation(
    BuildContext context,
    String teamCode,
    bool isAdmin,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _FormationSheet(
        pichangaId: widget.pichangaId,
        teamCode: teamCode,
        isAdmin: isAdmin,
        onApplied: () => _refreshDetail(ref),
      ),
    );
  }

  Widget _buildTeamBoardCard(
    BuildContext context, {
    required List<Map<String, dynamic>> teams,
    required int clubId,
    required bool isMember,
    required bool isAdmin,
    required String? selectedTeamCode,
    required String? myTeamCode,
  }) {
    if (teams.isEmpty) {
      return const SizedBox.shrink();
    }

    final screenWidth = MediaQuery.sizeOf(context).width;
    final cardWidth = ((screenWidth - 32 - 20) / 2.45).clamp(136.0, 165.0);

    Widget buildTeamCard(Map<String, dynamic> team) {
      final code = (team['code'] ?? '').toString();
      final label = (team['label'] ?? 'Equipo $code').toString();
      final avgRating = team['avg_rating'];
      final avgText = avgRating is num
          ? '★ ${avgRating.toDouble().toStringAsFixed(1)}'
          : 'Sin rating';
      final confirmedCount =
          int.tryParse((team['confirmed_count'] ?? 0).toString()) ?? 0;
      final baseSize = int.tryParse((team['base_size'] ?? 0).toString()) ?? 0;
      final slots = team['slots'] is List
          ? (team['slots'] as List)
                .whereType<Map>()
                .map((e) => e.cast<String, dynamic>())
                .toList()
          : <Map<String, dynamic>>[];
      final confirmedSlots = slots
          .where((slot) => slot['user'] is Map)
          .toList();
      final selected = selectedTeamCode == code;
      final isMyTeam = myTeamCode == code;

      return Stack(
        clipBehavior: Clip.none,
        children: [
          InkWell(
            onTap: isMember
                ? () => setState(() {
                    _selectedTeamCode = code;
                  })
                : null,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: cardWidth,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).dividerColor,
                  width: selected ? 2 : 1,
                ),
                color: selected
                    ? Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.06)
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                              ),
                        ),
                      ),
                      if ((isAdmin || isMyTeam) && confirmedCount > 0)
                        IconButton(
                          key: Key('team-formation-$code'),
                          tooltip: 'Ver formación',
                          icon: const Icon(
                            Icons.sports_soccer_outlined,
                            size: 18,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints.tightFor(
                            width: 32,
                            height: 32,
                          ),
                          visualDensity: VisualDensity.compact,
                          onPressed: () =>
                              _openFormation(context, code, isAdmin),
                        ),
                      if (selected)
                        Icon(
                          Icons.check_circle,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        avgText,
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '$confirmedCount/$baseSize',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                fontSize: 10,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  Expanded(
                    child: confirmedSlots.isEmpty
                        ? Center(
                            child: Text(
                              'Sin miembros',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.outline,
                                    fontStyle: FontStyle.italic,
                                    fontSize: 11,
                                  ),
                            ),
                          )
                        : ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            itemCount: confirmedSlots.length,
                            padding: EdgeInsets.zero,
                            itemBuilder: (context, idx) {
                              final slot = confirmedSlots[idx];
                              final user = (slot['user'] as Map)
                                  .cast<String, dynamic>();
                              final name =
                                  (user['nick'] ?? user['name'] ?? 'Jugador')
                                      .toString();
                              final userId =
                                  int.tryParse(user['id'].toString()) ?? 0;
                              final isMe = user['is_me'] == true;

                              final userRatingRaw = user['avg_rating'];
                              final userRatingStr = userRatingRaw is num
                                  ? userRatingRaw.toDouble().toStringAsFixed(1)
                                  : '-';

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Row(
                                  children: [
                                    InkResponse(
                                      onTap: (clubId <= 0 || userId <= 0)
                                          ? null
                                          : () => Navigator.of(context).push(
                                              MaterialPageRoute<void>(
                                                builder: (_) =>
                                                    PublicPlayerProfileScreen(
                                                      clubId: clubId,
                                                      userId: userId,
                                                    ),
                                              ),
                                            ),
                                      radius: 18,
                                      child: Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary
                                              .withValues(alpha: 0.15),
                                          border: Border.all(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                            width: 1.2,
                                          ),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          userRatingStr,
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w900,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              fontWeight: isMe
                                                  ? FontWeight.w900
                                                  : FontWeight.w500,
                                              fontSize: 12,
                                              color: isMe
                                                  ? Theme.of(
                                                      context,
                                                    ).colorScheme.primary
                                                  : Theme.of(
                                                      context,
                                                    ).colorScheme.onSurface,
                                            ),
                                      ),
                                    ),
                                    if (isAdmin && !isMe)
                                      IconButton(
                                        tooltip: 'Mover de equipo',
                                        icon: const Icon(
                                          Icons.swap_horiz,
                                          size: 17,
                                        ),
                                        visualDensity: VisualDensity.compact,
                                        onPressed: () => _openMovePlayer(
                                          context,
                                          userId,
                                          name,
                                          teams,
                                          code,
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isMyTeam
                        ? '★ Tu equipo'
                        : (baseSize > confirmedCount
                              ? '${baseSize - confirmedCount} cupos libres'
                              : 'Equipo lleno'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: isMyTeam || baseSize > confirmedCount
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.outline,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Equipos',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        Text(
          isMember
              ? 'Toca un equipo para seleccionarlo.'
              : 'Plantillas y disponibilidad por equipo.',
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 245,
          child: ListView.separated(
            physics: const BouncingScrollPhysics(),
            scrollDirection: Axis.horizontal,
            itemCount: teams.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (_, index) => buildTeamCard(teams[index]),
          ),
        ),
        if (myTeamCode != null) ...[
          const SizedBox(height: 10),
          Text(
            'Tu equipo actual: $myTeamCode',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _openMovePlayer(
    BuildContext context,
    int userId,
    String name,
    List<Map<String, dynamic>> teams,
    String currentTeam,
  ) async {
    final target = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(title: Text('Mover a $name')),
            ...teams
                .where((team) => team['code']?.toString() != currentTeam)
                .map((team) {
                  final code = team['code']?.toString() ?? '';
                  return ListTile(
                    leading: const Icon(Icons.groups_outlined),
                    title: Text('Equipo $code'),
                    onTap: () => Navigator.of(context).pop(code),
                  );
                }),
          ],
        ),
      ),
    );
    if (target == null || userId <= 0) return;
    if (!context.mounted) return;
    await _runAction(
      context,
      ref,
      action: () => ref
          .read(pichangasRepositoryProvider)
          .moveParticipantTeam(widget.pichangaId, userId, target),
      successMessage: '$name fue movido a Equipo $target.',
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
                      'skill_fisico_min': double.tryParse(
                        fisicoController.text.trim(),
                      ),
                      'skill_defensa_min': double.tryParse(
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
                      'skill_fisico_min': double.tryParse(
                        fisicoController.text.trim(),
                      ),
                      'skill_defensa_min': double.tryParse(
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
    final ratingData = await ref.read(
      pichangaRatingsProvider(widget.pichangaId).future,
    );
    final eligible = (ratingData['eligible_players'] as List? ?? [])
        .whereType<Map>()
        .map((item) => item.cast<String, dynamic>())
        .toList();
    final alreadyRated = (ratingData['my_rated_user_ids'] as List? ?? [])
        .map((id) => int.tryParse(id.toString()) ?? 0)
        .toSet();
    final candidates = eligible
        .where(
          (player) => !alreadyRated.contains(
            int.tryParse(player['id'].toString()) ?? 0,
          ),
        )
        .toList();
    if (candidates.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No tienes compañeros confirmados pendientes por calificar.',
            ),
          ),
        );
      }
      return;
    }
    if (!context.mounted) return;
    int? ratedUserId = int.tryParse(candidates.first['id'].toString());
    double fisico = 2.5;
    double arquero = 2.5;
    double delantero = 2.5;
    double mediocampo = 2.5;
    double defensa = 2.5;
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
                      max: 5,
                      divisions: 50,
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
                    DropdownButtonFormField<int>(
                      initialValue: ratedUserId,
                      decoration: const InputDecoration(
                        labelText: 'Jugador confirmado',
                      ),
                      items: candidates
                          .map(
                            (player) => DropdownMenuItem(
                              value: int.tryParse(player['id'].toString()),
                              child: Text(
                                (player['nick'] ?? player['name'] ?? 'Jugador')
                                    .toString(),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) => setState(() => ratedUserId = value),
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
                            ratedUserId: ratedUserId!,
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

class _PichangaTabsHeader extends SliverPersistentHeaderDelegate {
  _PichangaTabsHeader({
    required this.color,
    required this.topInset,
    required this.labels,
    required this.activeIndex,
    required this.onSelected,
    required this.onBack,
  });

  final Color color;
  final double topInset;
  final List<String> labels;
  final int activeIndex;
  final ValueChanged<int> onSelected;
  final VoidCallback onBack;

  @override
  double get minExtent => 58 + topInset;

  @override
  double get maxExtent => 58 + topInset;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => Material(
    color: color,
    elevation: overlapsContent ? 2 : 0,
    child: Padding(
      padding: EdgeInsets.only(top: topInset),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Volver',
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_ios_new),
          ),
          Expanded(
            child: Row(
              children: List.generate(labels.length, (index) {
                final selected = index == activeIndex;
                return Expanded(
                  child: InkWell(
                    onTap: () => onSelected(index),
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: selected
                                ? Theme.of(context).colorScheme.primary
                                : Colors.transparent,
                            width: 3,
                          ),
                        ),
                      ),
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 150),
                        style: Theme.of(context).textTheme.titleSmall!.copyWith(
                          color: selected
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: selected
                              ? FontWeight.w800
                              : FontWeight.w600,
                        ),
                        child: Text(labels[index]),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    ),
  );

  @override
  bool shouldRebuild(covariant _PichangaTabsHeader oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.topInset != topInset ||
      oldDelegate.activeIndex != activeIndex ||
      oldDelegate.labels.length != labels.length;
}

class _PichangaHero extends StatelessWidget {
  const _PichangaHero({
    required this.pichanga,
    required this.onBack,
    required this.onShare,
  });

  final Map<String, dynamic> pichanga;
  final VoidCallback onBack;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final photo = (pichanga['venue_photo_url'] ?? '').toString();
    return SizedBox(
      height: 235,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (photo.isNotEmpty)
            Image.network(
              photo,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const _VenuePlaceholder(),
            )
          else
            const _VenuePlaceholder(),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.4),
                  Colors.black.withValues(alpha: 0.05),
                ],
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HeroAction(
                    icon: Icons.arrow_back_ios_new,
                    tooltip: 'Volver',
                    onTap: onBack,
                  ),
                  _HeroAction(
                    icon: Icons.ios_share_outlined,
                    tooltip: 'Compartir',
                    onTap: onShare,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VenuePlaceholder extends StatelessWidget {
  const _VenuePlaceholder();
  @override
  Widget build(BuildContext context) => ColoredBox(
    color: const Color(0xFF263128),
    child: Center(
      child: Icon(
        Icons.sports_soccer,
        size: 64,
        color: Theme.of(context).colorScheme.primary,
      ),
    ),
  );
}

class _HeroAction extends StatelessWidget {
  const _HeroAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.black.withValues(alpha: 0.48),
    shape: const CircleBorder(),
    child: IconButton(
      tooltip: tooltip,
      onPressed: onTap,
      color: Colors.white,
      icon: Icon(icon),
    ),
  );
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.primaryContainer,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      label,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: Theme.of(context).colorScheme.onPrimaryContainer,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.trailing,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    child: ListTile(
      onTap: onTap,
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: subtitle.isEmpty ? null : Text(subtitle),
      trailing: trailing,
    ),
  );
}

class _CapacityStrip extends StatelessWidget {
  const _CapacityStrip({
    required this.confirmed,
    required this.capacity,
    required this.spots,
  });
  final String confirmed;
  final String capacity;
  final String spots;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        Icon(
          Icons.groups_2_outlined,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            '$confirmed / $capacity confirmados',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        Text(
          '$spots cupos',
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    ),
  );
}

class _PendingRequestNotice extends StatelessWidget {
  const _PendingRequestNotice();
  @override
  Widget build(BuildContext context) => const Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(Icons.schedule, size: 18),
      SizedBox(width: 8),
      Text('Solicitud enviada'),
    ],
  );
}

class _ConfirmedNotice extends StatelessWidget {
  const _ConfirmedNotice({required this.teamCode});
  final String? teamCode;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary),
      const SizedBox(width: 8),
      Text(
        'Estás en Equipo ${teamCode ?? ''}',
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
    ],
  );
}

class _DetailLoadError extends StatelessWidget {
  const _DetailLoadError({required this.onRetry});
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
    child: FilledButton.icon(
      onPressed: onRetry,
      icon: const Icon(Icons.refresh),
      label: const Text('Reintentar'),
    ),
  );
}

class _DetailEmptyState extends StatelessWidget {
  const _DetailEmptyState({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(32),
    child: Column(
      children: [
        Icon(icon, size: 40),
        const SizedBox(height: 12),
        Text(text, textAlign: TextAlign.center),
      ],
    ),
  );
}

String _formatMatchFormat(Map<String, dynamic> pichanga) {
  final teams = pichanga['team_count'] ?? 2;
  final perTeam = pichanga['players_per_team'] ?? '-';
  return '$teams equipos · $perTeam por equipo';
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

class _FormationSheet extends ConsumerStatefulWidget {
  const _FormationSheet({
    required this.pichangaId,
    required this.teamCode,
    required this.isAdmin,
    required this.onApplied,
  });
  final int pichangaId;
  final String teamCode;
  final bool isAdmin;
  final VoidCallback onApplied;
  @override
  ConsumerState<_FormationSheet> createState() => _FormationSheetState();
}

class _FormationSheetState extends ConsumerState<_FormationSheet> {
  late Future<List<Map<String, dynamic>>> _future;
  List<Map<String, dynamic>>? _positions;
  bool _saving = false;
  static const _labels = {
    'goalkeeper': 'Arquero',
    'defender': 'Defensa',
    'midfielder': 'Mediocampo',
    'forward': 'Delantero',
  };

  @override
  void initState() {
    super.initState();
    _future = ref
        .read(pichangasRepositoryProvider)
        .formationSuggestion(widget.pichangaId, widget.teamCode);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .76,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'No se pudo generar la sugerencia: ${snapshot.error}',
                  ),
                );
              }
              _positions ??= snapshot.data ?? [];
              _ensurePitchPositions();
              if (_positions!.isEmpty) {
                return const Center(
                  child: Text(
                    'Aún no hay jugadores confirmados para sugerir una formación.',
                  ),
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Formación sugerida · Equipo ${widget.teamCode}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Arrastra a cada jugador dentro de la cancha y aplica los cambios cuando estés listo.',
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    child: Center(
                      child: AspectRatio(
                        aspectRatio: 2 / 3,
                        child: _FormationPitch(
                          positions: _positions!,
                          labels: _labels,
                          onMove: _movePlayer,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _saving ? null : _apply,
                      icon: const Icon(Icons.check_circle_outline),
                      label: Text(_saving ? 'Guardando…' : 'Aplicar formación'),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _ensurePitchPositions() {
    final byRole = <String, List<Map<String, dynamic>>>{};
    for (final item in _positions!) {
      final role = (item['formation_role'] ?? 'midfielder').toString();
      (byRole[role] ??= []).add(item);
    }
    for (final entry in byRole.entries) {
      for (var index = 0; index < entry.value.length; index++) {
        final item = entry.value[index];
        final x = item['formation_x'];
        final y = item['formation_y'];
        if (x is num && y is num) continue;
        final count = entry.value.length;
        final spread = (index + 1) / (count + 1);
        item['formation_x'] = entry.key == 'goalkeeper'
            ? .5
            : .12 + .76 * spread;
        item['formation_y'] = switch (entry.key) {
          'goalkeeper' => .88,
          'defender' => .68,
          'forward' => .22,
          _ => .46,
        };
      }
    }
  }

  void _movePlayer(int index, Offset delta, Size pitchSize) {
    final item = _positions![index];
    final x =
        ((item['formation_x'] as num).toDouble() + delta.dx / pitchSize.width)
            .clamp(.06, .94);
    final y =
        ((item['formation_y'] as num).toDouble() + delta.dy / pitchSize.height)
            .clamp(.05, .95);
    setState(() {
      item['formation_x'] = x;
      item['formation_y'] = y;
    });
  }

  Future<void> _apply() async {
    setState(() => _saving = true);
    try {
      final positions = _positions!
          .asMap()
          .entries
          .map(
            (entry) => {
              'user_id': entry.value['user_id'],
              'formation_role': entry.value['formation_role'],
              'formation_order': entry.key + 1,
              'formation_x': entry.value['formation_x'],
              'formation_y': entry.value['formation_y'],
            },
          )
          .toList();
      await ref
          .read(pichangasRepositoryProvider)
          .updateFormation(widget.pichangaId, widget.teamCode, positions);
      widget.onApplied();
      if (mounted) {
        Navigator.of(context).pop();
      }
    } on ApiError catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }
}

class _FormationPitch extends StatelessWidget {
  const _FormationPitch({
    required this.positions,
    required this.labels,
    required this.onMove,
  });

  final List<Map<String, dynamic>> positions;
  final Map<String, String> labels;
  final void Function(int index, Offset delta, Size pitchSize) onMove;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) => ClipRRect(
        key: const Key('formation-pitch'),
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/share/lineup_7v7_template.png',
              fit: BoxFit.cover,
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(
                  color: colors.primary.withValues(alpha: .7),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            ...positions.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final x = (item['formation_x'] as num).toDouble();
              final y = (item['formation_y'] as num).toDouble();
              final name = (item['nick'] ?? item['name'] ?? 'Jugador')
                  .toString();
              final role = (item['formation_role'] ?? 'midfielder').toString();
              return Positioned(
                left: x * constraints.maxWidth - 24,
                top: y * constraints.maxHeight - 25,
                child: GestureDetector(
                  key: Key('formation-player-${item['user_id']}'),
                  onPanUpdate: (details) =>
                      onMove(index, details.delta, constraints.biggest),
                  child: Semantics(
                    label: '$name, ${labels[role] ?? role}',
                    child: SizedBox(
                      width: 48,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: colors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: Text(
                              name.isEmpty
                                  ? '?'
                                  : name.substring(0, 1).toUpperCase(),
                              style: TextStyle(
                                color: colors.onPrimary,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              shadows: [
                                Shadow(color: Colors.black, blurRadius: 3),
                              ],
                            ),
                          ),
                          Text(
                            labels[role] ?? role,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 8,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
