import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_error.dart';
import '../data/clubs_repository.dart';
import 'club_detail_screen.dart';
import 'join_club_by_link_screen.dart';

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
    final mineAsync = ref.watch(mineClubsProvider(_q));
    final discoverAsync = ref.watch(discoverClubsProvider(_q));
    final invitationsAsync = ref.watch(myInvitationsProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar grupos',
                    prefixIcon: const Icon(Icons.search),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _q = '');
                      },
                    ),
                  ),
                  onSubmitted: (value) => setState(() => _q = value.trim()),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: _openCreateClubDialog,
                icon: const Icon(Icons.add),
                label: const Text('Crear'),
              ),
              IconButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const JoinClubByLinkScreen(),
                    ),
                  );
                },
                tooltip: 'Ingresar por link',
                icon: const Icon(Icons.link),
              ),
            ],
          ),
        ),
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
            Tab(text: 'Descubrir'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildClubList(mineAsync),
              _buildClubList(discoverAsync, discoverMode: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildClubList(
    AsyncValue<List<Map<String, dynamic>>> asyncValue, {
    bool discoverMode = false,
  }) {
    return asyncValue.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) =>
          Center(child: Text('No se pudo cargar grupos: $error')),
      data: (items) {
        if (items.isEmpty) {
          return const Center(child: Text('Sin resultados.'));
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(mineClubsProvider(_q));
            ref.invalidate(discoverClubsProvider(_q));
          },
          child: ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final club = items[index];
              final clubId = int.tryParse(club['id'].toString()) ?? 0;
              final name = (club['nombre'] ?? '').toString();
              final role = club['my_role']?.toString();
              final isVisible = club['is_visible'] == true;

              return Card(
                child: ListTile(
                  title: Text(name),
                  subtitle: Text(
                    '${club['miembros_count'] ?? 0} miembros • ${isVisible ? 'visible' : 'oculto'}'
                    '${role != null ? ' • $role' : ''}',
                  ),
                  trailing: discoverMode && role == null
                      ? TextButton(
                          onPressed: () =>
                              _requestJoinBySearch(clubId: clubId, name: name),
                          child: const Text('Solicitar'),
                        )
                      : const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => ClubDetailScreen(clubId: clubId),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _requestJoinBySearch({
    required int clubId,
    required String name,
  }) async {
    try {
      await ref.read(clubsRepositoryProvider).requestJoinBySearch(clubId);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Solicitud enviada a $name.')));
      ref.invalidate(discoverClubsProvider(_q));
      ref.invalidate(mineClubsProvider(_q));
    } on ApiError catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _respondInvitation(int invitationId, String action) async {
    try {
      await ref
          .read(clubsRepositoryProvider)
          .respondInvitation(invitationId, action);
      ref.invalidate(myInvitationsProvider);
      ref.invalidate(mineClubsProvider(_q));
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

  Future<void> _openCreateClubDialog() async {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    bool isVisible = true;
    String pichangaScope = 'admins';
    String renotifyScope = 'members';
    int maxDegree = 3;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Crear grupo'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Nombre *'),
                    ),
                    TextField(
                      controller: descController,
                      decoration: const InputDecoration(
                        labelText: 'Descripción',
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Grupo visible en búsqueda'),
                      value: isVisible,
                      onChanged: (value) => setState(() => isVisible = value),
                    ),
                    DropdownButtonFormField<String>(
                      initialValue: pichangaScope,
                      decoration: const InputDecoration(
                        labelText: 'Quién puede crear pichanga',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'admins',
                          child: Text('Solo admins'),
                        ),
                        DropdownMenuItem(
                          value: 'members',
                          child: Text('Admins y miembros'),
                        ),
                      ],
                      onChanged: (value) => setState(
                        () => pichangaScope = value ?? pichangaScope,
                      ),
                    ),
                    DropdownButtonFormField<String>(
                      initialValue: renotifyScope,
                      decoration: const InputDecoration(
                        labelText: 'Quién puede re-avisar',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'admins',
                          child: Text('Solo admins'),
                        ),
                        DropdownMenuItem(
                          value: 'members',
                          child: Text('Admins y miembros'),
                        ),
                      ],
                      onChanged: (value) => setState(
                        () => renotifyScope = value ?? renotifyScope,
                      ),
                    ),
                    DropdownButtonFormField<int>(
                      initialValue: maxDegree,
                      decoration: const InputDecoration(
                        labelText: 'Máximo grado de audiencia',
                      ),
                      items: const [
                        DropdownMenuItem(value: 1, child: Text('1er grado')),
                        DropdownMenuItem(value: 2, child: Text('2do grado')),
                        DropdownMenuItem(value: 3, child: Text('3er grado')),
                      ],
                      onChanged: (value) =>
                          setState(() => maxDegree = value ?? 1),
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
                    final name = nameController.text.trim();
                    if (name.length < 3) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(content: Text('Nombre inválido.')),
                      );
                      return;
                    }

                    try {
                      await ref.read(clubsRepositoryProvider).createClub({
                        'nombre': name,
                        'descripcion': descController.text.trim(),
                        'is_visible': isVisible,
                        'pichanga_create_scope': pichangaScope,
                        'renotify_scope': renotifyScope,
                        'audience_max_degree': maxDegree,
                        'renotify_cooldown_minutes': 30,
                        'renotify_max_per_pichanga': 5,
                      });

                      if (!mounted || !dialogContext.mounted || !context.mounted) {
                        return;
                      }

                      Navigator.of(dialogContext).pop();
                      ref.invalidate(mineClubsProvider(_q));
                      ref.invalidate(discoverClubsProvider(_q));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Grupo creado.')),
                      );
                    } on ApiError catch (e) {
                      if (!dialogContext.mounted) {
                        return;
                      }
                      ScaffoldMessenger.of(
                        dialogContext,
                      ).showSnackBar(SnackBar(content: Text(e.message)));
                    }
                  },
                  child: const Text('Crear'),
                ),
              ],
            );
          },
        );
      },
    );

    if (mounted) {
      nameController.dispose();
      descController.dispose();
    }
  }
}
