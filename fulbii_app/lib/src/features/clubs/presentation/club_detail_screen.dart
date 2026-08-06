import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';

import '../../../config/app_config.dart';
import '../../../core/network/api_error.dart';
import '../../auth/presentation/login_required_sheet.dart';
import '../../auth/session_controller.dart';
import '../../challenges/data/challenges_repository.dart';
import '../../challenges/presentation/challenges_screen.dart';
import '../../pichangas/data/pichangas_repository.dart';
import '../../pichangas/presentation/create_pichanga_screen.dart';
import '../../pichangas/presentation/pichanga_detail_screen.dart';
import '../../profile/presentation/public_player_profile_screen.dart';
import '../data/clubs_repository.dart';

final clubDetailProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, int>((ref, clubId) {
      return ref.watch(clubsRepositoryProvider).clubDetail(clubId);
    });

final clubMembersProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, int>((ref, clubId) {
      return ref.watch(clubsRepositoryProvider).members(clubId);
    });

final clubPichangasProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, int>((ref, clubId) {
      return ref.watch(pichangasRepositoryProvider).byClub(clubId);
    });

final clubNotificationPrefProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, int>((ref, clubId) {
      return ref.watch(clubsRepositoryProvider).notificationPreference(clubId);
    });

final clubJoinRequestsProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, int>((ref, clubId) {
      return ref
          .watch(clubsRepositoryProvider)
          .joinRequests(clubId, status: 'all');
    });

bool isClubAdminDetail(Map<String, dynamic>? detail) {
  final membership = detail?['membership'];
  return membership is Map && membership['my_role']?.toString() == 'admin';
}

bool isClubActiveDetail(Map<String, dynamic>? detail) {
  final club = detail?['club'];
  return club is! Map || club['is_active'] != false;
}

bool showLegacyClubDetailSections() =>
    const bool.fromEnvironment('show_legacy_group_detail', defaultValue: false);

class ClubDetailScreen extends ConsumerWidget {
  const ClubDetailScreen({required this.clubId, super.key});

