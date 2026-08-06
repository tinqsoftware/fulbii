import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

import '../../../config/app_config.dart';
import '../../../core/network/api_error.dart';
import '../../../core/theme/theme_controller.dart';
import '../../auth/presentation/login_required_sheet.dart';
import '../../auth/session_controller.dart';
import '../data/profile_repository.dart';
import '../services/clip_processing_service.dart';

final pichangaHistoryProvider = FutureProvider.autoDispose<List<dynamic>>(
  (ref) => ref.watch(profileRepositoryProvider).pichangaHistory(),
);

final favoriteFieldsProvider = FutureProvider.autoDispose<List<dynamic>>(
  (ref) => ref.watch(profileRepositoryProvider).favoriteFields(),
);

final myProfileClipsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
      final items = await ref.watch(profileRepositoryProvider).myProfileClips();
      return items
          .whereType<Map>()
          .map((item) => item.cast<String, dynamic>())
          .toList();
    });

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _clipBusy = false;
  final ClipProcessingService _clipProcessingService = ClipProcessingService();

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    final session = ref.watch(sessionControllerProvider);
    final historyAsync = ref.watch(pichangaHistoryProvider);
    final favoritesAsync = ref.watch(favoriteFieldsProvider);
    final clipsAsync = ref.watch(myProfileClipsProvider);
    final appConfig = ref.watch(appConfigProvider);
    final themeMode = ref.watch(themeModeProvider);

    final user = session.user;

    if (user == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.person_outline, size: 56),
              const SizedBox(height: 14),
              Text(
                'Explora Fulbii sin cuenta',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              const Text(
                'Inicia sesión para crear pichangas, guardar favoritos y participar en grupos.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 22),
              FilledButton(
                onPressed: () =>
                    requireSignIn(context, ref, action: 'usar tu perfil'),
                child: const Text('Iniciar sesión'),
              ),
              const SizedBox(height: 14),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Modo oscuro'),
                value: themeMode == ThemeMode.dark,
                onChanged: (value) =>
                    ref.read(themeModeProvider.notifier).setDarkMode(value),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      child: Text(
                        user.nick?.substring(0, 1).toUpperCase() ?? 'U',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.nick ?? user.name,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          Text(user.email),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => _openEditProfile(context, ref),
                      icon: const Icon(Icons.edit),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Chip(label: Text('Sexo: ${user.sexo ?? '-'}')),
                    Chip(label: Text('Altura: ${user.alturaCm ?? '-'} cm')),
                    Chip(label: Text('Nac: ${user.fecNac ?? '-'}')),
                    if (user.isSuperadmin)
                      const Chip(label: Text('Superadmin')),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: SwitchListTile.adaptive(
            contentPadding: const EdgeInsets.symmetric(horizontal: 14),
            title: const Text('Modo oscuro'),
            subtitle: const Text('Se guarda solo en este equipo.'),
            value: themeMode == ThemeMode.dark,
            onChanged: (value) =>
                ref.read(themeModeProvider.notifier).setDarkMode(value),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Mis clips de perfil (máx 5)',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: _clipBusy ? null : _pickAndUploadClip,
                      icon: _clipBusy
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.add),
                      label: const Text('Subir clip'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Flujo: video con audio (7-20s) → eliges tramo exacto de 7s → compresión vertical 9:16 (objetivo 0.5MB-1.0MB, máximo 1.3MB).',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.black54),
                ),
                const SizedBox(height: 10),
                clipsAsync.when(
                  loading: () => const LinearProgressIndicator(minHeight: 2),
                  error: (error, _) =>
                      Text('No se pudieron cargar clips: $error'),
                  data: (items) {
                    if (items.isEmpty) {
                      return const Text('No tienes clips todavía.');
                    }

                    return ReorderableListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: items.length,
                      onReorder: (oldIndex, newIndex) {
                        if (_clipBusy) {
                          return;
                        }
                        _reorderClips(items, oldIndex, newIndex);
                      },
                      itemBuilder: (context, index) {
                        return _buildClipTile(
                          context,
                          key: ValueKey('clip_${items[index]['id']}'),
                          index: index,
                          item: items[index],
                          appLinkBaseUrl: appConfig.appLinkBaseUrl,
                        );
                      },
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
                  'Historial de pichangas',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                historyAsync.when(
                  loading: () => const LinearProgressIndicator(minHeight: 2),
                  error: (error, _) =>
                      Text('No se pudo cargar historial: $error'),
                  data: (items) {
                    if (items.isEmpty) {
                      return const Text('Sin historial todavía.');
                    }

                    return Column(
                      children: items.whereType<Map>().take(20).map((item) {
                        final title =
                            (item['title'] ?? 'Pichanga #${item['id']}')
                                .toString();
                        final startsAt = (item['starts_at'] ?? '')
                            .toString()
                            .replaceFirst('T', ' ');
                        final status = (item['status'] ?? '').toString();

                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(title),
                          subtitle: Text('$startsAt • $status'),
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
                  'Mis canchas favoritas',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                favoritesAsync.when(
                  loading: () => const LinearProgressIndicator(minHeight: 2),
                  error: (error, _) =>
                      Text('No se pudo cargar favoritos: $error'),
                  data: (items) {
                    if (items.isEmpty) {
                      return const Text('No tienes canchas favoritas.');
                    }

                    return Column(
                      children: items.whereType<Map>().take(20).map((item) {
                        final field =
                            (item['field'] as Map?)?.cast<String, dynamic>() ??
                            {};
                        final fieldName = (field['nombre'] ?? '').toString();
                        final fieldId = int.tryParse(
                          item['polideportivo_id'].toString(),
                        );

                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(fieldName),
                          subtitle: Text(
                            (field['descripcion'] ?? '').toString(),
                          ),
                          trailing: IconButton(
                            onPressed: fieldId == null
                                ? null
                                : () async {
                                    await ref
                                        .read(profileRepositoryProvider)
                                        .removeFavoriteField(fieldId);
                                    ref.invalidate(favoriteFieldsProvider);
                                  },
                            icon: const Icon(Icons.delete_outline),
                          ),
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
        FilledButton.icon(
          onPressed: () =>
              ref.read(sessionControllerProvider.notifier).logout(),
          icon: const Icon(Icons.logout),
          label: const Text('Cerrar sesión'),
        ),
      ],
    );
  }

  Widget _buildClipTile(
    BuildContext context, {
    required Key key,
    required int index,
    required Map<String, dynamic> item,
    required String appLinkBaseUrl,
  }) {
    final clipId = int.tryParse(item['id'].toString());
    final title = (item['title'] ?? '').toString().trim();
    final durationMs = int.tryParse(item['duration_ms'].toString()) ?? 0;
    final fileSizeBytes = int.tryParse(item['file_size_bytes'].toString()) ?? 0;
    final hasAudio = item['has_audio'] == true || item['has_audio'] == 1;
    final mp4UrlRaw = (item['mp4_url'] ?? '').toString();
    final mp4Url = _resolveClipUrl(mp4UrlRaw, appLinkBaseUrl);

    return Container(
      key: key,
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ReorderableDragStartListener(
              index: index,
              enabled: !_clipBusy,
              child: const Padding(
                padding: EdgeInsets.only(top: 34),
                child: Icon(Icons.drag_handle, color: Colors.black45),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 96,
              height: 96,
              child: GestureDetector(
                onTap: mp4Url.isEmpty
                    ? null
                    : () => _openClipFullscreen(context, mp4Url, title),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _ProfileClipPreview(url: mp4Url),
                      const Positioned(
                        right: 6,
                        top: 6,
                        child: Icon(
                          Icons.fullscreen,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title.isEmpty ? 'Clip #${item['id']}' : title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Duración: ${_formatSeconds(durationMs)} • Peso: ${_formatBytes(fileSizeBytes)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        hasAudio ? Icons.volume_up : Icons.volume_off,
                        size: 16,
                        color: hasAudio ? Colors.green : Colors.black45,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        hasAudio ? 'Con audio' : 'Sin audio',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints.tightFor(width: 30, height: 30),
              onPressed: clipId == null || _clipBusy
                  ? null
                  : () => _deleteClip(clipId),
              icon: const Icon(Icons.delete_outline, size: 18),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUploadClip() async {
    setState(() => _clipBusy = true);
    try {
      final picker = ImagePicker();
      final picked = await picker.pickVideo(source: ImageSource.gallery);
      if (picked == null) {
        return;
      }

      final file = File(picked.path);
      final controller = VideoPlayerController.file(file);
      await controller.initialize();
      final duration = controller.value.duration;
      await controller.dispose();

      if (duration < const Duration(seconds: 7)) {
        throw ApiError('El video origen debe durar al menos 7 segundos.');
      }
      if (duration > const Duration(seconds: 20)) {
        throw ApiError('El video origen no puede exceder 20 segundos.');
      }

      Duration startAt = Duration.zero;
      if (duration > const Duration(seconds: 7)) {
        if (!mounted) {
          return;
        }
        final pickedStart = await _pickSevenSecondWindowStart(
          context: context,
          sourceFile: file,
          sourceDuration: duration,
        );
        if (pickedStart == null) {
          return;
        }
        startAt = pickedStart;
      }

      String? title;
      if (mounted) {
        title = await _askClipTitle(context);
      }

      final processed = await _clipProcessingService.processVerticalSevenSecond(
        sourceFile: file,
        startAt: startAt,
      );

      await ref
          .read(profileRepositoryProvider)
          .uploadProfileClip(
            file: processed.file,
            sourceDurationMs: duration.inMilliseconds,
            durationMs: processed.durationMs,
            hasAudio: processed.hasAudio,
            title: title,
            width: processed.width,
            height: processed.height,
          );

      ref.invalidate(myProfileClipsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Clip subido (${_formatBytes(processed.fileSizeBytes)}).',
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('No se pudo subir el clip: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _clipBusy = false);
      }
    }
  }

  Future<Duration?> _pickSevenSecondWindowStart({
    required BuildContext context,
    required File sourceFile,
    required Duration sourceDuration,
  }) {
    return showDialog<Duration?>(
      context: context,
      builder: (dialogContext) => _SevenSecondWindowPickerDialog(
        sourceFile: sourceFile,
        sourceDuration: sourceDuration,
      ),
    );
  }

  Future<void> _deleteClip(int clipId) async {
    setState(() => _clipBusy = true);
    try {
      await ref.read(profileRepositoryProvider).deleteProfileClip(clipId);
      ref.invalidate(myProfileClipsProvider);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Clip eliminado.')));
      }
    } on ApiError catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) {
        setState(() => _clipBusy = false);
      }
    }
  }

  Future<void> _reorderClips(
    List<Map<String, dynamic>> items,
    int oldIndex,
    int newIndex,
  ) async {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    if (oldIndex == newIndex) {
      return;
    }
    final ids = items
        .map((item) => int.tryParse(item['id'].toString()))
        .whereType<int>()
        .toList();
    if (ids.length != items.length) {
      return;
    }

    setState(() => _clipBusy = true);
    try {
      final swapped = [...ids];
      final movedId = swapped.removeAt(oldIndex);
      swapped.insert(newIndex, movedId);

      await ref.read(profileRepositoryProvider).reorderProfileClips(swapped);
      ref.invalidate(myProfileClipsProvider);
    } on ApiError catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) {
        setState(() => _clipBusy = false);
      }
    }
  }

  void _openClipFullscreen(BuildContext context, String url, String title) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _ProfileClipFullscreenPage(url: url, title: title),
      ),
    );
  }

  Future<String?> _askClipTitle(BuildContext context) async {
    final controller = TextEditingController();
    final result = await showDialog<String?>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Título del clip (opcional)'),
          content: TextField(
            controller: controller,
            maxLength: 120,
            decoration: const InputDecoration(labelText: 'Título'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(null),
              child: const Text('Saltar'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(controller.text.trim()),
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
    controller.dispose();
    return result;
  }

  String _resolveClipUrl(String raw, String appLinkBaseUrl) {
    final value = raw.trim();
    if (value.isEmpty) {
      return value;
    }
    final uri = Uri.tryParse(value);
    if (uri != null && uri.hasScheme) {
      return value;
    }
    final base = appLinkBaseUrl.endsWith('/')
        ? appLinkBaseUrl.substring(0, appLinkBaseUrl.length - 1)
        : appLinkBaseUrl;
    final path = value.startsWith('/') ? value : '/$value';
    return '$base$path';
  }

  String _formatSeconds(int durationMs) {
    if (durationMs <= 0) {
      return '-';
    }
    final seconds = (durationMs / 1000).toStringAsFixed(1);
    return '${seconds}s';
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) {
      return '-';
    }
    final kb = bytes / 1024;
    if (kb < 1024) {
      return '${kb.toStringAsFixed(0)} KB';
    }
    final mb = kb / 1024;
    return '${mb.toStringAsFixed(2)} MB';
  }

  Future<void> _openEditProfile(BuildContext context, WidgetRef ref) async {
    final session = ref.read(sessionControllerProvider);
    final user = session.user;
    if (user == null) {
      return;
    }

    final nameController = TextEditingController(text: user.name);
    final avatarController = TextEditingController(text: user.avatarUrl ?? '');
    final birthController = TextEditingController(text: user.fecNac ?? '');
    final heightController = TextEditingController(
      text: '${user.alturaCm ?? ''}',
    );
    String sexo = user.sexo ?? 'M';

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Editar perfil'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Nombre'),
                    ),
                    TextField(
                      controller: avatarController,
                      decoration: const InputDecoration(
                        labelText: 'Avatar URL',
                      ),
                    ),
                    TextField(
                      controller: birthController,
                      decoration: const InputDecoration(
                        labelText: 'Fecha nac (YYYY-MM-DD)',
                      ),
                    ),
                    TextField(
                      controller: heightController,
                      decoration: const InputDecoration(
                        labelText: 'Altura (cm)',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    DropdownButtonFormField<String>(
                      initialValue: sexo,
                      items: const [
                        DropdownMenuItem(value: 'M', child: Text('Hombre')),
                        DropdownMenuItem(value: 'F', child: Text('Mujer')),
                      ],
                      onChanged: (value) =>
                          setState(() => sexo = value ?? sexo),
                      decoration: const InputDecoration(labelText: 'Sexo'),
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
                      await ref.read(profileRepositoryProvider).updateProfile({
                        'name': nameController.text.trim(),
                        'avatar_url': avatarController.text.trim(),
                        'fec_nac': birthController.text.trim(),
                        'altura_cm': int.tryParse(heightController.text.trim()),
                        'sexo': sexo,
                      });
                      await ref
                          .read(sessionControllerProvider.notifier)
                          .refreshMe();
                      ref.invalidate(pichangaHistoryProvider);
                      if (context.mounted) {
                        Navigator.of(dialogContext).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Perfil actualizado.')),
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
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );

    if (context.mounted) {
      nameController.dispose();
      avatarController.dispose();
      birthController.dispose();
      heightController.dispose();
    }
  }
}

class _SevenSecondWindowPickerDialog extends StatefulWidget {
  const _SevenSecondWindowPickerDialog({
    required this.sourceFile,
    required this.sourceDuration,
  });

  final File sourceFile;
  final Duration sourceDuration;

  @override
  State<_SevenSecondWindowPickerDialog> createState() =>
      _SevenSecondWindowPickerDialogState();
}

class _SevenSecondWindowPickerDialogState
    extends State<_SevenSecondWindowPickerDialog> {
  late final VideoPlayerController _controller;
  bool _loading = true;
  double _startMs = 0;

  int get _maxStartMs =>
      (widget.sourceDuration - const Duration(seconds: 7)).inMilliseconds;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(widget.sourceFile);
    _init();
  }

  Future<void> _init() async {
    try {
      await _controller.initialize();
      await _controller.setVolume(0);
      if (!mounted) {
        return;
      }
      setState(() => _loading = false);
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _previewSelection() async {
    if (!_controller.value.isInitialized) {
      return;
    }
    final startAt = Duration(milliseconds: _startMs.round());
    await _controller.seekTo(startAt);
    await _controller.play();
    await Future<void>.delayed(const Duration(seconds: 7));
    if (!mounted) {
      return;
    }
    await _controller.pause();
  }

  @override
  Widget build(BuildContext context) {
    final mediaSize = MediaQuery.sizeOf(context);
    final startAt = Duration(milliseconds: _startMs.round());
    final endAt = startAt + const Duration(seconds: 7);
    final divisions = _maxStartMs > 0 ? (_maxStartMs / 100).round() : 1;
    final previewHeight = min(220.0, mediaSize.height * 0.28);

    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
      titlePadding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      contentPadding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      actionsPadding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      title: const Text('Selecciona el tramo de 7 segundos'),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 520,
          maxHeight: mediaSize.height * 0.56,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Mueve el selector y confirma qué 7 segundos se van a subir.',
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: previewHeight,
                width: double.infinity,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: ColoredBox(
                    color: Colors.black,
                    child: _loading
                        ? const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : _controller.value.isInitialized
                        ? Center(
                            child: AspectRatio(
                              aspectRatio: _controller.value.aspectRatio,
                              child: VideoPlayer(_controller),
                            ),
                          )
                        : const Center(
                            child: Icon(
                              Icons.videocam_off_outlined,
                              color: Colors.white70,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Slider(
                value: _startMs.clamp(0, _maxStartMs.toDouble()),
                min: 0,
                max: _maxStartMs.toDouble(),
                divisions: divisions <= 0 ? null : divisions,
                label:
                    '${(startAt.inMilliseconds / 1000).toStringAsFixed(1)}s → ${(endAt.inMilliseconds / 1000).toStringAsFixed(1)}s',
                onChanged: _maxStartMs <= 0
                    ? null
                    : (value) {
                        setState(() => _startMs = value);
                      },
              ),
              Text(
                'Segmento: ${_formatDuration(startAt)} - ${_formatDuration(endAt)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 6),
              OutlinedButton.icon(
                onPressed: _loading ? null : _previewSelection,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Previsualizar 7s'),
              ),
            ],
          ),
        ),
      ),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(
            context,
          ).pop(Duration(milliseconds: _startMs.round())),
          child: const Text('Usar tramo'),
        ),
      ],
    );
  }

  String _formatDuration(Duration value) {
    final min = value.inMinutes.remainder(60).toString().padLeft(2, '0');
    final sec = value.inSeconds.remainder(60).toString().padLeft(2, '0');
    final msTenths = ((value.inMilliseconds % 1000) / 100).floor();
    return '$min:$sec.$msTenths';
  }
}

class _ProfileClipFullscreenPage extends StatefulWidget {
  const _ProfileClipFullscreenPage({required this.url, required this.title});

  final String url;
  final String title;

  @override
  State<_ProfileClipFullscreenPage> createState() =>
      _ProfileClipFullscreenPageState();
}

class _ProfileClipFullscreenPageState
    extends State<_ProfileClipFullscreenPage> {
  VideoPlayerController? _controller;
  bool _loading = true;
  bool _muted = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final uri = Uri.tryParse(widget.url);
    if (uri == null || !uri.hasScheme) {
      if (mounted) {
        setState(() => _loading = false);
      }
      return;
    }
    final controller = VideoPlayerController.networkUrl(uri);
    try {
      await controller.initialize();
      await controller.setLooping(true);
      await controller.setVolume(1);
      await controller.play();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _loading = false;
      });
    } catch (_) {
      await controller.dispose();
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _toggleMute() {
    final controller = _controller;
    if (controller == null) {
      return;
    }
    setState(() => _muted = !_muted);
    controller.setVolume(_muted ? 0 : 1);
  }

  void _togglePlay() {
    final controller = _controller;
    if (controller == null) {
      return;
    }
    if (controller.value.isPlaying) {
      controller.pause();
    } else {
      controller.play();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final initialized = controller?.value.isInitialized == true;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(widget.title.isEmpty ? 'Clip' : widget.title),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
            : !initialized
            ? const Center(
                child: Text(
                  'No se pudo cargar el clip.',
                  style: TextStyle(color: Colors.white70),
                ),
              )
            : Stack(
                children: [
                  Center(
                    child: AspectRatio(
                      aspectRatio: controller!.value.aspectRatio,
                      child: VideoPlayer(controller),
                    ),
                  ),
                  Positioned(
                    left: 12,
                    right: 12,
                    bottom: 12,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            onPressed: _togglePlay,
                            color: Colors.white,
                            icon: Icon(
                              controller.value.isPlaying
                                  ? Icons.pause
                                  : Icons.play_arrow,
                            ),
                          ),
                          IconButton(
                            onPressed: _toggleMute,
                            color: Colors.white,
                            icon: Icon(
                              _muted ? Icons.volume_off : Icons.volume_up,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _ProfileClipPreview extends StatefulWidget {
  const _ProfileClipPreview({required this.url});

  final String url;

  @override
  State<_ProfileClipPreview> createState() => _ProfileClipPreviewState();
}

class _ProfileClipPreviewState extends State<_ProfileClipPreview> {
  VideoPlayerController? _controller;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    if (widget.url.isEmpty) {
      if (mounted) {
        setState(() => _loading = false);
      }
      return;
    }

    final uri = Uri.tryParse(widget.url);
    if (uri == null || !uri.hasScheme) {
      if (mounted) {
        setState(() => _loading = false);
      }
      return;
    }

    final controller = VideoPlayerController.networkUrl(uri);
    try {
      await controller.initialize();
      await controller.setLooping(true);
      await controller.setVolume(0);
      await controller.play();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _loading = false;
      });
    } catch (_) {
      await controller.dispose();
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return const ColoredBox(
        color: Color(0x11000000),
        child: Center(
          child: Icon(Icons.videocam_off_outlined, color: Colors.black45),
        ),
      );
    }
    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: controller.value.size.width,
        height: controller.value.size.height,
        child: VideoPlayer(controller),
      ),
    );
  }
}
