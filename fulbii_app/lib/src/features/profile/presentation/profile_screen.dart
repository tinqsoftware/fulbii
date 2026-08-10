import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

import '../../../config/app_config.dart';
import '../../../core/network/api_error.dart';
import '../../../core/formatters/spanish_date_formatter.dart';
import '../../../core/theme/theme_controller.dart';
import '../../auth/presentation/login_required_sheet.dart';
import '../../auth/session_controller.dart';
import '../data/profile_repository.dart';
import '../services/clip_processing_service.dart';
import 'edit_profile_screen.dart';
import 'player_rankings_screen.dart';
import '../../clubs/data/clubs_repository.dart';
import '../../pichangas/presentation/pichanga_history_screen.dart';
import '../../pichangas/presentation/pichanga_detail_screen.dart';
import '../../fields/presentation/field_submission_screen.dart';

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

final myRatingHistoryProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, int>(
      (ref, userId) =>
          ref.watch(profileRepositoryProvider).ratingHistory(userId),
    );

final ownPlayerRankingProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, int>(
      (ref, userId) =>
          ref.watch(profileRepositoryProvider).playerRanking(userId),
    );

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

    final topPadding = MediaQuery.of(context).padding.top + 16;
    final ratingsAsync = ref.watch(myRatingHistoryProvider(user.id));
    final rankingAsync = ref.watch(ownPlayerRankingProvider(user.id));

    return ListView(
      padding: EdgeInsets.fromLTRB(20, topPadding, 20, 24),
      children: [
        // Cabecera Principal
        Row(
          children: [
            CircleAvatar(
              radius: 42,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              backgroundImage:
                  user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                  ? NetworkImage(
                      resolveClubImageUrl(user.avatarUrl, appConfig) ?? '',
                    )
                  : null,
              child: (user.avatarUrl == null || user.avatarUrl!.isEmpty)
                  ? Text(
                      user.nick?.substring(0, 1).toUpperCase() ?? 'U',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 22,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '@${user.nick ?? ""}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user.email,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            IconButton.filledTonal(
              onPressed: () => _openEditProfile(context, ref),
              icon: const Icon(Icons.edit_outlined, size: 20),
              tooltip: 'Editar Perfil',
            ),
          ],
        ),
        const SizedBox(height: 18),

        // Info Chips
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildInfoChip(
              context,
              icon: Icons.wc_outlined,
              label: user.sexo == 'M'
                  ? 'Hombre'
                  : (user.sexo == 'F' ? 'Mujer' : 'Sexo: —'),
            ),
            _buildInfoChip(
              context,
              icon: Icons.height,
              label: user.alturaCm != null
                  ? '${user.alturaCm} cm'
                  : 'Altura: —',
            ),
            _buildInfoChip(
              context,
              icon: Icons.cake_outlined,
              label: SpanishDateFormatter.birthDate(user.fecNac),
            ),
            if (user.isSuperadmin)
              _buildInfoChip(
                context,
                icon: Icons.admin_panel_settings_outlined,
                label: 'Superadmin',
                color: Colors.amber.shade700,
              ),
          ],
        ),
        rankingAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (_, _) => const SizedBox.shrink(),
          data: (ranking) => Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Wrap(
              spacing: 8,
              children: [
                _buildInfoChip(
                  context,
                  icon: Icons.leaderboard_outlined,
                  label: ranking['total'] == null
                      ? 'Ranking total: —'
                      : 'Ranking total: #${ranking['total']}',
                ),
                _buildInfoChip(
                  context,
                  icon: Icons.cake_outlined,
                  label: ranking['age'] == null
                      ? 'Ranking edad: —'
                      : '${ranking['age_band_label'] ?? 'Edad'}: #${ranking['age']}',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const PlayerRankingsScreen(),
              ),
            ),
            icon: const Icon(Icons.leaderboard_outlined),
            label: const Text('Ver ranking'),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) =>
                    const FieldSubmissionScreen(showMyContributions: true),
              ),
            ),
            icon: const Icon(Icons.add_location_alt_outlined),
            label: const Text('Mis aportes de canchas'),
          ),
        ),
        const SizedBox(height: 24),
        const Divider(height: 1),
        const SizedBox(height: 20),

        // Sección de Clips
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Mis Clips de Perfil (máx 5)',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: _clipBusy ? null : _pickAndUploadClip,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: _clipBusy
                  ? const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.add, size: 16),
              label: const Text('Subir clip', style: TextStyle(fontSize: 13)),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Selecciona un tramo de 7s de un video con audio (duración 7-20s). Se optimizará verticalmente.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 14),
        clipsAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (error, _) => Text('Error al cargar clips: $error'),
          data: (items) {
            if (items.isEmpty) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'No tienes clips todavía.',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              );
            }

            return ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              onReorder: (oldIndex, newIndex) {
                if (_clipBusy) return;
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
        const SizedBox(height: 16),
        const Divider(height: 1),
        const SizedBox(height: 20),

        Text(
          'Historial de calificaciones',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        ratingsAsync.when(
          loading: () => const LinearProgressIndicator(minHeight: 2),
          error: (_, _) => const Text('No se pudo cargar tu historial.'),
          data: (items) => items.isEmpty
              ? const Text('Aún no recibiste calificaciones.')
              : Column(
                  children: items
                      .take(5)
                      .map(
                        (item) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.star_outline),
                          title: Text('@${item['rater_nick'] ?? 'Jugador'}'),
                          subtitle: Text(
                            'F ${item['fisico']} · A ${item['arquero']} · D ${item['delantero']} · M ${item['mediocampo']} · Def ${item['defensa']}',
                          ),
                        ),
                      )
                      .toList(),
                ),
        ),
        const SizedBox(height: 16),
        const Divider(height: 1),
        const SizedBox(height: 20),

        // Historial de Pichangas
        Row(
          children: [
            Expanded(
              child: Text(
                'Historial de Pichangas',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const PichangaHistoryScreen(),
                ),
              ),
              child: const Text('Ver todo'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        historyAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (error, _) => Text('Error al cargar historial: $error'),
          data: (items) {
            if (items.isEmpty) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'Sin historial todavía.',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              );
            }

            return Column(
              children: items.whereType<Map>().take(3).map((item) {
                final title = (item['title'] ?? 'Pichanga #${item['id']}')
                    .toString();
                final startsAt = SpanishDateFormatter.pichangaDate(
                  item['starts_at']?.toString(),
                );
                final status = SpanishDateFormatter.status(
                  item['status']?.toString(),
                );

                final id = int.tryParse(item['id'].toString()) ?? 0;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    radius: 18,
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.primaryContainer,
                    child: const Icon(Icons.sports_soccer_outlined, size: 18),
                  ),
                  title: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Text(
                    '$startsAt · $status',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: id <= 0
                      ? null
                      : () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                PichangaDetailScreen(pichangaId: id),
                          ),
                        ),
                );
              }).toList(),
            );
          },
        ),
        const SizedBox(height: 16),
        const Divider(height: 1),
        const SizedBox(height: 20),

        // Canchas Favoritas
        Text(
          'Mis Canchas Favoritas',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        favoritesAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (error, _) => Text('Error al cargar favoritos: $error'),
          data: (items) {
            if (items.isEmpty) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'Aún no tienes canchas favoritas agregadas.',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              );
            }

            return Column(
              children: items.whereType<Map>().take(10).map((item) {
                final field =
                    (item['field'] as Map?)?.cast<String, dynamic>() ?? {};
                final fieldName = (field['nombre'] ?? '').toString();
                final fieldId = int.tryParse(
                  item['polideportivo_id'].toString(),
                );

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    radius: 18,
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.secondaryContainer,
                    child: const Icon(Icons.star_outline, size: 18),
                  ),
                  title: Text(
                    fieldName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Text(
                    (field['descripcion'] ?? '').toString(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12),
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
                    icon: const Icon(Icons.delete_outline, size: 20),
                  ),
                );
              }).toList(),
            );
          },
        ),
        const SizedBox(height: 16),
        const Divider(height: 1),
        const SizedBox(height: 12),

        // Preferencias & Ajustes
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          secondary: Icon(
            themeMode == ThemeMode.dark
                ? Icons.dark_mode_outlined
                : Icons.light_mode_outlined,
            color: Theme.of(context).colorScheme.primary,
          ),
          title: const Text(
            'Modo Oscuro',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
          subtitle: const Text(
            'Tema visual de la interfaz.',
            style: TextStyle(fontSize: 12),
          ),
          value: themeMode == ThemeMode.dark,
          onChanged: (value) =>
              ref.read(themeModeProvider.notifier).setDarkMode(value),
        ),
        const SizedBox(height: 24),

        // Botón Cerrar Sesión
        OutlinedButton.icon(
          onPressed: () =>
              ref.read(sessionControllerProvider.notifier).logout(),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            side: const BorderSide(color: Colors.redAccent),
            foregroundColor: Colors.redAccent,
          ),
          icon: const Icon(Icons.logout_outlined, size: 18),
          label: const Text(
            'Cerrar Sesión',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    Color? color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color:
            color?.withValues(alpha: 0.1) ??
            Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color:
              color?.withValues(alpha: 0.3) ??
              Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: color ?? Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color ?? Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
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

    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const EditProfileScreen()));
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