  final int clubId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(sessionControllerProvider).isAuthenticated) {
      return _GuestClubDetail(clubId: clubId);
    }
    final detailAsync = ref.watch(clubDetailProvider(clubId));
    final membersAsync = ref.watch(clubMembersProvider(clubId));
    final pichangasAsync = ref.watch(clubPichangasProvider(clubId));
    final isAdminFromDetail = isClubAdminDetail(detailAsync.valueOrNull);
    final isActiveFromDetail = isClubActiveDetail(detailAsync.valueOrNull);
    final isMemberFromDetail =
        (detailAsync.valueOrNull?['membership'] as Map?)?['is_member'] == true;
    final prefAsync = isMemberFromDetail && isActiveFromDetail
        ? ref.watch(clubNotificationPrefProvider(clubId))
        : null;
    final joinRequestsAsync = isAdminFromDetail && isActiveFromDetail
        ? ref.watch(clubJoinRequestsProvider(clubId))
        : null;

    return Scaffold(
      bottomNavigationBar: detailAsync.when(
        loading: () => null,
        error: (_, _) => null,
        data: (data) {
          final club = (data['club'] as Map?)?.cast<String, dynamic>() ?? {};
          final membership =
              (data['membership'] as Map?)?.cast<String, dynamic>() ?? {};
          final isMember = membership['is_member'] == true;
          final isAdmin = membership['my_role']?.toString() == 'admin';
          final canCreate =
              club['is_active'] != false &&
              (isAdmin ||
                  (isMember &&
                      (club['pichanga_create_scope'] ?? 'admins') ==
                          'members'));
          if (!canCreate) return null;
          return SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
              ),
              child: FilledButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => CreatePichangaScreen(clubId: clubId),
                  ),
                ),
                icon: const Icon(Icons.add),
                label: const Text('Crear pichanga'),
              ),
            ),
          );
        },
      ),
      body: Stack(
        children: [
          ListView(
            padding: EdgeInsets.zero,
            children: [
              detailAsync.when(
                loading: () => const LinearProgressIndicator(minHeight: 2),
                error: (error, _) => Text('No se pudo cargar grupo: $error'),
                data: (data) {
                  final club =
                      (data['club'] as Map?)?.cast<String, dynamic>() ?? {};
                  final config = ref.watch(appConfigProvider);
                  final membership =
                      (data['membership'] as Map?)?.cast<String, dynamic>() ??
                      {};
                  final myRole = membership['my_role']?.toString();
                  final isAdmin = myRole == 'admin';
                  final isMember = membership['is_member'] == true;
                  final isVisitor = !isMember;
                  final isActive = club['is_active'] != false;
                  final isVisible = club['is_visible'] == true;
                  final shareUrl = (club['share_url'] ?? '').toString();
                  final linkJoinEnabled = club['link_join_enabled'] == true;
                  final hasPendingJoinRequest =
                      club['has_pending_join_request'] == true;
                  final autoEnabled = club['auto_reminder_enabled'] == true;
                  final auto48 = club['auto_reminder_48h_enabled'] == true;
                  final auto24 = club['auto_reminder_24h_enabled'] == true;

                  return Column(
                    children: [
                      _ClubDetailPhoto(
                        url:
                            resolveClubImageUrl(
                              club['logo_url']?.toString(),
                              config,
                            ) ??
                            '',
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    (club['nombre'] ?? '').toString(),
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(fontWeight: FontWeight.w800),
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Compartir grupo',
                                  onPressed: isActive
                                      ? () => _shareClub(
                                          context,
                                          clubName: (club['nombre'] ?? 'Grupo')
                                              .toString(),
                                          shareUrl: shareUrl.isNotEmpty
                                              ? shareUrl
                                              : '${config.appLinkBaseUrl}/club/$clubId',
                                        )
                                      : null,
                                  icon: const Icon(Icons.ios_share_outlined),
                                ),
                              ],
                            ),
                            if (club['rating_average'] != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                '★ ${(club['rating_average'] as num).toDouble().toStringAsFixed(1)}',
                                style: const TextStyle(
                                  color: Color(0xFFFFD21F),
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                            if ((club['descripcion'] ?? '')
                                .toString()
                                .isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(club['descripcion'].toString()),
                              ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _ClubStatusChip(
                                  label: isVisible
                                      ? 'Grupo visible públicamente'
                                      : 'Grupo no visible públicamente',
                                ),
                                if (isAdmin)
                                  const _ClubStatusChip(label: 'Administrador'),
                                if (isMember && !isAdmin)
                                  const _ClubStatusChip(label: 'Miembro'),
                                if (!isActive)
                                  const _ClubStatusChip(label: 'Desactivado'),
                                if (hasPendingJoinRequest)
                                  const _ClubStatusChip(
                                    label: 'Solicitud enviada',
                                  ),
                              ],
                            ),
                            if (!isActive) ...[
                              const SizedBox(height: 12),
                              const Text(
                                'Este grupo está desactivado. Puedes consultar su información, pero no realizar acciones.',
                              ),
                            ],
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                if (isActive &&
                                    isVisitor &&
                                    isVisible &&
                                    linkJoinEnabled &&
                                    !hasPendingJoinRequest)
                                  FilledButton.icon(
                                    onPressed: () => _requestJoin(context, ref),
                                    icon: const Icon(Icons.group_add_outlined),
                                    label: const Text('Solicitar ingreso'),
                                  ),
                                if (isActive && isAdmin)
                                  OutlinedButton.icon(
                                    onPressed: () =>
                                        _inviteDialog(context, ref),
                                    icon: const Icon(Icons.person_add_alt_1),
                                    label: const Text('Invitar'),
                                  ),
                                if (isActive && isMember)
                                  OutlinedButton.icon(
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute<void>(
                                          builder: (_) =>
                                              const ChallengesScreen(),
                                        ),
                                      );
                                    },
                                    icon: const Icon(
                                      Icons.sports_kabaddi_outlined,
                                    ),
                                    label: const Text('Retos'),
                                  ),
                                if (isActive && isVisitor && isVisible)
                                  OutlinedButton.icon(
                                    onPressed: () => _challengeClubDialog(
                                      context,
                                      ref,
                                      targetClubId: clubId,
                                      targetClubName: (club['nombre'] ?? '')
                                          .toString(),
                                    ),
                                    icon: const Icon(Icons.bolt_outlined),
                                    label: const Text('Retar grupo'),
                                  ),
                              ],
                            ),
                            if (showLegacyClubDetailSections() &&
                                isActive &&
                                isAdmin) ...[
                              const SizedBox(height: 10),
                              const Divider(),
                              const SizedBox(height: 4),
                              Text(
                                'Administración del grupo',
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              const SizedBox(height: 4),
                              SwitchListTile.adaptive(
                                contentPadding: EdgeInsets.zero,
                                value: linkJoinEnabled,
                                title: const Text(
                                  'Permitir solicitudes de ingreso',
                                ),
                                onChanged: (value) => _updateClubSettings(
                                  context,
                                  ref,
                                  {'link_join_enabled': value},
                                ),
                              ),
                              SwitchListTile.adaptive(
                                contentPadding: EdgeInsets.zero,
                                value: autoEnabled,
                                title: const Text('Avisos automáticos activos'),
                                onChanged: (value) => _updateClubSettings(
                                  context,
                                  ref,
                                  {'auto_reminder_enabled': value},
                                ),
                              ),
                              SwitchListTile.adaptive(
                                contentPadding: EdgeInsets.zero,
                                value: auto48,
                                title: const Text(
                                  'Ola automática 48h (grado 1)',
                                ),
                                onChanged: autoEnabled
                                    ? (value) => _updateClubSettings(
                                        context,
                                        ref,
                                        {'auto_reminder_48h_enabled': value},
                                      )
                                    : null,
                              ),
                              SwitchListTile.adaptive(
                                contentPadding: EdgeInsets.zero,
                                value: auto24,
                                title: const Text(
                                  'Ola automática 24h (máx grado)',
                                ),
                                onChanged: autoEnabled
                                    ? (value) => _updateClubSettings(
                                        context,
                                        ref,
                                        {'auto_reminder_24h_enabled': value},
                                      )
                                    : null,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
              if (showLegacyClubDetailSections() &&
                  isAdminFromDetail &&
                  isActiveFromDetail) ...[
                const SizedBox(height: 12),
                Card(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: detailAsync.when(
                      loading: () => const SizedBox.shrink(),
                      error: (error, stackTrace) => const SizedBox.shrink(),
                      data: (data) {
                        final membership =
                            (data['membership'] as Map?)
                                ?.cast<String, dynamic>() ??
                            {};
                        if ((membership['my_role'] ?? '').toString() !=
                            'admin') {
                          return const Text(
                            'Solo administradores pueden gestionar solicitudes.',
                          );
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Solicitudes de ingreso',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            joinRequestsAsync!.when(
                              loading: () =>
                                  const LinearProgressIndicator(minHeight: 2),
                              error: (error, _) => Text('Error: $error'),
                              data: (items) {
                                if (items.isEmpty) {
                                  return const Text(
                                    'No hay solicitudes pendientes.',
                                  );
                                }

                                return Column(
                                  children: items.map((item) {
                                    final requestId =
                                        int.tryParse(item['id'].toString()) ??
                                        0;
                                    final requester =
                                        (item['requester'] as Map?)
                                            ?.cast<String, dynamic>() ??
                                        {};
                                    final nick =
                                        (requester['nick'] ??
                                                requester['name'] ??
                                                'usuario')
                                            .toString();
                                    final via =
                                        (item['requested_via'] ?? 'search')
                                            .toString();
                                    final status = (item['status'] ?? 'pending')
                                        .toString();

                                    return ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      title: Text(nick),
                                      subtitle: Text(
                                        'Vía: $via • Estado: $status',
                                      ),
                                      trailing: status == 'pending'
                                          ? Wrap(
                                              spacing: 2,
                                              children: [
                                                IconButton(
                                                  onPressed: () =>
                                                      _decideJoinRequest(
                                                        context,
                                                        ref,
                                                        requestId: requestId,
                                                        action: 'accept',
                                                      ),
                                                  icon: const Icon(
                                                    Icons.check,
                                                    color: Colors.green,
                                                  ),
                                                ),
                                                IconButton(
                                                  onPressed: () =>
                                                      _decideJoinRequest(
                                                        context,
                                                        ref,
                                                        requestId: requestId,
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
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: prefAsync!.when(
                      loading: () =>
                          const LinearProgressIndicator(minHeight: 2),
                      error: (error, _) =>
                          Text('No se pudo cargar preferencia: $error'),
                      data: (pref) {
                        final mode = (pref['mode'] ?? 'always_on').toString();
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Notificaciones de este grupo',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              initialValue: mode,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'always_on',
                                  child: Text('Siempre activas'),
                                ),
                                DropdownMenuItem(
                                  value: 'mute_24h',
                                  child: Text('Silenciar 24 horas'),
                                ),
                                DropdownMenuItem(
                                  value: 'mute_1w',
                                  child: Text('Silenciar 1 semana'),
                                ),
                                DropdownMenuItem(
                                  value: 'mute_forever',
                                  child: Text('Silenciar para siempre'),
                                ),
                              ],
                              onChanged: (value) async {
                                if (value == null) {
                                  return;
                                }

                                try {
                                  await ref
                                      .read(clubsRepositoryProvider)
                                      .setNotificationPreference(clubId, value);
                                  ref.invalidate(
                                    clubNotificationPrefProvider(clubId),
                                  );
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Preferencia actualizada.',
                                        ),
                                      ),
                                    );
                                  }
                                } on ApiError catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(e.message)),
                                    );
                                  }
                                }
                              },
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              if (showLegacyClubDetailSections())
                Card(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Miembros',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        membersAsync.when(
                          loading: () =>
                              const LinearProgressIndicator(minHeight: 2),
                          error: (error, _) =>
                              Text('No se pudo cargar miembros: $error'),
                          data: (members) {
                            if (members.isEmpty) {
                              return const Text('Sin miembros.');
                            }

                            return Column(
                              children: members.map((member) {
                                final user =
                                    (member['user'] as Map?)
                                        ?.cast<String, dynamic>() ??
                                    {};
                                final name =
                                    (user['nick'] ?? user['name'] ?? '')
                                        .toString();
                                final role = (member['rol'] ?? 'miembro')
                                    .toString();

                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: CircleAvatar(
                                    child: Text(
                                      name.isEmpty ? '?' : name.substring(0, 1),
                                    ),
                                  ),
                                  title: Text(name),
                                  subtitle: Text(role),
                                );
                              }).toList(),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pichangas del grupo',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      pichangasAsync.when(
                        loading: () =>
                            const LinearProgressIndicator(minHeight: 2),
                        error: (error, _) =>
                            Text('No se pudo cargar pichangas: $error'),
                        data: (items) {
                          if (items.isEmpty) {
                            return const Text('Todavía no hay pichangas.');
                          }

                          return Column(
                            children: items
                                .map(
                                  (item) => _ClubPichangaCard(
                                    item: item,
                                    onTap: () {
                                      final id =
                                          int.tryParse(item['id'].toString()) ??
                                          0;
                                      if (id > 0) {
                                        Navigator.of(context).push(
                                          MaterialPageRoute<void>(
                                            builder: (_) =>
                                                PichangaDetailScreen(
                                                  pichangaId: id,
                                                ),
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                )
                                .toList(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Material(
                    color: Colors.black.withValues(alpha: 0.42),
                    shape: const CircleBorder(),
                    child: const BackButton(color: Colors.white),
                  ),
                  detailAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, _) => const SizedBox.shrink(),
                    data: (data) {
                      final membership =
                          (data['membership'] as Map?)
                              ?.cast<String, dynamic>() ??
                          {};
                      final isMember = membership['is_member'] == true;
                      return Row(
                        children: [
                          _TopAction(
                            icon: Icons.groups_outlined,
                            tooltip: 'Integrantes',
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    ClubMembersScreen(clubId: clubId),
                              ),
                            ),
                          ),
                          if (isMember)
                            _TopAction(
                              icon: Icons.settings_outlined,
                              tooltip: 'Administración',
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) =>
                                      ClubAdministrationScreen(clubId: clubId),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _inviteDialog(BuildContext context, WidgetRef ref) async {
    final nickController = TextEditingController();
    final emailController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Invitar usuario'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nickController,
                decoration: const InputDecoration(labelText: 'Nick'),
              ),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () async {
                final nick = nickController.text.trim();
                final email = emailController.text.trim();
                if (nick.isEmpty && email.isEmpty) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(content: Text('Ingresa nick o email.')),
                  );
                  return;
                }

                try {
                  await ref
                      .read(clubsRepositoryProvider)
                      .inviteByNickOrEmail(
                        clubId,
                        nick: nick.isEmpty ? null : nick,
                        email: email.isEmpty ? null : email,
                      );
                  if (context.mounted) {
                    Navigator.of(dialogContext).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Invitación enviada.')),
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

    if (context.mounted) {
      nickController.dispose();
      emailController.dispose();
    }
  }

  Future<void> _requestJoin(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(clubsRepositoryProvider).requestJoinBySearch(clubId);
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Solicitud de ingreso enviada.')),
      );
      ref.invalidate(clubDetailProvider(clubId));
    } on ApiError catch (e) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _shareClub(
    BuildContext context, {
    required String clubName,
    required String shareUrl,
  }) async {
    await SharePlus.instance.share(
      ShareParams(
        subject: clubName,
        text: 'Mira el grupo $clubName en Fulbii: $shareUrl',
      ),
    );
  }

  Future<void> _challengeClubDialog(
    BuildContext context,
    WidgetRef ref, {
    required int targetClubId,
    required String targetClubName,
  }) async {
    final myClubs = await ref
        .read(clubsRepositoryProvider)
        .listClubs(scope: 'mine');
    if (!context.mounted) {
      return;
    }

    if (myClubs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Necesitas pertenecer a un grupo para retar.'),
        ),
      );
      return;
    }

    int selectedClubId = int.tryParse(myClubs.first['id'].toString()) ?? 0;
    final teamSizeController = TextEditingController(text: '6');
    String challengeWindow = 'next_week';
    final noteController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Retar a $targetClubName'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<int>(
                      initialValue: selectedClubId,
                      decoration: const InputDecoration(
                        labelText: 'Tu grupo',
                        border: OutlineInputBorder(),
                      ),
                      items: myClubs.map((club) {
                        final id = int.tryParse(club['id'].toString()) ?? 0;
                        return DropdownMenuItem<int>(
                          value: id,
                          child: Text((club['nombre'] ?? 'Grupo').toString()),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }
                        setDialogState(() => selectedClubId = value);
                      },
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: teamSizeController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Cantidad por equipo (vs)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: challengeWindow,
                      decoration: const InputDecoration(
                        labelText: 'Ventana del reto',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'next_week',
                          child: Text('Siguiente semana'),
                        ),
                        DropdownMenuItem(
                          value: 'next_fortnight',
                          child: Text('Siguiente quincena'),
                        ),
                        DropdownMenuItem(
                          value: 'next_month',
                          child: Text('Siguiente mes'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }
                        setDialogState(() => challengeWindow = value);
                      },
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: noteController,
                      minLines: 2,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Mensaje inicial (opcional)',
                        border: OutlineInputBorder(),
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
                    try {
                      final teamSize =
                          int.tryParse(teamSizeController.text.trim()) ?? 6;
                      await ref
                          .read(challengesRepositoryProvider)
                          .create(
                            fromClubId: selectedClubId,
                            challengedClubId: targetClubId,
                            teamSize: teamSize,
                            challengeWindow: challengeWindow,
                            requestedNote: noteController.text.trim().isEmpty
                                ? null
                                : noteController.text.trim(),
                          );
                      if (dialogContext.mounted) {
                        Navigator.of(dialogContext).pop();
                      }
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Reto enviado.')),
                        );
                      }
                    } on ApiError catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text(e.message)));
                      }
                    }
                  },
                  child: const Text('Enviar reto'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _updateClubSettings(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> body,
  ) async {
    try {
      await ref.read(clubsRepositoryProvider).updateClub(clubId, body);
      ref.invalidate(clubDetailProvider(clubId));
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Configuración actualizada.')),
      );
    } on ApiError catch (e) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _decideJoinRequest(
    BuildContext context,
    WidgetRef ref, {
    required int requestId,
    required String action,
  }) async {
    try {
      await ref
          .read(clubsRepositoryProvider)
          .decideJoinRequest(clubId, requestId, action: action);
      ref.invalidate(clubJoinRequestsProvider(clubId));
      ref.invalidate(clubMembersProvider(clubId));
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            action == 'accept' ? 'Solicitud aceptada.' : 'Solicitud rechazada.',
          ),
        ),
      );
    } on ApiError catch (e) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }
}

class _ClubDetailPhoto extends StatelessWidget {
  const _ClubDetailPhoto({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 258,
      width: double.infinity,
      child: url.isEmpty
          ? ColoredBox(
              color: colorScheme.surfaceContainerHighest,
              child: Icon(
                Icons.groups_outlined,
                size: 54,
                color: colorScheme.primary,
              ),
            )
          : Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => ColoredBox(
                color: colorScheme.surfaceContainerHighest,
                child: Icon(
                  Icons.groups_outlined,
                  size: 54,
                  color: colorScheme.primary,
                ),
              ),
            ),
    );
  }
}

class _ClubStatusChip extends StatelessWidget {
  const _ClubStatusChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _TopAction extends StatelessWidget {
  const _TopAction({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.black.withValues(alpha: 0.42),
    shape: const CircleBorder(),
    child: IconButton(
      tooltip: tooltip,
      color: Colors.white,
      onPressed: onPressed,
      icon: Icon(icon),
    ),
  );
}

class _ClubPichangaCard extends StatelessWidget {
  const _ClubPichangaCard({required this.item, required this.onTap});

  final Map<String, dynamic> item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final startsAt = DateTime.tryParse(
      (item['starts_at'] ?? '').toString(),
    )?.toLocal();
    final day = startsAt == null
        ? '--'
        : startsAt.day.toString().padLeft(2, '0');
    final month = startsAt == null
        ? ''
        : const [
            'ENE',
            'FEB',
            'MAR',
            'ABR',
            'MAY',
            'JUN',
            'JUL',
            'AGO',
            'SEP',
            'OCT',
            'NOV',
            'DIC',
          ][startsAt.month - 1];
    final time = startsAt == null
        ? 'Horario por confirmar'
        : '${startsAt.hour.toString().padLeft(2, '0')}:${startsAt.minute.toString().padLeft(2, '0')}';
    final court = (item['court_name'] ?? '').toString().trim();
    final field = (item['field_name'] ?? '').toString().trim();
    final venue = [court, field].where((value) => value.isNotEmpty).join(' · ');
    final spots = item['spots_left'] ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 52,
                padding: const EdgeInsets.symmetric(vertical: 7),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      day,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                    Text(month, style: Theme.of(context).textTheme.labelSmall),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (item['title'] ?? 'Pichanga').toString(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$time · $spots cupos libres',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (venue.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        venue,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class ClubMembersScreen extends ConsumerWidget {
  const ClubMembersScreen({required this.clubId, super.key});

  final int clubId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final members = ref.watch(clubMembersProvider(clubId));
    return Scaffold(
      appBar: AppBar(title: const Text('Integrantes')),
      body: members.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text('No se pudieron cargar integrantes: $error')),
        data: (items) => ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          itemCount: items.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (_, index) {
            final member = items[index];
            final user =
                (member['user'] as Map?)?.cast<String, dynamic>() ?? {};
            final name = (user['nick'] ?? user['name'] ?? 'Jugador').toString();
            final stars = member['stars'];
            final userId = int.tryParse(member['user_id'].toString()) ?? 0;
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(vertical: 5),
              leading: CircleAvatar(
                child: Text(
                  name.isEmpty ? '?' : name.substring(0, 1).toUpperCase(),
                ),
              ),
              title: Text(name),
              subtitle: Text(
                (member['rol'] ?? 'miembro').toString() == 'admin'
                    ? 'Administrador'
                    : 'Miembro',
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    stars == null
                        ? '—'
                        : '★ ${(stars as num).toDouble().toStringAsFixed(1)}',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right),
                ],
              ),
              onTap: userId <= 0
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
          },
        ),
      ),
    );
  }
}

class ClubAdministrationScreen extends ConsumerWidget {
  const ClubAdministrationScreen({required this.clubId, super.key});

  final int clubId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(clubDetailProvider(clubId));
    return Scaffold(
      appBar: AppBar(title: const Text('Administración del grupo')),
      body: detail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text('No se pudo cargar el grupo: $error')),
        data: (data) => _ClubAdministrationBody(clubId: clubId, detail: data),
      ),
    );
  }
}

class _ClubAdministrationBody extends ConsumerWidget {
  const _ClubAdministrationBody({required this.clubId, required this.detail});

  final int clubId;
  final Map<String, dynamic> detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final club = (detail['club'] as Map?)?.cast<String, dynamic>() ?? {};
    final membership =
        (detail['membership'] as Map?)?.cast<String, dynamic>() ?? {};
    final isAdmin = membership['my_role']?.toString() == 'admin';
    final isActive = club['is_active'] != false;
    final canEdit = isAdmin && isActive;
    final pref = ref.watch(clubNotificationPrefProvider(clubId));
    final requests = isAdmin && isActive
        ? ref.watch(clubJoinRequestsProvider(clubId))
        : null;

    Future<void> update(Map<String, dynamic> body) async {
      try {
        await ref.read(clubsRepositoryProvider).updateClub(clubId, body);
        ref.invalidate(clubDetailProvider(clubId));
      } on ApiError catch (error) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(error.message)));
        }
      }
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: [
        if (!isAdmin)
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text(
              'Solo lectura. Solo los administradores pueden modificar los ajustes del grupo.',
            ),
          ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.edit_outlined),
          title: const Text('Editar grupo'),
          subtitle: const Text('Nombre, descripción y foto'),
          enabled: canEdit,
          trailing: const Icon(Icons.chevron_right),
          onTap: !canEdit
              ? null
              : () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => _EditClubScreen(clubId: clubId, club: club),
                  ),
                ),
        ),
        const Divider(),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          value: club['is_visible'] == true,
          title: const Text('Grupo visible públicamente'),
          onChanged: canEdit ? (value) => update({'is_visible': value}) : null,
        ),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          value: club['link_join_enabled'] == true,
          title: const Text('Permitir solicitudes de ingreso'),
          onChanged: canEdit && club['is_visible'] == true
              ? (value) => update({'link_join_enabled': value})
              : null,
        ),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          value: club['auto_reminder_enabled'] == true,
          title: const Text('Avisos automáticos activos'),
          onChanged: canEdit
              ? (value) => update({'auto_reminder_enabled': value})
              : null,
        ),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          value: club['auto_reminder_48h_enabled'] == true,
          title: const Text('Ola automática 48 h'),
          onChanged: canEdit && club['auto_reminder_enabled'] == true
              ? (value) => update({'auto_reminder_48h_enabled': value})
              : null,
        ),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          value: club['auto_reminder_24h_enabled'] == true,
          title: const Text('Ola automática 24 h'),
          onChanged: canEdit && club['auto_reminder_enabled'] == true
              ? (value) => update({'auto_reminder_24h_enabled': value})
              : null,
        ),
        const Divider(height: 32),
        Text(
          'Tus notificaciones',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        pref.when(
          loading: () => const LinearProgressIndicator(),
          error: (error, _) => Text('No se pudieron cargar: $error'),
          data: (value) => DropdownButtonFormField<String>(
            initialValue: (value['mode'] ?? 'always_on').toString(),
            items: const [
              DropdownMenuItem(
                value: 'always_on',
                child: Text('Siempre activas'),
              ),
              DropdownMenuItem(
                value: 'mute_24h',
                child: Text('Silenciar 24 horas'),
              ),
              DropdownMenuItem(
                value: 'mute_1w',
                child: Text('Silenciar 1 semana'),
              ),
              DropdownMenuItem(
                value: 'mute_forever',
                child: Text('Silenciar para siempre'),
              ),
            ],
            onChanged: isActive
                ? (mode) async {
                    if (mode == null) return;
                    await ref
                        .read(clubsRepositoryProvider)
                        .setNotificationPreference(clubId, mode);
                    ref.invalidate(clubNotificationPrefProvider(clubId));
                  }
                : null,
          ),
        ),
        if (requests != null) ...[
          const Divider(height: 32),
          Text(
            'Solicitudes de ingreso',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          requests.when(
            loading: () => const LinearProgressIndicator(),
            error: (error, _) => Text('No se pudieron cargar: $error'),
            data: (items) => items.isEmpty
                ? const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text('No hay solicitudes.'),
                  )
                : Column(
                    children: items.map((item) {
                      final requester =
                          (item['requester'] as Map?)
                              ?.cast<String, dynamic>() ??
                          {};
                      final name =
                          (requester['nick'] ?? requester['name'] ?? 'Usuario')
                              .toString();
                      final id = int.tryParse(item['id'].toString()) ?? 0;
                      final pending = item['status']?.toString() == 'pending';
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(name),
                        subtitle: Text((item['status'] ?? '').toString()),
                        trailing: pending
                            ? Wrap(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.close),
                                    onPressed: () =>
                                        _decide(context, ref, id, 'reject'),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.check),
                                    onPressed: () =>
                                        _decide(context, ref, id, 'accept'),
                                  ),
                                ],
                              )
                            : null,
                      );
                    }).toList(),
                  ),
          ),
        ],
      ],
    );
  }

  Future<void> _decide(
    BuildContext context,
    WidgetRef ref,
    int requestId,
    String action,
  ) async {
    await ref
        .read(clubsRepositoryProvider)
        .decideJoinRequest(clubId, requestId, action: action);
    ref.invalidate(clubJoinRequestsProvider(clubId));
    ref.invalidate(clubMembersProvider(clubId));
  }
}

