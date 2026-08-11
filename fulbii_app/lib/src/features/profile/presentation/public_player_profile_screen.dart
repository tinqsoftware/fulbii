import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'player_rating_dialog.dart';
import '../../../core/formatters/spanish_date_formatter.dart';
import 'package:video_player/video_player.dart';

import '../../../config/app_config.dart';
import '../../clubs/data/clubs_repository.dart';
import '../../notifications/presentation/report_content_sheet.dart';
import '../data/profile_repository.dart';

final publicPlayerProfileProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, ({int clubId, int userId})>((ref, key) {
      return ref
          .watch(clubsRepositoryProvider)
          .publicMemberProfile(key.clubId, key.userId);
    });

final publicPlayerClipsProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, int>((ref, userId) async {
      final items = await ref
          .watch(profileRepositoryProvider)
          .userProfileClips(userId);
      return items
          .whereType<Map>()
          .map((item) => item.cast<String, dynamic>())
          .toList();
    });

final publicRatingHistoryProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, int>(
      (ref, userId) =>
          ref.watch(profileRepositoryProvider).ratingHistory(userId),
    );

final publicRatingEligibilityProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, int>(
      (ref, userId) =>
          ref.watch(profileRepositoryProvider).ratingEligibility(userId),
    );

class PublicPlayerProfileScreen extends ConsumerWidget {
  const PublicPlayerProfileScreen({
    required this.clubId,
    required this.userId,
    super.key,
  });

