import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../pichangas/presentation/pichanga_detail_screen.dart';
import '../data/championships_repository.dart';
import 'championship_invitations_screen.dart';

final championshipsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>(
      (ref) => ref.watch(championshipsRepositoryProvider).list(),
    );

final championshipDetailProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, int>(
      (ref, id) => ref.watch(championshipsRepositoryProvider).detail(id),
    );

final championshipStandingsProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, int>(
      (ref, id) => ref.watch(championshipsRepositoryProvider).standings(id),
    );

final championshipFixtureProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, int>(
      (ref, id) => ref.watch(championshipsRepositoryProvider).fixture(id),
    );

final championshipPlayerStatsProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, int>(
      (ref, id) => ref.watch(championshipsRepositoryProvider).playerStats(id),
    );

final championshipTeamMembersProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, int>(
      (ref, teamId) =>
          ref.watch(championshipsRepositoryProvider).teamMembers(teamId),
    );

class ChampionshipsScreen extends ConsumerWidget {
  const ChampionshipsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncItems = ref.watch(championshipsProvider);
    final invitationCount = ref
        .watch(myChampionshipInvitationsProvider(true))
        .maybeWhen(data: (items) => items.length, orElse: () => 0);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Campeonatos'),
        actions: [
          IconButton(
            tooltip: 'Invitaciones',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const ChampionshipInvitationsScreen(),
              ),
            ),
            icon: Badge(
              isLabelVisible: invitationCount > 0,
              label: Text('$invitationCount'),
              child: const Icon(Icons.mail_outline_rounded),
            ),
          ),
          IconButton(
            tooltip: 'Actualizar',
            onPressed: () => ref.invalidate(championshipsProvider),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: asyncItems.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorState(
          message: 'No se pudieron cargar los campeonatos.',
          onRetry: () => ref.invalidate(championshipsProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const _EmptyState(
              icon: Icons.emoji_events_outlined,
              title: 'Todavía no hay campeonatos',
              subtitle:
                  'Cuando se publique uno, podrás ver su tabla y fixture aquí.',
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(championshipsProvider),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = items[index];
                final id = _asInt(item['id']);
                return _ChampionshipCard(
                  item: item,
                  onTap: id <= 0
                      ? null
                      : () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                ChampionshipDetailScreen(championshipId: id),
                          ),
                        ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class ChampionshipDetailScreen extends ConsumerWidget {
  const ChampionshipDetailScreen({required this.championshipId, super.key});

  final int championshipId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(championshipDetailProvider(championshipId));
    final standings = ref.watch(championshipStandingsProvider(championshipId));
    final fixture = ref.watch(championshipFixtureProvider(championshipId));
    final stats = ref.watch(championshipPlayerStatsProvider(championshipId));

    return Scaffold(
      appBar: AppBar(title: const Text('Campeonato')),
      body: detail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorState(
          message: 'No se pudo cargar el campeonato.',
          onRetry: () =>
              ref.invalidate(championshipDetailProvider(championshipId)),
        ),
        data: (championship) {
          final name = (championship['name'] ?? 'Campeonato').toString();
          final status = _localizedStatus(championship['status']);
          final teams = _asMapList(championship['teams']);
          return DefaultTabController(
            length: 5,
            child: NestedScrollView(
              headerSliverBuilder: (context, _) => [
                SliverToBoxAdapter(
                  child: _ChampionshipHeader(
                    name: name,
                    status: status,
                    championship: championship,
                  ),
                ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _TabBarDelegate(
                    const TabBar(
                      tabs: [
                        Tab(text: 'Tabla'),
                        Tab(text: 'Fixture'),
                        Tab(text: 'En vivo'),
                        Tab(text: 'Equipos'),
                        Tab(text: 'Estadísticas'),
                      ],
                    ),
                  ),
                ),
              ],
              body: TabBarView(
                children: [
                  _StandingsTab(asyncItems: standings),
                  _FixtureTab(asyncItems: fixture),
                  _LiveTab(asyncItems: fixture),
                  _TeamsTab(
                    championshipId: championshipId,
                    teams: teams,
                    viewer: (championship['viewer'] as Map?)
                        ?.cast<String, dynamic>(),
                  ),
                  _PlayerStatsTab(asyncItems: stats),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ChampionshipCard extends StatelessWidget {
  const _ChampionshipCard({required this.item, this.onTap});

  final Map<String, dynamic> item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = _localizedStatus(item['status']);
    final teams = _asInt(item['teams_count']);
    final doubleRound = item['double_round_robin'] == true;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 15, 12, 15),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  Icons.emoji_events_rounded,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (item['name'] ?? 'Campeonato').toString(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '$status · $teams equipos · ${doubleRound ? 'ida y vuelta' : 'una vuelta'}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChampionshipHeader extends StatelessWidget {
  const _ChampionshipHeader({
    required this.name,
    required this.status,
    required this.championship,
  });

  final String name;
  final String status;
  final Map<String, dynamic> championship;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final points =
        (championship['points'] as Map?)?.cast<String, dynamic>() ?? {};
    final startsAt = DateTime.tryParse(
      (championship['starts_at'] ?? '').toString(),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  Chip(
                    avatar: const Icon(Icons.circle, size: 10),
                    label: Text(status),
                  ),
                  Chip(
                    label: Text(
                      '${_asInt(championship['teams_count'])} equipos',
                    ),
                  ),
                  Chip(
                    avatar: Icon(
                      championship['format'] == 'knockout'
                          ? Icons.account_tree_outlined
                          : Icons.sync_alt_rounded,
                      size: 16,
                    ),
                    label: Text(_formatLabel(championship)),
                  ),
                  Chip(
                    label: Text(
                      'Pts ${points['win'] ?? 3}-${points['draw'] ?? 1}-${points['loss'] ?? 0}',
                    ),
                  ),
                ],
              ),
              if (startsAt != null) ...[
                const SizedBox(height: 5),
                Text(
                  'Inicio: ${DateFormat('d MMM yyyy', 'es').format(startsAt)}',
                ),
              ],
              if ((championship['description'] ?? '')
                  .toString()
                  .trim()
                  .isNotEmpty) ...[
                const SizedBox(height: 8),
                Text((championship['description']).toString()),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StandingsTab extends StatelessWidget {
  const _StandingsTab({required this.asyncItems});

  final AsyncValue<List<Map<String, dynamic>>> asyncItems;

  @override
  Widget build(BuildContext context) => asyncItems.when(
    loading: () => const Center(child: CircularProgressIndicator()),
    error: (_, __) => const _EmptyState(
      icon: Icons.table_chart_outlined,
      title: 'Tabla no disponible',
      subtitle: 'Vuelve a intentarlo en unos momentos.',
    ),
    data: (items) => ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Card(
          child: ListTile(
            leading: CircleAvatar(child: Text('${_asInt(item['position'])}')),
            title: Text((item['team_name'] ?? 'Equipo').toString()),
            subtitle: Text(
              'PJ ${_asInt(item['played'])} · GF ${_asInt(item['goals_for'])} · GC ${_asInt(item['goals_against'])} · DG ${_asInt(item['goal_difference'])}',
            ),
            trailing: Text(
              '${_asInt(item['points'])} pts',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        );
      },
    ),
  );
}

class _FixtureTab extends StatelessWidget {
  const _FixtureTab({required this.asyncItems});

  final AsyncValue<List<Map<String, dynamic>>> asyncItems;

  @override
  Widget build(BuildContext context) => asyncItems.when(
    loading: () => const Center(child: CircularProgressIndicator()),
    error: (_, __) => const _EmptyState(
      icon: Icons.event_busy_outlined,
      title: 'Fixture no disponible',
      subtitle: 'Vuelve a intentarlo en unos momentos.',
    ),
    data: (days) => ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: days.length,
      itemBuilder: (context, index) {
        final day = days[index];
        final matches = _asMapList(day['matches']);
        return Card(
          child: ExpansionTile(
            title: Text((day['name'] ?? 'Fecha ${index + 1}').toString()),
            subtitle: Text((day['date'] ?? 'Horario por confirmar').toString()),
            children: matches.isEmpty
                ? [const ListTile(title: Text('Partidos por asignar'))]
                : matches.map((match) => _MatchTile(match: match)).toList(),
          ),
        );
      },
    ),
  );
}

class _MatchTile extends StatelessWidget {
  const _MatchTile({required this.match});

  final Map<String, dynamic> match;

  @override
  Widget build(BuildContext context) {
    final home = (match['home_team'] as Map?)?.cast<String, dynamic>() ?? {};
    final away = (match['away_team'] as Map?)?.cast<String, dynamic>() ?? {};
    final score = (match['score'] as Map?)?.cast<String, dynamic>() ?? {};
    final pichangaId = _asInt(match['pichanga_id']);
    final startsAt = DateTime.tryParse((match['starts_at'] ?? '').toString());
    final endsAt = DateTime.tryParse((match['ends_at'] ?? '').toString());
    final phase = (match['phase'] ?? 'league').toString();
    final round = _asInt(match['bracket_round']);
    final bracketLabel = phase == 'knockout' && round > 0
        ? 'Llave · ronda $round'
        : (phase == 'knockout' ? 'Llaves' : 'Liga');
    final schedule = startsAt == null
        ? 'Horario y cancha por asignar'
        : '${DateFormat('d MMM · HH:mm', 'es').format(startsAt)}${endsAt == null ? '' : '–${DateFormat('HH:mm').format(endsAt)}'}';
    return ListTile(
      dense: true,
      title: Text(
        '${home['name'] ?? 'Local'}  ${score['home'] ?? '-'}  –  ${score['away'] ?? '-'}  ${away['name'] ?? 'Visitante'}',
      ),
      subtitle: Text(
        '$bracketLabel · $schedule${match['field_id'] == null ? '' : ' · Cancha asignada'}',
      ),
      trailing: pichangaId > 0
          ? IconButton(
              tooltip: 'Abrir pichanga',
              icon: const Icon(Icons.sports_soccer_outlined),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => PichangaDetailScreen(pichangaId: pichangaId),
                ),
              ),
            )
          : const Icon(Icons.schedule_outlined),
    );
  }
}

class _LiveTab extends StatelessWidget {
  const _LiveTab({required this.asyncItems});

  final AsyncValue<List<Map<String, dynamic>>> asyncItems;

  @override
  Widget build(BuildContext context) => asyncItems.when(
    loading: () => const Center(child: CircularProgressIndicator()),
    error: (_, __) => const _EmptyState(
      icon: Icons.live_tv_outlined,
      title: 'En vivo no disponible',
      subtitle: 'Vuelve a intentarlo en unos momentos.',
    ),
    data: (days) {
      final matches = days
          .expand((day) => _asMapList(day['matches']))
          .where((match) => match['status'] == 'live')
          .toList();
      if (matches.isEmpty) {
        return const _EmptyState(
          icon: Icons.sports_soccer_outlined,
          title: 'No hay partidos en vivo',
          subtitle:
              'Cuando empiece una pichanga del campeonato, el marcador aparecerá aquí.',
        );
      }
      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: matches.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final match = matches[index];
          final home =
              (match['home_team'] as Map?)?.cast<String, dynamic>() ?? {};
          final away =
              (match['away_team'] as Map?)?.cast<String, dynamic>() ?? {};
          final score = (match['score'] as Map?)?.cast<String, dynamic>() ?? {};
          return Card(
            child: ListTile(
              leading: const Icon(Icons.fiber_manual_record, color: Colors.red),
              title: Text(
                '${home['name'] ?? 'Local'}  ${score['home'] ?? 0} – ${score['away'] ?? 0}  ${away['name'] ?? 'Visitante'}',
              ),
              subtitle: const Text('Partido en curso'),
              trailing: const Icon(Icons.chevron_right_rounded),
            ),
          );
        },
      );
    },
  );
}

class _PlayerStatsTab extends StatelessWidget {
  const _PlayerStatsTab({required this.asyncItems});

  final AsyncValue<List<Map<String, dynamic>>> asyncItems;

  @override
  Widget build(BuildContext context) => asyncItems.when(
    loading: () => const Center(child: CircularProgressIndicator()),
    error: (_, __) => const _EmptyState(
      icon: Icons.query_stats_rounded,
      title: 'Estadísticas no disponibles',
      subtitle: 'Las estadísticas aparecerán después de confirmar actas.',
    ),
    data: (items) {
      if (items.isEmpty) {
        return const _EmptyState(
          icon: Icons.query_stats_rounded,
          title: 'Sin estadísticas todavía',
          subtitle:
              'Confirma convocatorias y resultados para empezar a acumular datos.',
        );
      }
      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final item = items[index];
          final user = (item['user'] as Map?)?.cast<String, dynamic>() ?? {};
          final team = (item['team'] as Map?)?.cast<String, dynamic>();
          return Card(
            child: ListTile(
              leading: CircleAvatar(child: Text('${index + 1}')),
              title: Text(
                (user['nick'] ?? user['name'] ?? 'Jugador').toString(),
              ),
              subtitle: Text(
                '${team?['name'] ?? 'Equipo'} · ${_asInt(item['matches_played'])} PJ · ${_asInt(item['assists'])} asistencias',
              ),
              trailing: Text(
                '${_asInt(item['goals'])} goles',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          );
        },
      );
    },
  );
}

class _TeamsTab extends StatelessWidget {
  const _TeamsTab({
    required this.championshipId,
    required this.teams,
    this.viewer,
  });

  final int championshipId;
  final List<Map<String, dynamic>> teams;
  final Map<String, dynamic>? viewer;

  @override
  Widget build(BuildContext context) {
    if (teams.isEmpty) {
      return const _EmptyState(
        icon: Icons.groups_outlined,
        title: 'Equipos por confirmar',
        subtitle: 'El organizador todavía no ha publicado las plantillas.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: teams.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final team = teams[index];
        final captain = (team['captain'] as Map?)?.cast<String, dynamic>();
        return Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: _asInt(team['id']) <= 0
                ? null
                : () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ChampionshipTeamRosterScreen(
                        championshipId: championshipId,
                        team: team,
                        viewer: viewer,
                      ),
                    ),
                  ),
            child: ListTile(
              leading: CircleAvatar(child: Text('${index + 1}')),
              title: Text((team['name'] ?? 'Equipo').toString()),
              subtitle: Text(
                'Capitán: ${captain?['nick'] ?? 'Por asignar'} · ${_asInt(team['members_count'])} jugadores',
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
            ),
          ),
        );
      },
    );
  }
}

class ChampionshipTeamRosterScreen extends ConsumerStatefulWidget {
  const ChampionshipTeamRosterScreen({
    required this.championshipId,
    required this.team,
    this.viewer,
    super.key,
  });

  final int championshipId;
  final Map<String, dynamic> team;
  final Map<String, dynamic>? viewer;

  @override
  ConsumerState<ChampionshipTeamRosterScreen> createState() =>
      _ChampionshipTeamRosterScreenState();
}

class _ChampionshipTeamRosterScreenState
    extends ConsumerState<ChampionshipTeamRosterScreen> {
  bool _busy = false;

  int get _teamId => _asInt(widget.team['id']);

  // Roster mutations are deliberately deferred from the first mobile
  // delivery. The app remains a read-only championship view; invitation
  // responses are handled from the dedicated invitations screen.
  bool get _canManageRoster => false;

  bool get _canChangeCaptain => false;

  @override
  Widget build(BuildContext context) {
    final members = ref.watch(championshipTeamMembersProvider(_teamId));
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text((widget.team['name'] ?? 'Equipo').toString()),
        actions: [
          if (_canManageRoster)
            IconButton(
              tooltip: 'Invitar jugador',
              onPressed: _busy ? null : _showInviteDialog,
              icon: const Icon(Icons.person_add_alt_1_rounded),
            ),
        ],
      ),
      body: members.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorState(
          message: 'No se pudo cargar la plantilla.',
          onRetry: () =>
              ref.invalidate(championshipTeamMembersProvider(_teamId)),
        ),
        data: (items) {
          if (items.isEmpty) {
            return _EmptyState(
              icon: Icons.groups_outlined,
              title: 'Plantilla por confirmar',
              subtitle: _canManageRoster
                  ? 'Invita jugadores por su nickname para formar el equipo.'
                  : 'El capitán todavía no ha añadido jugadores.',
            );
          }
          return RefreshIndicator(
            onRefresh: () async =>
                ref.invalidate(championshipTeamMembersProvider(_teamId)),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (context, index) {
                final member = items[index];
                final user =
                    (member['user'] as Map?)?.cast<String, dynamic>() ?? {};
                final status = _localizedMemberStatus(member['status']);
                final isCaptain = member['role'] == 'captain';
                return Card(
                  child: ListTile(
                    leading: _MemberAvatar(user: user),
                    title: Text(
                      (user['nick'] ?? user['name'] ?? 'Jugador').toString(),
                    ),
                    subtitle: Text('${isCaptain ? 'Capitán · ' : ''}$status'),
                    trailing:
                        _canManageRoster && !isCaptain && _asInt(user['id']) > 0
                        ? PopupMenuButton<String>(
                            enabled: !_busy,
                            onSelected: (action) {
                              final userId = _asInt(user['id']);
                              if (action == 'captain') {
                                _makeCaptain(userId);
                              } else if (action == 'remove') {
                                _removeMember(userId);
                              }
                            },
                            itemBuilder: (_) => [
                              if (_canChangeCaptain)
                                const PopupMenuItem(
                                  value: 'captain',
                                  child: Text('Hacer capitán'),
                                ),
                              PopupMenuItem(
                                value: 'remove',
                                child: Text(
                                  'Retirar jugador',
                                  style: TextStyle(
                                    color: theme.colorScheme.error,
                                  ),
                                ),
                              ),
                            ],
                          )
                        : null,
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _showInviteDialog() async {
    final controller = TextEditingController();
    final nick = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Invitar jugador'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            labelText: 'Nickname',
            hintText: 'ej. ricci_10',
            prefixIcon: Icon(Icons.alternate_email_rounded),
          ),
          onSubmitted: (_) => Navigator.of(context).pop(controller.text),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Invitar'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (!mounted || nick == null || nick.trim().isEmpty) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(championshipsRepositoryProvider)
          .inviteTeamMember(_teamId, nick: nick);
      ref.invalidate(championshipTeamMembersProvider(_teamId));
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Invitación enviada.')));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('No se pudo enviar: $error')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _removeMember(int userId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Retirar jugador'),
        content: const Text('¿Quieres retirar a este jugador de la plantilla?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Retirar'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(championshipsRepositoryProvider)
          .removeTeamMember(_teamId, userId);
      ref.invalidate(championshipTeamMembersProvider(_teamId));
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('No se pudo retirar: $error')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _makeCaptain(int userId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cambiar capitán'),
        content: const Text('Este jugador será el nuevo capitán del equipo.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(championshipsRepositoryProvider)
          .setCaptain(_teamId, userId);
      ref.invalidate(championshipTeamMembersProvider(_teamId));
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Capitán actualizado.')));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('No se pudo cambiar: $error')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class _MemberAvatar extends StatelessWidget {
  const _MemberAvatar({required this.user});

  final Map<String, dynamic> user;

  @override
  Widget build(BuildContext context) {
    final avatarUrl = (user['avatar_url'] ?? '').toString().trim();
    final nick = (user['nick'] ?? user['name'] ?? 'J').toString();
    return CircleAvatar(
      backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
      child: avatarUrl.isEmpty
          ? Text(nick.isEmpty ? 'J' : nick.substring(0, 1).toUpperCase())
          : null,
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  const _TabBarDelegate(this.tabBar);

  final TabBar tabBar;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(covariant _TabBarDelegate oldDelegate) => false;
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    ),
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 12),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(subtitle, textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}

int _asInt(Object? value) => int.tryParse(value?.toString() ?? '') ?? 0;

List<Map<String, dynamic>> _asMapList(Object? value) {
  if (value is! List) return [];
  return value
      .whereType<Map>()
      .map((item) => item.cast<String, dynamic>())
      .toList();
}

String _localizedStatus(Object? value) {
  switch (value?.toString()) {
    case 'registration':
      return 'Inscripciones';
    case 'published':
      return 'Publicado';
    case 'in_progress':
      return 'En curso';
    case 'completed':
      return 'Finalizado';
    case 'archived':
      return 'Archivado';
    default:
      return 'Borrador';
  }
}

String _formatLabel(Map<String, dynamic> championship) {
  switch (championship['format']?.toString()) {
    case 'knockout':
      return 'Llaves';
    case 'hybrid':
      return 'Liga + playoffs';
    default:
      return championship['double_round_robin'] == true
          ? 'Liga · ida y vuelta'
          : 'Liga · una vuelta';
  }
}

String _localizedMemberStatus(Object? value) {
  switch (value?.toString()) {
    case 'approved':
      return 'Confirmado';
    case 'pending':
      return 'Pendiente de aprobación';
    case 'invited':
      return 'Invitación enviada';
    default:
      return 'Estado por confirmar';
  }
}