class _EditClubScreen extends ConsumerStatefulWidget {
  const _EditClubScreen({required this.clubId, required this.club});

  final int clubId;
  final Map<String, dynamic> club;

  @override
  ConsumerState<_EditClubScreen> createState() => _EditClubScreenState();
}

class _EditClubScreenState extends ConsumerState<_EditClubScreen> {
  late final TextEditingController _name = TextEditingController(
    text: (widget.club['nombre'] ?? '').toString(),
  );
  late final TextEditingController _description = TextEditingController(
    text: (widget.club['descripcion'] ?? '').toString(),
  );
  File? _logo;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Tomar foto'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Elegir de galería'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    final image = await ImagePicker().pickImage(source: source);
    if (image == null) return;
    final target =
        '${Directory.systemTemp.path}/fulbii_club_${DateTime.now().microsecondsSinceEpoch}.jpg';
    final compressed = await FlutterImageCompress.compressAndGetFile(
      image.path,
      target,
      minWidth: 1200,
      minHeight: 1200,
      quality: 75,
      format: CompressFormat.jpeg,
    );
    if (compressed != null &&
        await compressed.length() <= 2 * 1024 * 1024 &&
        mounted) {
      setState(() => _logo = File(compressed.path));
    }
  }

  Future<void> _save() async {
    if (_saving || _name.text.trim().length < 3) return;
    setState(() => _saving = true);
    final payload = {
      'nombre': _name.text.trim(),
      'descripcion': _description.text.trim(),
    };
    try {
      final repository = ref.read(clubsRepositoryProvider);
      if (_logo == null) {
        await repository.updateClub(widget.clubId, payload);
      } else {
        await repository.updateClubWithLogo(widget.clubId, payload, _logo!);
      }
      ref.invalidate(clubDetailProvider(widget.clubId));
      if (mounted) {
        Navigator.pop(context);
      }
    } on ApiError catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Editar grupo')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Align(
          child: InkWell(
            borderRadius: BorderRadius.circular(50),
            onTap: _pickPhoto,
            child: CircleAvatar(
              radius: 46,
              backgroundImage: _logo == null ? null : FileImage(_logo!),
              child: _logo == null
                  ? const Icon(Icons.add_a_photo_outlined)
                  : null,
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Center(child: Text('Cambiar foto')),
        const SizedBox(height: 24),
        TextField(
          controller: _name,
          maxLength: 150,
          decoration: const InputDecoration(labelText: 'Nombre del grupo'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _description,
          maxLines: 5,
          maxLength: 500,
          decoration: const InputDecoration(labelText: 'Descripción'),
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'Guardando…' : 'Guardar cambios'),
        ),
      ],
    ),
  );
}

