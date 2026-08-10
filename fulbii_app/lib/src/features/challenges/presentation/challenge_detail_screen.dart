import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formatters/spanish_date_formatter.dart';
import '../../../core/network/api_error.dart';
import '../../notifications/presentation/report_content_sheet.dart';
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
      return ref
          .watch(challengesRepositoryProvider)
          .configurations(challengeId);
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
    final messagesAsync = ref.watch(
      challengeMessagesProvider(widget.challengeId),
    );
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
              ref.invalidate(
                challengeConfigurationsProvider(widget.challengeId),
              );
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
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _ChallengeStatusBadge(status: status),
                          _ChallengeMetaBadge(
                            icon: isCoordinator
                                ? Icons.verified_user_outlined
                                : Icons.group_outlined,
                            label: isCoordinator
                                ? 'Eres coordinador'
                                : 'Participas como ${_sideLabel(mySide)}',
                          ),
                        ],
                      ),
                      if ((challenge['expires_at'] ?? '').toString().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'Responde hasta ${SpanishDateFormatter.pichangaDate(challenge['expires_at']?.toString())}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: _primaryAction(
                                status: status,
                                isCoordinator: isCoordinator,
                                fieldOptions: fieldOptions,
                                timeOptions: timeOptions,
                              ),
                              icon: Icon(
                                isCoordinator
                                    ? Icons.add_location_alt_outlined
                                    : Icons.handshake_outlined,
                              ),
                              label: Text(
                                isCoordinator ? 'Proponer cancha' : 'Coordinar',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            onPressed: () => _showMoreActions(
                              status: status,
                              isCoordinator: isCoordinator,
                              fieldOptions: fieldOptions,
                              timeOptions: timeOptions,
                            ),
                            icon: const Icon(Icons.more_horiz),
                            label: const Text('Más'),
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
                                          onPressed: () => _decideConfiguration(
                                            id,
                                            'accept',
                                          ),
                                          icon: const Icon(
                                            Icons.check,
                                            color: Colors.green,
                                          ),
                                        ),
                                        IconButton(
                                          onPressed: () => _decideConfiguration(
                                            id,
                                            'reject',
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
                                final content = (item['content'] ?? '')
                                    .toString();
                                final createdAt =
                                    SpanishDateFormatter.pichangaDate(
                                      item['created_at']?.toString(),
                                    );
                                final type = (item['message_type'] ?? 'text')
                                    .toString();
                                final isMine = item['is_mine'] == true;
                                final senderId =
                                    int.tryParse(
                                      item['sender_user_id'].toString(),
                                    ) ??
                                    0;
                                final messageId =
                                    int.tryParse(item['id'].toString()) ?? 0;

                                if (type == 'system') {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 8,
                                    ),
                                    child: Text(
                                      content,
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant,
                                          ),
                                    ),
                                  );
                                }

                                return _ChallengeMessageBubble(
                                  senderName: senderName,
                                  content: content,
                                  createdAt: createdAt,
                                  isMine: isMine,
                                  senderId: senderId,
                                  messageId: messageId,
                                );
                              },
                            );
                          },
                        ),
                      ),
                      SafeArea(
                        top: false,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _messageController,
                                  minLines: 1,
                                  maxLines: 3,
                                  textCapitalization:
                                      TextCapitalization.sentences,
                                  decoration: const InputDecoration(
                                    hintText: 'Escribe un mensaje',
                                    isDense: true,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              FilledButton(
                                onPressed: _sendingMessage
                                    ? null
                                    : _sendMessage,
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size(48, 48),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                ),
                                child: _sendingMessage
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.send),
                              ),
                            ],
                          ),
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
      await ref
          .read(challengesRepositoryProvider)
          .sendMessage(widget.challengeId, text);
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

  String _sideLabel(String side) => switch (side) {
    'challenger' => 'retador',
    'challenged' => 'retado',
    _ => 'participante',
  };

  VoidCallback? _primaryAction({
    required String status,
    required bool isCoordinator,
    required List<Map<String, dynamic>> fieldOptions,
    required List<Map<String, dynamic>> timeOptions,
  }) {
    final isActive = ['pending', 'negotiating', 'configuring'].contains(status);
    if (!isActive) return null;
    if (!isCoordinator) return _coordinate;
    return () => _proposeField(fieldOptions);
  }

  Future<void> _showMoreActions({
    required String status,
    required bool isCoordinator,
    required List<Map<String, dynamic>> fieldOptions,
    required List<Map<String, dynamic>> timeOptions,
  }) {
    final isActive = ['pending', 'negotiating', 'configuring'].contains(status);
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Wrap(
            children: [
              if (isCoordinator)
                ListTile(
                  leading: const Icon(Icons.schedule_outlined),
                  title: const Text('Proponer fecha y hora'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _proposeTime(timeOptions);
                  },
                ),
              if (isCoordinator &&
                  fieldOptions.isNotEmpty &&
                  timeOptions.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.tune_outlined),
                  title: const Text('Configurar pichanga'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _proposeConfiguration(
                      fieldOptions: fieldOptions,
                      timeOptions: timeOptions,
                    );
                  },
                ),
              if (isActive)
                ListTile(
                  leading: const Icon(Icons.thumb_down_alt_outlined),
                  title: const Text('Rechazar reto'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _rejectChallenge();
                  },
                ),
              if (isActive)
                ListTile(
                  leading: const Icon(Icons.cancel_outlined),
                  title: const Text('Cancelar reto'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _cancelChallenge();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _coordinate() async {
    try {
      await ref
          .read(challengesRepositoryProvider)
          .coordinate(widget.challengeId);
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
                  await ref
                      .read(challengesRepositoryProvider)
                      .proposeFieldOption(
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
                  await ref
                      .read(challengesRepositoryProvider)
                      .proposeTimeOption(
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
                      onChanged: (value) =>
                          setDialogState(() => selectedField = value),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      initialValue: selectedTime,
                      decoration: const InputDecoration(
                        labelText: 'Fecha/hora',
                      ),
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
                              challengeConfigurationsProvider(
                                widget.challengeId,
                              ),
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
      await ref
          .read(challengesRepositoryProvider)
          .decideConfiguration(
            widget.challengeId,
            configurationId,
            action: action,
          );
      _snack(
        action == 'accept'
            ? 'Configuración aceptada.'
            : 'Configuración rechazada.',
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
      await ref
          .read(challengesRepositoryProvider)
          .updateChatPresence(
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _ChallengeStatusBadge extends StatelessWidget {
  const _ChallengeStatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final label = switch (status) {
      'pending' => 'Pendiente',
      'negotiating' => 'En coordinación',
      'configuring' => 'Por confirmar',
      'confirmed' => 'Confirmado',
      'rejected' => 'Rechazado',
      'cancelled' => 'Cancelado',
      'expired' => 'Vencido',
      _ => 'Estado pendiente',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ChallengeMetaBadge extends StatelessWidget {
  const _ChallengeMetaBadge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}

class _ChallengeMessageBubble extends StatelessWidget {
  const _ChallengeMessageBubble({
    required this.senderName,
    required this.content,
    required this.createdAt,
    required this.isMine,
    required this.senderId,
    required this.messageId,
  });

  final String senderName;
  final String content;
  final String createdAt;
  final bool isMine;
  final int senderId;
  final int messageId;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bubbleColor = isMine
        ? colorScheme.primaryContainer
        : colorScheme.surfaceContainerHighest;
    final foreground = isMine
        ? colorScheme.onPrimaryContainer
        : colorScheme.onSurface;
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 280),
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: isMine
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Text(
              isMine ? 'Tú' : senderName,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Text(content, style: TextStyle(color: foreground)),
                ),
                if (!isMine && senderId > 0 && messageId > 0)
                  IconButton(
                    tooltip: 'Reportar mensaje',
                    icon: Icon(
                      Icons.flag_outlined,
                      size: 17,
                      color: foreground,
                    ),
                    visualDensity: VisualDensity.compact,
                    onPressed: () => showReportContentSheet(
                      context,
                      targetType: 'user',
                      targetId: senderId,
                      contentType: 'challenge_message',
                      contentId: messageId,
                      title: 'Reportar mensaje',
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              createdAt,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: foreground.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
