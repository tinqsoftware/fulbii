import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_error.dart';
import '../data/challenges_repository.dart';

final challengeDetailProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, int>((ref, challengeId) {
      return ref.watch(challengesRepositoryProvider).detail(challengeId);
    });

final challengeMessagesProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, int>((ref, challengeId) {
      return ref.watch(challengesRepositoryProvider).messages(challengeId);
    });

final challengeConfigurationsProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, int>((ref, challengeId) {
      return ref.watch(challengesRepositoryProvider).configurations(challengeId);
    });

class ChallengeDetailScreen extends ConsumerStatefulWidget {
  const ChallengeDetailScreen({required this.challengeId, super.key});

  final int challengeId;

  @override
  ConsumerState<ChallengeDetailScreen> createState() =>
      _ChallengeDetailScreenState();
}

class _ChallengeDetailScreenState extends ConsumerState<ChallengeDetailScreen>
    with WidgetsBindingObserver {
  final _messageController = TextEditingController();
  Timer? _heartbeatTimer;
  Timer? _pollingTimer;
  bool _sendingMessage = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setPresence(true);
      _heartbeatTimer = Timer.periodic(
        const Duration(seconds: 30),
        (_) => _setPresence(true),
      );
      _pollingTimer = Timer.periodic(
        const Duration(seconds: 4),
        (_) => ref.invalidate(challengeMessagesProvider(widget.challengeId)),
      );
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _setPresence(true);
      return;
    }
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _setPresence(false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _setPresence(false);
    _heartbeatTimer?.cancel();
    _pollingTimer?.cancel();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(challengeDetailProvider(widget.challengeId));
    final messagesAsync = ref.watch(challengeMessagesProvider(widget.challengeId));
    final configurationsAsync = ref.watch(
      challengeConfigurationsProvider(widget.challengeId),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('Reto #${widget.challengeId}'),
        actions: [
          IconButton(
            onPressed: () {
              ref.invalidate(challengeDetailProvider(widget.challengeId));
              ref.invalidate(challengeMessagesProvider(widget.challengeId));
              ref.invalidate(challengeConfigurationsProvider(widget.challengeId));
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error cargando reto: $error')),
        data: (detail) {
          final challenge =
              (detail['challenge'] as Map?)?.cast<String, dynamic>() ?? {};
          final fieldOptions = detail['field_options'] is List
              ? (detail['field_options'] as List)
                  .whereType<Map>()
                  .map((item) => item.cast<String, dynamic>())
                  .toList()
              : <Map<String, dynamic>>[];
          final timeOptions = detail['time_options'] is List
              ? (detail['time_options'] as List)
                  .whereType<Map>()
                  .map((item) => item.cast<String, dynamic>())
                  .toList()
              : <Map<String, dynamic>>[];

          final mySide = (challenge['my_side'] ?? '').toString();
          final isCoordinator = challenge['my_is_coordinator'] == true;
          final status = (challenge['status'] ?? '').toString();
          final challengerClub =
              (challenge['challenger_club'] as Map?)?.cast<String, dynamic>() ??
                  {};
          final challengedClub =
              (challenge['challenged_club'] as Map?)?.cast<String, dynamic>() ??
                  {};

          return Column(
            children: [
              Card(
                margin: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${challengerClub['nombre'] ?? 'Grupo A'} vs ${challengedClub['nombre'] ?? 'Grupo B'}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      Text('Estado: $status'),
                      Text('Mi lado: ${mySide.isEmpty ? '-' : mySide}'),
                      Text('Coordinador: ${isCoordinator ? 'sí' : 'no'}'),
                      if ((challenge['expires_at'] ?? '').toString().isNotEmpty)
                        Text(
                          'Expira: ${(challenge['expires_at'] ?? '').toString().replaceFirst('T', ' ')}',
                        ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          OutlinedButton(
                            onPressed: status == 'confirmed' || status == 'cancelled'
                                ? null
                                : () => _coordinate(),
                            child: const Text('Coordinar'),
                          ),
                          OutlinedButton(
                            onPressed: status == 'pending' ||
                                    status == 'negotiating' ||
                                    status == 'configuring'
                                ? () => _rejectChallenge()
                                : null,
                            child: const Text('Rechazar'),
                          ),
                          OutlinedButton(
                            onPressed: status == 'pending' ||
                                    status == 'negotiating' ||
                                    status == 'configuring'
                                ? () => _cancelChallenge()
                                : null,
                            child: const Text('Cancelar'),
                          ),
                          OutlinedButton(
                            onPressed: isCoordinator
                                ? () => _proposeField(fieldOptions)
                                : null,
                            child: const Text('Proponer cancha'),
                          ),
                          OutlinedButton(
                            onPressed: isCoordinator
                                ? () => _proposeTime(timeOptions)
                                : null,
                            child: const Text('Proponer fecha'),
                          ),
                          OutlinedButton(
                            onPressed: isCoordinator &&
                                    fieldOptions.isNotEmpty &&
                                    timeOptions.isNotEmpty
                                ? () => _proposeConfiguration(
                                    fieldOptions: fieldOptions,
                                    timeOptions: timeOptions,
                                  )
                                : null,
                            child: const Text('Configurar pichanga'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Card(
                margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: configurationsAsync.when(
                    loading: () => const LinearProgressIndicator(minHeight: 2),
                    error: (error, _) => Text('Error configuraciones: $error'),
                    data: (items) {
                      if (items.isEmpty) {
                        return const Text('Sin configuraciones propuestas.');
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Configuraciones',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 8),
                          ...items.map((item) {
                            final id = int.tryParse(item['id'].toString()) ?? 0;
                            final cfgStatus = (item['status'] ?? '').toString();
                            final fieldOption =
                                (item['field_option'] as Map?)
                                    ?.cast<String, dynamic>() ??
                                {};
                            final timeOption =
                                (item['time_option'] as Map?)
                                    ?.cast<String, dynamic>() ??
                                {};
                            final fieldName =
                                (fieldOption['field_name'] ??
                                        fieldOption['field_address'] ??
                                        'Cancha')
                                    .toString();
                            final startsAt = (timeOption['starts_at'] ?? '')
                                .toString()
                                .replaceFirst('T', ' ');

                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text('$fieldName • $startsAt'),
                              subtitle: Text('Estado: $cfgStatus'),
                              trailing: cfgStatus == 'pending' && isCoordinator
                                  ? Wrap(
                                      spacing: 0,
                                      children: [
                                        IconButton(
                                          onPressed: () =>
                                              _decideConfiguration(id, 'accept'),
                                          icon: const Icon(
                                            Icons.check,
                                            color: Colors.green,
                                          ),
                                        ),
                                        IconButton(
                                          onPressed: () =>
                                              _decideConfiguration(id, 'reject'),
                                          icon: const Icon(
                                            Icons.close,
                                            color: Colors.red,
                                          ),
                                        ),
                                      ],
                                    )
                                  : null,
                            );
                          }),
                        ],
                      );
                    },
                  ),
                ),
              ),
              Expanded(
                child: Card(
                  margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: Column(
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(10),
                        child: Row(
                          children: [
                            Icon(Icons.chat_bubble_outline),
                            SizedBox(width: 8),
                            Text('Chat del reto'),
                          ],
                        ),
                      ),
                      Expanded(
                        child: messagesAsync.when(
                          loading: () =>
                              const Center(child: CircularProgressIndicator()),
                          error: (error, _) =>
                              Center(child: Text('Error chat: $error')),
                          data: (items) {
                            if (items.isEmpty) {
                              return const Center(
                                child: Text('Aún no hay mensajes.'),
                              );
                            }

                            return ListView.builder(
                              reverse: true,
                              itemCount: items.length,
                              itemBuilder: (context, index) {
                                final item = items[items.length - 1 - index];
                                final sender =
                                    (item['sender'] as Map?)
                                        ?.cast<String, dynamic>() ??
                                    {};
                                final senderName =
                                    (sender['nick'] ??
                                            sender['name'] ??
                                            'Usuario')
                                        .toString();
                                final content = (item['content'] ?? '').toString();
                                final createdAt = (item['created_at'] ?? '')
                                    .toString()
                                    .replaceFirst('T', ' ');
                                final type = (item['message_type'] ?? 'text')
                                    .toString();

                                return ListTile(
                                  dense: true,
                                  title: Text(
                                    type == 'system'
                                        ? 'Sistema'
                                        : senderName,
                                  ),
                                  subtitle: Text('$content\n$createdAt'),
                                  isThreeLine: true,
                                );
                              },
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _messageController,
                                minLines: 1,
                                maxLines: 3,
                                decoration: const InputDecoration(
                                  hintText: 'Escribe un mensaje',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            FilledButton.icon(
                              onPressed: _sendingMessage ? null : _sendMessage,
                              icon: const Icon(Icons.send),
                              label: const Text('Enviar'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) {
      return;
    }
    setState(() => _sendingMessage = true);
    try {
      await ref.read(challengesRepositoryProvider).sendMessage(
            widget.challengeId,
            text,
          );
      _messageController.clear();
      ref.invalidate(challengeMessagesProvider(widget.challengeId));
      ref.invalidate(challengeDetailProvider(widget.challengeId));
    } on ApiError catch (e) {
      _snack(e.message);
    } finally {
      if (mounted) {
        setState(() => _sendingMessage = false);
      }
    }
  }

  Future<void> _coordinate() async {
    try {
      await ref.read(challengesRepositoryProvider).coordinate(widget.challengeId);
      _snack('Coordinación activada.');
      ref.invalidate(challengeDetailProvider(widget.challengeId));
      ref.invalidate(challengeMessagesProvider(widget.challengeId));
    } on ApiError catch (e) {
      _snack(e.message);
    }
  }

  Future<void> _rejectChallenge() async {
    final reason = await _askText('Motivo de rechazo (opcional)');
    if (!mounted) {
      return;
    }
    try {
      await ref
          .read(challengesRepositoryProvider)
          .reject(widget.challengeId, reason: reason);
      _snack('Reto rechazado.');
      ref.invalidate(challengeDetailProvider(widget.challengeId));
      ref.invalidate(challengeMessagesProvider(widget.challengeId));
    } on ApiError catch (e) {
      _snack(e.message);
    }
  }

  Future<void> _cancelChallenge() async {
    final reason = await _askText('Motivo de cancelación (opcional)');
    if (!mounted) {
      return;
    }
    try {
      await ref
          .read(challengesRepositoryProvider)
          .cancel(widget.challengeId, reason: reason);
      _snack('Reto cancelado.');
      ref.invalidate(challengeDetailProvider(widget.challengeId));
      ref.invalidate(challengeMessagesProvider(widget.challengeId));
    } on ApiError catch (e) {
      _snack(e.message);
    }
  }

  Future<void> _proposeField(List<Map<String, dynamic>> currentOptions) async {
    final nameController = TextEditingController();
    final addressController = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Proponer cancha'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nombre'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(labelText: 'Dirección'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
            FilledButton(
              onPressed: () async {
                try {
                  await ref.read(challengesRepositoryProvider).proposeFieldOption(
                        widget.challengeId,
                        fieldName: nameController.text.trim(),
                        fieldAddress: addressController.text.trim(),
                      );
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                  ref.invalidate(challengeDetailProvider(widget.challengeId));
                  ref.invalidate(challengeMessagesProvider(widget.challengeId));
                } on ApiError catch (e) {
                  _snack(e.message);
                }
              },
              child: const Text('Proponer'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _proposeTime(List<Map<String, dynamic>> currentOptions) async {
    DateTime selected = DateTime.now().add(const Duration(days: 2));
    final durationController = TextEditingController(text: '90');

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Proponer fecha/hora'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Inicio'),
                subtitle: Text(selected.toString()),
                trailing: IconButton(
                  onPressed: () async {
                    final day = await showDatePicker(
                      context: context,
                      initialDate: selected,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 40)),
                    );
                    if (day == null || !context.mounted) {
                      return;
                    }
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(selected),
                    );
                    if (time == null) {
                      return;
                    }
                    setState(() {
                      selected = DateTime(
                        day.year,
                        day.month,
                        day.day,
                        time.hour,
                        time.minute,
                      );
                    });
                  },
                  icon: const Icon(Icons.calendar_today),
                ),
              ),
              TextField(
                controller: durationController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Duración (min)'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
            FilledButton(
              onPressed: () async {
                try {
                  final duration = int.tryParse(durationController.text) ?? 90;
                  await ref.read(challengesRepositoryProvider).proposeTimeOption(
                        widget.challengeId,
                        startsAt: selected,
                        durationMinutes: duration,
                      );
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                  ref.invalidate(challengeDetailProvider(widget.challengeId));
                  ref.invalidate(challengeMessagesProvider(widget.challengeId));
                } on ApiError catch (e) {
                  _snack(e.message);
                }
              },
              child: const Text('Proponer'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _proposeConfiguration({
    required List<Map<String, dynamic>> fieldOptions,
    required List<Map<String, dynamic>> timeOptions,
  }) async {
    int? selectedField = int.tryParse(
      fieldOptions
          .firstWhere(
            (item) => (item['status'] ?? 'proposed').toString() == 'proposed',
            orElse: () => fieldOptions.first,
          )['id']
          .toString(),
    );
    int? selectedTime = int.tryParse(
      timeOptions
          .firstWhere(
            (item) => (item['status'] ?? 'proposed').toString() == 'proposed',
            orElse: () => timeOptions.first,
          )['id']
          .toString(),
    );
    bool invitedLink = false;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Configurar pichanga'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<int>(
                      initialValue: selectedField,
                      decoration: const InputDecoration(labelText: 'Cancha'),
                      items: fieldOptions
                          .where(
                            (item) =>
                                (item['status'] ?? 'proposed').toString() ==
                                'proposed',
                          )
                          .map((item) {
                            final id = int.tryParse(item['id'].toString()) ?? 0;
                            final label =
                                (item['field_name'] ??
                                        item['field_address'] ??
                                        'Cancha')
                                    .toString();
                            return DropdownMenuItem(
                              value: id,
                              child: Text(label),
                            );
                          })
                          .toList(),
                      onChanged: (value) => setDialogState(
                        () => selectedField = value,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      initialValue: selectedTime,
                      decoration: const InputDecoration(labelText: 'Fecha/hora'),
                      items: timeOptions
                          .where(
                            (item) =>
                                (item['status'] ?? 'proposed').toString() ==
                                'proposed',
                          )
                          .map((item) {
                            final id = int.tryParse(item['id'].toString()) ?? 0;
                            final label = (item['starts_at'] ?? '')
                                .toString()
                                .replaceFirst('T', ' ');
                            return DropdownMenuItem(
                              value: id,
                              child: Text(label),
                            );
                          })
                          .toList(),
                      onChanged: (value) =>
                          setDialogState(() => selectedTime = value),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile.adaptive(
                      value: invitedLink,
                      onChanged: (value) =>
                          setDialogState(() => invitedLink = value),
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Permitir link de invitados'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cerrar'),
                ),
                FilledButton(
                  onPressed: selectedField == null || selectedTime == null
                      ? null
                      : () async {
                          try {
                            await ref
                                .read(challengesRepositoryProvider)
                                .proposeConfiguration(
                                  widget.challengeId,
                                  fieldOptionId: selectedField!,
                                  timeOptionId: selectedTime!,
                                  invitedLinkEnabled: invitedLink,
                                );
                            if (context.mounted) {
                              Navigator.of(context).pop();
                            }
                            ref.invalidate(
                              challengeConfigurationsProvider(widget.challengeId),
                            );
                            ref.invalidate(
                              challengeMessagesProvider(widget.challengeId),
                            );
                          } on ApiError catch (e) {
                            _snack(e.message);
                          }
                        },
                  child: const Text('Enviar propuesta'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _decideConfiguration(int configurationId, String action) async {
    try {
      await ref.read(challengesRepositoryProvider).decideConfiguration(
            widget.challengeId,
            configurationId,
            action: action,
          );
      _snack(
        action == 'accept' ? 'Configuración aceptada.' : 'Configuración rechazada.',
      );
      ref.invalidate(challengeDetailProvider(widget.challengeId));
      ref.invalidate(challengeConfigurationsProvider(widget.challengeId));
      ref.invalidate(challengeMessagesProvider(widget.challengeId));
    } on ApiError catch (e) {
      _snack(e.message);
    }
  }

  Future<String?> _askText(String title) async {
    final controller = TextEditingController();
    return showDialog<String?>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Opcional',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('Cerrar'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(context).pop(controller.text.trim()),
              child: const Text('Enviar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _setPresence(bool active) async {
    try {
      await ref.read(challengesRepositoryProvider).updateChatPresence(
            isActive: active,
            challengeId: active ? widget.challengeId : null,
          );
    } catch (_) {
      // Ignorado: heartbeat best-effort.
    }
  }

  void _snack(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
