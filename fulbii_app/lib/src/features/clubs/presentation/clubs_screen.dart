import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/app_config.dart';
import '../../../core/network/api_error.dart';
import '../../auth/presentation/login_required_sheet.dart';
import '../../auth/session_controller.dart';
import '../data/clubs_repository.dart';
import 'club_scope_filter.dart';
import 'club_detail_screen.dart';
import 'create_club_screen.dart';

final mineClubsProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, String>((ref, q) async {
      return ref.watch(clubsRepositoryProvider).listClubs(scope: 'mine', q: q);
    });

final discoverClubsProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, String>((ref, q) async {
      return ref
          .watch(clubsRepositoryProvider)
          .listClubs(scope: 'discover', q: q);
    });

final myInvitationsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>(
      (ref) => ref.watch(clubsRepositoryProvider).myInvitations(),
    );

class ClubsScreen extends ConsumerStatefulWidget {
  const ClubsScreen({super.key});

  @override
  ConsumerState<ClubsScreen> createState() => _ClubsScreenState();
}

class _ClubsScreenState extends ConsumerState<ClubsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _searchController = TextEditingController();
  String _q = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAuthenticated = ref
        .watch(sessionControllerProvider)
        .isAuthenticated;
    final mineAsync = isAuthenticated ? ref.watch(mineClubsProvider('')) : null;
    final discoverAsync = ref.watch(discoverClubsProvider(_q));
    final mineClubIds =
        mineAsync?.valueOrNull
            ?.map((club) => int.tryParse(club['id'].toString()))
            .whereType<int>()
            .toSet() ??
        <int>{};
    final invitationsAsync = isAuthenticated
        ? ref.watch(myInvitationsProvider)
        : const AsyncData<List<Map<String, dynamic>>>([]);

    if (!isAuthenticated) {
      return SafeArea(
        top: true,
        bottom: false,
        child: _buildDiscoverTab(discoverAsync),
      );
    }

    return SafeArea(
      top: true,
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: invitationsAsync.when(
              data: (items) {
                if (items.isEmpty) {
                  return const SizedBox.shrink();
                }

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Invitaciones pendientes (${items.length})',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        ...items.take(3).map((item) {
                          final club = item['club'] as Map?;
                          final clubName = (club?['nombre'] ?? 'Grupo')
                              .toString();
                          final invitationId = int.tryParse(
                            item['id'].toString(),
                          );

                          return Row(
                            children: [
                              Expanded(child: Text(clubName)),
                              TextButton(
                                onPressed: invitationId == null
                                    ? null
                                    : () => _respondInvitation(
                                        invitationId,
                                        'accept',
                                      ),
                                child: const Text('Aceptar'),
                              ),
                              TextButton(
                                onPressed: invitationId == null
                                    ? null
                                    : () => _respondInvitation(
                                        invitationId,
                                        'reject',
                                      ),
                                child: const Text('Rechazar'),
                              ),
                            ],
                          );
                        }),
                      ],
                    ),
                  ),
                );
              },
              loading: () => const LinearProgressIndicator(minHeight: 2),
              error: (error, stackTrace) => const SizedBox.shrink(),
            ),
          ),
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Mis grupos'),
              Tab(text: 'Descubrir grupos'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildClubList(mineAsync!, showCreateButton: true),
                _buildDiscoverTab(discoverAsync, excludedClubIds: mineClubIds),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscoverTab(
    AsyncValue<List<Map<String, dynamic>>> asyncValue, {
    Set<int> excludedClubIds = const <int>{},
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar grupos',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _q.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _q = '');
                      },
                    ),
            ),
            onChanged: (value) => setState(() => _q = value.trim()),
          ),
        ),
        Expanded(
          child: _buildClubList(
            asyncValue,
            discoverMode: true,
            excludedClubIds: excludedClubIds,
          ),
        ),
      ],
    );
  }

  Widget _buildClubList(
    AsyncValue<List<Map<String, dynamic>>> asyncValue, {
    bool discoverMode = false,
    bool showCreateButton = false,
    Set<int> excludedClubIds = const <int>{},
  }) {
    final config = ref.watch(appConfigProvider);

    Widget createButton() {
      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () async {
              if (await requireSignIn(context, ref, action: 'crear un grupo')) {
                await _openCreateClubScreen();
              }
            },
            icon: const Icon(Icons.add),
            label: const Text('Crear grupo'),
          ),
        ),
      );
    }

    return asyncValue.when(
      loading: () => Column(
        children: [
          if (showCreateButton) createButton(),
          const Expanded(child: Center(child: CircularProgressIndicator())),
        ],
      ),
      error: (error, _) => Column(
        children: [
          if (showCreateButton) createButton(),
          Expanded(
            child: Center(child: Text('No se pudo cargar grupos: $error')),
          ),
        ],
      ),
      data: (items) {
        final visibleItems = discoverMode
            ? filterDiscoverClubs(items, excludedClubIds: excludedClubIds)
            : items;

        return Column(
          children: [
            if (showCreateButton) createButton(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(mineClubsProvider(''));
                  ref.invalidate(discoverClubsProvider(_q));
                },
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                  itemCount: visibleItems.isEmpty ? 1 : visibleItems.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    if (visibleItems.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          showCreateButton
                              ? 'Aún no tienes grupos.'
                              : 'Sin resultados.',
                          textAlign: TextAlign.center,
                        ),
                      );
                    }
                    final club = visibleItems[index];
                    final clubId = int.tryParse(club['id'].toString()) ?? 0;
                    final name = (club['nombre'] ?? '').toString();
                    final isActive = club['is_active'] != false;
                    final pendingPichangas =
                        int.tryParse(
                          club['pending_pichangas_count']?.toString() ?? '0',
                        ) ??
                        0;
                    final openPichangas =
                        int.tryParse(
                          club['open_pichangas_count']?.toString() ?? '0',
                        ) ??
                        0;
                    final hasMyConfirmedPichanga =
                        club['has_my_confirmed_pichanga'] == true;
                    final myConfirmedPichangas =
                        int.tryParse(
                          club['my_confirmed_pichangas_count']?.toString() ??
                              '0',
                        ) ??
                        0;

                    return _ClubListCard(
                      name: name,
                      membersLabel:
                          '${club['miembros_count'] ?? 0} miembros'
                          '${isActive ? '' : ' • desactivado'}',
                      imageUrl: resolveClubImageUrl(
                        club['logo_url']?.toString(),
                        config,
                      ),
                      photoKey: ValueKey('club-photo-$clubId'),
                      badges: [
                        if (!discoverMode && pendingPichangas > 0)
                          _ClubActivityBadge(
                            key: ValueKey('club-pichangas-badge-$clubId'),
                            icon: Icons.sports_soccer_outlined,
                            label:
                                '$pendingPichangas ${pendingPichangas == 1 ? 'pichanga' : 'pichangas'}',
                          ),
                        if (!discoverMode &&
                            (myConfirmedPichangas > 0 ||
                                hasMyConfirmedPichanga))
                          _ClubActivityBadge(
                            key: ValueKey('club-attending-badge-$clubId'),
                            icon: Icons.check_circle_outline,
                            label:
                                'Asistiré a ${myConfirmedPichangas > 0 ? myConfirmedPichangas : 1}',
                          ),
                        if (discoverMode && openPichangas > 0)
                          _ClubActivityBadge(
                            key: ValueKey('club-open-pichangas-badge-$clubId'),
                            icon: Icons.sports_soccer_outlined,
                            label:
                                '$openPichangas ${openPichangas == 1 ? 'pichanga abierta' : 'pichangas abiertas'}',
                          ),
                      ],
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => ClubDetailScreen(clubId: clubId),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _respondInvitation(int invitationId, String action) async {
    try {
      await ref
          .read(clubsRepositoryProvider)
          .respondInvitation(invitationId, action);
      ref.invalidate(myInvitationsProvider);
      ref.invalidate(mineClubsProvider(''));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              action == 'accept'
                  ? 'Invitación aceptada.'
                  : 'Invitación rechazada.',
            ),
          ),
        );
      }
    } on ApiError catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Future<void> _openCreateClubScreen() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => const CreateClubScreen()),
    );
    if (!mounted || created != true) {
      return;
    }

    ref.invalidate(mineClubsProvider(''));
    ref.invalidate(discoverClubsProvider(_q));
    _tabController.animateTo(0);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Grupo creado.')));
  }
}