  final int clubId;
  final int userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(
      publicPlayerProfileProvider((clubId: clubId, userId: userId)),
    );
    final clips = ref.watch(publicPlayerClipsProvider(userId));
    final ratingHistory = ref.watch(publicRatingHistoryProvider(userId));
    final ratingEligibility = ref.watch(
      publicRatingEligibilityProvider(userId),
    );
    final appConfig = ref.watch(appConfigProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil Deportivo'),
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Bloquear jugador',
            icon: const Icon(Icons.block_outlined),
            onPressed: () => _confirmBlock(context, ref, userId),
          ),
          IconButton(
            tooltip: 'Reportar jugador',
            icon: const Icon(Icons.flag_outlined),
            onPressed: () => showReportContentSheet(
              context,
              targetType: 'user',
              targetId: userId,
              title: 'Reportar jugador',
            ),
          ),
        ],
      ),
      body: profile.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'No se pudo cargar el perfil: $error',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (data) {
          final club = (data['club'] as Map?)?.cast<String, dynamic>() ?? {};
          final member =
              (data['member'] as Map?)?.cast<String, dynamic>() ?? {};
          final stats = (data['stats'] as Map?)?.cast<String, dynamic>() ?? {};
          final skills =
              (stats['skills'] as Map?)?.cast<String, dynamic>() ?? {};
          final name = (member['nick'] ?? 'Jugador').toString();
          final avatar = (member['avatar_url'] ?? '').toString();
          final stars = stats['star_average'] as num?;
          final playerAverage = stats['player_average'] as num?;
          final goalkeeperAverage = stats['goalkeeper_average'] as num?;
          final ranking =
              (data['ranking'] as Map?)?.cast<String, dynamic>() ?? {};
          final suggestedPosition =
              (stats['primary_position'] ?? stats['primary_role'] ?? '—')
                  .toString();

          final latestPichangas =
              (data['latest_pichangas'] as List?)
                  ?.cast<Map<String, dynamic>>() ??
              [];

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              // Cabecera del Integrante
              Row(
                children: [
                  _PublicAvatar(name: name, url: avatar),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          member['rol']?.toString() == 'admin'
                              ? 'Administrador del grupo'
                              : 'Integrante del grupo',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Miembro de ${club['nombre'] ?? 'este grupo'}',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Posición sugerida · $suggestedPosition',
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _Metric(
                      label: suggestedPosition == 'jugador'
                          ? 'Principal · jugador'
                          : 'Como jugador',
                      value: playerAverage == null
                          ? '—'
                          : playerAverage.toDouble().toStringAsFixed(1),
                      highlighted: suggestedPosition == 'jugador',
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _Metric(
                      label: suggestedPosition == 'arquero'
                          ? 'Principal · arquero'
                          : 'Como arquero',
                      value: goalkeeperAverage == null
                          ? '—'
                          : goalkeeperAverage.toDouble().toStringAsFixed(1),
                      highlighted: suggestedPosition == 'arquero',
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _Metric(
                      label: 'Pichangas',
                      value: '${stats['pichangas_played'] ?? 0}',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _ProfileMiniChip(
                    icon: Icons.star_rounded,
                    label: stars == null
                        ? 'Sin promedio'
                        : '★ ${stars.toDouble().toStringAsFixed(1)} principal',
                  ),
                  _ProfileMiniChip(
                    icon: Icons.leaderboard_outlined,
                    label: ranking['total'] == null
                        ? 'Ranking total —'
                        : 'Total #${ranking['total']}',
                  ),
                  _ProfileMiniChip(
                    icon: Icons.cake_outlined,
                    label: ranking['age'] == null
                        ? 'Edad —'
                        : '${ranking['age_band_label'] ?? 'Edad'} #${ranking['age']}',
                  ),
                ],
              ),
              ratingEligibility.when(
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
                data: (eligibility) => eligibility['allow'] == true
                    ? Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: () =>
                                _showProfileRatingDialog(context, ref, userId),
                            icon: const Icon(Icons.star_outline),
                            label: const Text('Calificar'),
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              const SizedBox(height: 14),
              Text(
                'Clips Públicos',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              clips.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (_, _) => const _EmptyProfileSection(
                  icon: Icons.videocam_off_outlined,
                  text: 'No se pudieron cargar los clips.',
                ),
                data: (items) => items.isEmpty
                    ? const _EmptyProfileSection(
                        icon: Icons.video_library_outlined,
                        text: 'Este jugador aún no tiene clips públicos.',
                      )
                    : SizedBox(
                        height: 112,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: items.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 12),
                          itemBuilder: (_, index) => _ClipCard(
                            clip: {
                              ...items[index],
                              'mp4_url': _resolvePublicClipUrl(
                                (items[index]['mp4_url'] ?? '').toString(),
                                appConfig.appLinkBaseUrl,
                              ),
                            },
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: 14),
              Text(
                'Habilidades',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              if (stars == null)
                const _EmptyProfileSection(
                  icon: Icons.bar_chart_outlined,
                  text: 'Todavía no tiene calificaciones deportivas.',
                )
              else
                ...[
                  ('Delantero', 'delantero'),
                  ('Mediocampo', 'mediocampo'),
                  ('Defensa', 'defensa'),
                  ('Arquero', 'arquero'),
                  ('Físico', 'fisico'),
                ].map(
                  (skill) => _SkillBar(
                    label: skill.$1,
                    value: (skills[skill.$2] as num?)?.toDouble(),
                  ),
                ),
              const SizedBox(height: 10),
              _ProfileActivityTabs(
                ratings: ratingHistory.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, _) => const Center(
                    child: Text('No se pudo cargar el historial.'),
                  ),
                  data: (items) => items.isEmpty
                      ? const _EmptyProfileSection(
                          icon: Icons.history_outlined,
                          text: 'Aún no tiene calificaciones públicas.',
                        )
                      : ListView.builder(
                          padding: EdgeInsets.zero,
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            final item = items[index];
                            return ListTile(
                              dense: true,
                              visualDensity: VisualDensity.compact,
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(
                                item['source'] == 'pichanga'
                                    ? Icons.sports_soccer_outlined
                                    : Icons.star_outline,
                                size: 18,
                              ),
                              title: Text(
                                '@${item['rater_nick'] ?? 'Jugador'}',
                              ),
                              subtitle: Text(
                                'F ${item['fisico']} · A ${item['arquero']} · D ${item['delantero']} · M ${item['mediocampo']} · Def ${item['defensa']}',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 11),
                              ),
                            );
                          },
                        ),
                ),
                pichangas: latestPichangas.isEmpty
                    ? const _EmptyProfileSection(
                        icon: Icons.sports_soccer_outlined,
                        text: 'Aún no registra pichangas jugadas.',
                      )
                    : ListView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: latestPichangas.length,
                        itemBuilder: (context, index) {
                          final item = latestPichangas[index];
                          return ListTile(
                            dense: true,
                            visualDensity: VisualDensity.compact,
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(
                              Icons.sports_soccer_outlined,
                              size: 18,
                            ),
                            title: Text(
                              (item['title'] ?? 'Pichanga #${item['id']}')
                                  .toString(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              '${SpanishDateFormatter.pichangaDate(item['starts_at']?.toString())} · ${SpanishDateFormatter.status(item['status']?.toString())}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 11),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

Future<void> _confirmBlock(
  BuildContext context,
  WidgetRef ref,
  int userId,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Bloquear jugador'),
      content: const Text(
        'No verás sus mensajes en chats compartidos ni recibirás sus avisos sociales.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Bloquear'),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;
  try {
    await ref.read(profileRepositoryProvider).blockUser(userId);
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Jugador bloqueado.')));
    }
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo bloquear al jugador.')),
      );
    }
  }
}

Future<void> _showProfileRatingDialog(
  BuildContext context,
  WidgetRef ref,
  int userId,
) async {
  final saved = await showPlayerRatingDialog(
    context,
    candidates: [PlayerRatingCandidate(id: userId, name: 'Jugador')],
    onSubmit: (ratedUserId, values, comment) => ref
        .read(profileRepositoryProvider)
        .ratePlayer(ratedUserId, {...values, 'comentario': comment}),
  );
  if (saved == true) {
    ref.invalidate(publicRatingHistoryProvider(userId));
    ref.invalidate(publicRatingEligibilityProvider(userId));
  }
}

class _ProfileRatingDialog extends StatefulWidget {
  const _ProfileRatingDialog({required this.onSubmit});

  final Future<void> Function(Map<String, double> values, String comment)
  onSubmit;

  @override
  State<_ProfileRatingDialog> createState() => _ProfileRatingDialogState();
}

class _ProfileRatingDialogState extends State<_ProfileRatingDialog> {
  static const _skills = <({String key, String label, IconData icon})>[
    (key: 'fisico', label: 'Físico', icon: Icons.directions_run_rounded),
    (key: 'arquero', label: 'Arquero', icon: Icons.sports_handball_outlined),
    (key: 'delantero', label: 'Delantero', icon: Icons.ads_click_rounded),
    (key: 'mediocampo', label: 'Mediocampo', icon: Icons.hub_outlined),
    (key: 'defensa', label: 'Defensa', icon: Icons.shield_outlined),
  ];

  final _commentController = TextEditingController();
  final _values = <String, double>{
    'fisico': 3,
    'arquero': 3,
    'delantero': 3,
    'mediocampo': 3,
    'defensa': 3,
  };
  var _isSubmitting = false;

  double get _average =>
      _values.values.reduce((total, value) => total + value) / _values.length;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      await widget.onSubmit(_values, _commentController.text.trim());
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo guardar la calificación: $error')),
        );
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      titlePadding: const EdgeInsets.fromLTRB(24, 22, 24, 8),
      contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
      title: const Text('Calificar jugador'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Valora cada habilidad de 0 a 5.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(Icons.star_rounded, color: colors.primary),
                  const SizedBox(width: 8),
                  const Expanded(child: Text('Promedio de esta calificación')),
                  Text(
                    '${_average.toStringAsFixed(1)} / 5',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            ..._skills.map(_buildSkillControl),
            const SizedBox(height: 8),
            TextField(
              controller: _commentController,
              minLines: 2,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Comentario opcional',
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: _isSubmitting ? null : _submit,
          icon: _isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.check_rounded),
          label: Text(_isSubmitting ? 'Guardando' : 'Guardar'),
        ),
      ],
    );
  }

  Widget _buildSkillControl(({String key, String label, IconData icon}) skill) {
    final colors = Theme.of(context).colorScheme;
    final value = _values[skill.key] ?? 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Column(
        children: [
          Row(
            children: [
              Icon(skill.icon, size: 19, color: colors.primary),
              const SizedBox(width: 8),
              Expanded(child: Text(skill.label)),
              Container(
                constraints: const BoxConstraints(minWidth: 42),
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  value.toStringAsFixed(1),
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          Slider(
            value: value,
            min: 0,
            max: 5,
            divisions: 10,
            label: value.toStringAsFixed(1),
            semanticFormatterCallback: (value) =>
                '${skill.label}: ${value.toStringAsFixed(1)} de 5',
            onChanged: _isSubmitting
                ? null
                : (value) => setState(() => _values[skill.key] = value),
          ),
        ],
      ),
    );
  }
}

String _resolvePublicClipUrl(String raw, String appLinkBaseUrl) {
  final value = raw.trim();
  if (value.isEmpty || (Uri.tryParse(value)?.hasScheme ?? false)) {
    return value;
  }
  final base = appLinkBaseUrl.endsWith('/')
      ? appLinkBaseUrl.substring(0, appLinkBaseUrl.length - 1)
      : appLinkBaseUrl;
  return '$base${value.startsWith('/') ? value : '/$value'}';
}

class _PublicAvatar extends ConsumerWidget {
  const _PublicAvatar({required this.name, required this.url});
  final String name;
  final String url;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(appConfigProvider);
    final resolvedUrl = resolveClubImageUrl(url, config);

    return CircleAvatar(
      radius: 42,
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      backgroundImage: resolvedUrl != null && resolvedUrl.isNotEmpty
          ? NetworkImage(resolvedUrl)
          : null,
      child: (resolvedUrl == null || resolvedUrl.isEmpty)
          ? Text(
              name.isEmpty ? '?' : name.substring(0, 1).toUpperCase(),
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
            )
          : null,
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    this.highlighted = false,
  });
  final String label;
  final String value;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 5),
      decoration: BoxDecoration(
        color: highlighted
            ? colorScheme.primaryContainer
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: highlighted ? colorScheme.primary : colorScheme.outlineVariant,
          width: highlighted ? 1.5 : 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color: highlighted
                  ? colorScheme.onPrimaryContainer
                  : colorScheme.primary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileMiniChip extends StatelessWidget {
  const _ProfileMiniChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: colors.primary),
          const SizedBox(width: 3),
          Text(
            label,
            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _ProfileActivityTabs extends StatelessWidget {
  const _ProfileActivityTabs({required this.ratings, required this.pichangas});

  final Widget ratings;
  final Widget pichangas;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            labelStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
            labelPadding: const EdgeInsets.symmetric(horizontal: 6),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: colors.outlineVariant,
            tabs: const [
              Tab(text: 'Últimas pichangas'),
              Tab(text: 'Calificaciones'),
            ],
          ),
          SizedBox(
            height: 184,
            child: TabBarView(children: [pichangas, ratings]),
          ),
        ],
      ),
    );
  }
}

