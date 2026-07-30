import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../../../config/app_config.dart';
import '../../../core/network/api_error.dart';
import '../../challenges/data/challenges_repository.dart';
import '../../challenges/presentation/challenges_screen.dart';
import '../../pichangas/data/pichangas_repository.dart';
import '../../pichangas/presentation/create_pichanga_screen.dart';
import '../../pichangas/presentation/pichanga_detail_screen.dart';
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

class ClubDetailScreen extends ConsumerWidget {
  const ClubDetailScreen({required this.clubId, super.key});

  final int clubId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(clubDetailProvider(clubId));
    final membersAsync = ref.watch(clubMembersProvider(clubId));
    final pichangasAsync = ref.watch(clubPichangasProvider(clubId));
    final prefAsync = ref.watch(clubNotificationPrefProvider(clubId));
    final joinRequestsAsync = ref.watch(clubJoinRequestsProvider(clubId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del grupo'),
        actions: [
          IconButton(
            onPressed: () {
              ref.invalidate(clubDetailProvider(clubId));
              ref.invalidate(clubMembersProvider(clubId));
              ref.invalidate(clubPichangasProvider(clubId));
              ref.invalidate(clubNotificationPrefProvider(clubId));
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          detailAsync.when(
            loading: () => const LinearProgressIndicator(minHeight: 2),
            error: (error, _) => Text('No se pudo cargar grupo: $error'),
            data: (data) {
              final club =
                  (data['club'] as Map?)?.cast<String, dynamic>() ?? {};
              final membership =
                  (data['membership'] as Map?)?.cast<String, dynamic>() ?? {};
              final myRole = membership['my_role']?.toString();
              final isAdmin = myRole == 'admin';
              final joinCode = (club['join_code'] ?? '').toString();
              final joinUrl = (club['join_url'] ?? '').toString();
              final linkJoinEnabled = club['link_join_enabled'] == true;
              final autoEnabled = club['auto_reminder_enabled'] == true;
              final auto48 = club['auto_reminder_48h_enabled'] == true;
              final auto24 = club['auto_reminder_24h_enabled'] == true;

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (club['nombre'] ?? '').toString(),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      if ((club['descripcion'] ?? '').toString().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(club['descripcion'].toString()),
                        ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          Chip(
                            label: Text(
                              club['is_visible'] == true ? 'Visible' : 'Oculto',
                            ),
                          ),
                          Chip(label: Text('Mi rol: ${myRole ?? 'visitante'}')),
                          Chip(
                            label: Text(
                              'Crear pichanga: ${club['pichanga_create_scope'] ?? 'admins'}',
                            ),
                          ),
                          Chip(
                            label: Text(
                              'Re-avisar: ${club['renotify_scope'] ?? 'admins'}',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        children: [
                          FilledButton.icon(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) =>
                                      CreatePichangaScreen(clubId: clubId),
                                ),
                              );
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Crear pichanga'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () =>
                                _inviteDialog(context, ref, isAdmin),
                            icon: const Icon(Icons.person_add_alt_1),
                            label: const Text('Invitar'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const ChallengesScreen(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.sports_kabaddi_outlined),
                            label: const Text('Retos'),
                          ),
                          if (myRole == null && club['is_visible'] == true)
                            OutlinedButton.icon(
                              onPressed: () => _challengeClubDialog(
                                context,
                                ref,
                                targetClubId: clubId,
                                targetClubName: (club['nombre'] ?? '').toString(),
                              ),
                              icon: const Icon(Icons.bolt_outlined),
                              label: const Text('Retar grupo'),
                            ),
                        ],
                      ),
                      if (isAdmin) ...[
                        const SizedBox(height: 10),
                        const Divider(),
                        const SizedBox(height: 4),
                        Text(
                          'Growth',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Código de ingreso: ${joinCode.isEmpty ? '-' : joinCode}',
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            OutlinedButton.icon(
                              onPressed: joinCode.isEmpty
                                  ? null
                                  : () => _copyJoinLink(
                                      context,
                                      ref,
                                      joinCode,
                                      joinUrl,
                                    ),
                              icon: const Icon(Icons.share_outlined),
                              label: const Text('Copiar link'),
                            ),
                            OutlinedButton.icon(
                              onPressed: () => _rotateJoinCode(context, ref),
                              icon: const Icon(Icons.refresh),
                              label: const Text('Rotar link'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          value: linkJoinEnabled,
                          title: const Text('Permitir ingreso por link'),
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
                          title: const Text('Ola automática 48h (grado 1)'),
                          onChanged: autoEnabled
                              ? (value) => _updateClubSettings(context, ref, {
                                  'auto_reminder_48h_enabled': value,
                                })
                              : null,
                        ),
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          value: auto24,
                          title: const Text('Ola automática 24h (máx grado)'),
                          onChanged: autoEnabled
                              ? (value) => _updateClubSettings(context, ref, {
                                  'auto_reminder_24h_enabled': value,
                                })
                              : null,
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: detailAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (error, stackTrace) => const SizedBox.shrink(),
                data: (data) {
                  final membership =
                      (data['membership'] as Map?)?.cast<String, dynamic>() ??
                      {};
                  if ((membership['my_role'] ?? '').toString() != 'admin') {
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
                      joinRequestsAsync.when(
                        loading: () =>
                            const LinearProgressIndicator(minHeight: 2),
                        error: (error, _) => Text('Error: $error'),
                        data: (items) {
                          if (items.isEmpty) {
                            return const Text('No hay solicitudes pendientes.');
                          }

                          return Column(
                            children: items.map((item) {
                              final requestId =
                                  int.tryParse(item['id'].toString()) ?? 0;
                              final requester =
                                  (item['requester'] as Map?)
                                      ?.cast<String, dynamic>() ??
                                  {};
                              final nick =
                                  (requester['nick'] ??
                                          requester['name'] ??
                                          'usuario')
                                      .toString();
                              final via = (item['requested_via'] ?? 'search')
                                  .toString();
                              final status = (item['status'] ?? 'pending')
                                  .toString();

                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(nick),
                                subtitle: Text('Vía: $via • Estado: $status'),
                                trailing: status == 'pending'
                                    ? Wrap(
                                        spacing: 2,
                                        children: [
                                          IconButton(
                                            onPressed: () => _decideJoinRequest(
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
                                            onPressed: () => _decideJoinRequest(
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
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: prefAsync.when(
                loading: () => const LinearProgressIndicator(minHeight: 2),
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
                                  content: Text('Preferencia actualizada.'),
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
          const SizedBox(height: 12),
          Card(
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
                    loading: () => const LinearProgressIndicator(minHeight: 2),
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
                          final name = (user['nick'] ?? user['name'] ?? '')
                              .toString();
                          final role = (member['rol'] ?? 'miembro').toString();

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
                    loading: () => const LinearProgressIndicator(minHeight: 2),
                    error: (error, _) =>
                        Text('No se pudo cargar pichangas: $error'),
                    data: (items) {
                      if (items.isEmpty) {
                        return const Text('Todavía no hay pichangas.');
                      }

                      return Column(
                        children: items.map((item) {
                          final id = int.tryParse(item['id'].toString()) ?? 0;
                          final title = (item['title'] ?? 'Pichanga #$id')
                              .toString();
                          final startsAt = (item['starts_at'] ?? '')
                              .toString()
                              .replaceFirst('T', ' ');
                          final status = (item['status'] ?? '').toString();

                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(title),
                            subtitle: Text('$startsAt • $status'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) =>
                                      PichangaDetailScreen(pichangaId: id),
                                ),
                              );
                            },
                          );
                        }).toList(),
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

  Future<void> _inviteDialog(
    BuildContext context,
    WidgetRef ref,
    bool isAdmin,
  ) async {
    if (!isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Solo admins pueden invitar.')),
      );
      return;
    }

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

  Future<void> _copyJoinLink(
    BuildContext context,
    WidgetRef ref,
    String joinCode,
    String joinUrl,
  ) async {
    final normalized = joinCode.trim();
    final config = ref.read(appConfigProvider);
    final link = joinUrl.isNotEmpty
        ? joinUrl
        : '${config.appLinkBaseUrl}/join/$normalized';
    await Clipboard.setData(ClipboardData(text: link));
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Link copiado: $link')));
  }

  Future<void> _challengeClubDialog(
    BuildContext context,
    WidgetRef ref, {
    required int targetClubId,
    required String targetClubName,
  }) async {
    final myClubs = await ref.read(clubsRepositoryProvider).listClubs(scope: 'mine');
    if (!context.mounted) {
      return;
    }

    if (myClubs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Necesitas pertenecer a un grupo para retar.')),
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
                      final teamSize = int.tryParse(teamSizeController.text.trim()) ?? 6;
                      await ref.read(challengesRepositoryProvider).create(
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
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(e.message)),
                        );
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

  Future<void> _rotateJoinCode(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(clubsRepositoryProvider).rotateJoinCode(clubId);
      ref.invalidate(clubDetailProvider(clubId));
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Link rotado.')));
    } on ApiError catch (e) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    }
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