class _ClubListCard extends StatelessWidget {
  const _ClubListCard({
    required this.name,
    required this.membersLabel,
    required this.imageUrl,
    required this.photoKey,
    required this.badges,
    required this.onTap,
  });

  final String name;
  final String membersLabel;
  final String? imageUrl;
  final Key photoKey;
  final List<Widget> badges;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasBadges = badges.isNotEmpty;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: hasBadges ? 116 : 94,
          child: Row(
            children: [
              SizedBox(
                key: photoKey,
                width: 88,
                height: double.infinity,
                child: _ClubPhoto(url: imageUrl, fillsCard: true),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(13, 12, 6, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        membersLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      if (hasBadges) ...[
                        const SizedBox(height: 7),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              for (
                                var index = 0;
                                index < badges.length;
                                index++
                              ) ...[
                                if (index > 0) const SizedBox(width: 5),
                                badges[index],
                              ],
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(right: 9),
                child: Icon(Icons.chevron_right),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClubActivityBadge extends StatelessWidget {
  const _ClubActivityBadge({
    super.key,
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: colors.onPrimaryContainer),
          const SizedBox(width: 3),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colors.onPrimaryContainer,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ClubPhoto extends StatelessWidget {
  const _ClubPhoto({this.url, this.fillsCard = false});

  final String? url;
  final bool fillsCard;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: fillsCard ? BorderRadius.zero : BorderRadius.circular(10),
      child: SizedBox(
        width: fillsCard ? double.infinity : 48,
        height: fillsCard ? double.infinity : 48,
        child: url == null || url!.isEmpty
            ? ColoredBox(
                color: colorScheme.surfaceContainerHighest,
                child: Icon(Icons.groups_outlined, color: colorScheme.primary),
              )
            : Image.network(
                url!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => ColoredBox(
                  color: colorScheme.surfaceContainerHighest,
                  child: Icon(
                    Icons.groups_outlined,
                    color: colorScheme.primary,
                  ),
                ),
              ),
      ),
    );
  }
}