class _GuestClubDetail extends ConsumerWidget {
  const _GuestClubDetail({required this.clubId});

  final int clubId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(clubDetailProvider(clubId));
    final members = ref.watch(clubMembersProvider(clubId));
    final pichangas = ref.watch(clubPichangasProvider(clubId));
    return Scaffold(
      body: Stack(
        children: [
          ListView(
            padding: EdgeInsets.zero,
            children: [
              detail.when(
                loading: () => const LinearProgressIndicator(minHeight: 2),
                error: (error, _) => Text('No se pudo cargar grupo: $error'),
                data: (data) {
                  final club =
                      (data['club'] as Map?)?.cast<String, dynamic>() ?? {};
                  final config = ref.watch(appConfigProvider);
                  return Column(
                    children: [
                      _ClubDetailPhoto(
                        url:
                            resolveClubImageUrl(
                              club['logo_url']?.toString(),
                              config,
                            ) ??
                            '',
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    (club['nombre'] ?? 'Grupo').toString(),
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(fontWeight: FontWeight.w800),
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Compartir grupo',
                                  onPressed: () => SharePlus.instance.share(
                                    ShareParams(
                                      subject: (club['nombre'] ?? 'Grupo')
                                          .toString(),
                                      text:
                                          'Mira este grupo en Fulbii: ${(club['share_url'] ?? '').toString()}',
                                    ),
                                  ),
                                  icon: const Icon(Icons.ios_share_outlined),
                                ),
                              ],
                            ),
                            if (club['rating_average'] != null)
                              Text(
                                '★ ${(club['rating_average'] as num).toDouble().toStringAsFixed(1)}',
                                style: const TextStyle(
                                  color: Color(0xFFFFD21F),
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            if ((club['descripcion'] ?? '')
                                .toString()
                                .trim()
                                .isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(club['descripcion'].toString()),
                            ],
                            const SizedBox(height: 10),
                            const _ClubStatusChip(
                              label: 'Grupo visible públicamente',
                            ),
                            const SizedBox(height: 16),
                            FilledButton.icon(
                              onPressed: () => requireSignIn(
                                context,
                                ref,
                                action: 'unirte a este grupo',
                              ),
                              icon: const Icon(Icons.login),
                              label: const Text(
                                'Inicia sesión para participar',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 12),
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Próximas pichangas',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      pichangas.when(
                        loading: () =>
                            const LinearProgressIndicator(minHeight: 2),
                        error: (error, _) =>
                            const Text('No se pudieron cargar pichangas.'),
                        data: (items) => items.isEmpty
                            ? const Text('Todavía no hay pichangas abiertas.')
                            : Column(
                                children: items
                                    .map(
                                      (item) => _ClubPichangaCard(
                                        item: item,
                                        onTap: () {
                                          final id =
                                              int.tryParse(
                                                item['id'].toString(),
                                              ) ??
                                              0;
                                          if (id > 0) {
                                            Navigator.of(context).push(
                                              MaterialPageRoute<void>(
                                                builder: (_) =>
                                                    PichangaDetailScreen(
                                                      pichangaId: id,
                                                    ),
                                              ),
                                            );
                                          }
                                        },
                                      ),
                                    )
                                    .toList(),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Miembros',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      members.when(
                        loading: () =>
                            const LinearProgressIndicator(minHeight: 2),
                        error: (error, _) =>
                            Text('No se pudieron cargar miembros: $error'),
                        data: (items) => Column(
                          children: items.take(12).map((member) {
                            final user =
                                (member['user'] as Map?)
                                    ?.cast<String, dynamic>() ??
                                {};
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const CircleAvatar(
                                child: Icon(Icons.person_outline),
                              ),
                              title: Text(
                                (user['nick'] ?? user['name'] ?? 'Jugador')
                                    .toString(),
                              ),
                              subtitle: Text(
                                (member['rol'] ?? 'miembro').toString(),
                              ),
                              onTap: () => requireSignIn(
                                context,
                                ref,
                                action: 'ver perfiles de miembros',
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(left: 8, top: 4),
              child: Align(
                alignment: Alignment.topLeft,
                child: Material(
                  color: Colors.black.withValues(alpha: 0.42),
                  shape: const CircleBorder(),
                  child: BackButton(color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