class _SkillBar extends StatelessWidget {
  const _SkillBar({required this.label, required this.value});
  final String label;
  final double? value;

  @override
  Widget build(BuildContext context) {
    final safeValue = (value ?? 0).clamp(0, 5);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: safeValue / 5,
                minHeight: 6,
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest,
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 30,
            child: Text(
              value == null ? '—' : value!.toStringAsFixed(1),
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyProfileSection extends StatelessWidget {
  const _EmptyProfileSection({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.outline),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    ),
  );
}

class _ClipCard extends StatelessWidget {
  const _ClipCard({required this.clip});
  final Map<String, dynamic> clip;

  @override
  Widget build(BuildContext context) {
    final url = (clip['mp4_url'] ?? '').toString();
    final title = (clip['title'] ?? 'Clip deportivo').toString();
    return SizedBox(
      width: 110,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: url.isEmpty
            ? null
            : () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => _PublicClipPlayer(url: url, title: title),
                ),
              ),
        child: Ink(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.play_circle_fill_outlined,
                  size: 36,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PublicClipPlayer extends StatefulWidget {
  const _PublicClipPlayer({required this.url, required this.title});
  final String url;
  final String title;

  @override
  State<_PublicClipPlayer> createState() => _PublicClipPlayerState();
}

class _PublicClipPlayerState extends State<_PublicClipPlayer> {
  late final VideoPlayerController _controller =
      VideoPlayerController.networkUrl(Uri.parse(widget.url));

  @override
  void initState() {
    super.initState();
    _controller.initialize().then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.title)),
    body: Center(
      child: _controller.value.isInitialized
          ? AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  VideoPlayer(_controller),
                  IconButton.filled(
                    icon: Icon(
                      _controller.value.isPlaying
                          ? Icons.pause
                          : Icons.play_arrow,
                    ),
                    onPressed: () => setState(
                      () => _controller.value.isPlaying
                          ? _controller.pause()
                          : _controller.play(),
                    ),
                  ),
                ],
              ),
            )
          : const CircularProgressIndicator(),
    ),
  );
}
