import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/formatters/spanish_date_formatter.dart';
import 'package:video_player/video_player.dart';

import '../../../config/app_config.dart';
import '../../clubs/data/clubs_repository.dart';
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
    final appConfig = ref.watch(appConfigProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil Deportivo'), elevation: 0),
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
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(height: 1),
              const SizedBox(height: 20),

              // Métricas de Rendimiento (Grid 2x2 responsivo y elegante)
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 2.2,
                children: [
                  _Metric(
                    label: 'Estrellas',
                    value: stars == null
                        ? '—'
                        : '★ ${stars.toDouble().toStringAsFixed(1)}',
                  ),
                  _Metric(
                    label: 'Promedio jugador',
                    value: playerAverage == null
                        ? '—'
                        : playerAverage.toDouble().toStringAsFixed(1),
                  ),
                  _Metric(
                    label: 'Como arquero',
                    value: goalkeeperAverage == null
                        ? '—'
                        : goalkeeperAverage.toDouble().toStringAsFixed(1),
                  ),
                  _Metric(
                    label: 'Pichangas',
                    value: '${stats['pichangas_played'] ?? 0}',
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(height: 1),
              const SizedBox(height: 20),

              // Habilidades
              Text(
                'Habilidades',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              if (stars == null)
                const _EmptyProfileSection(
                  icon: Icons.bar_chart_outlined,
                  text: 'Todavía no tiene calificaciones deportivas.',
                )
              else
                ...[
                  ('Físico', 'fisico'),
                  ('Arquero', 'arquero'),
                  ('Defensa', 'defensa'),
                  ('Mediocampo', 'mediocampo'),
                  ('Delantero', 'delantero'),
                ].map(
                  (skill) => _SkillBar(
                    label: skill.$1,
                    value: (skills[skill.$2] as num?)?.toDouble(),
                  ),
                ),
              const SizedBox(height: 20),
              const Divider(height: 1),
              const SizedBox(height: 20),

              // Clips públicos
              Text(
                'Clips Públicos',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              clips.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (_, __) => const _EmptyProfileSection(
                  icon: Icons.videocam_off_outlined,
                  text: 'No se pudieron cargar los clips.',
                ),
                data: (items) => items.isEmpty
                    ? const _EmptyProfileSection(
                        icon: Icons.video_library_outlined,
                        text: 'Este jugador aún no tiene clips públicos.',
                      )
                    : SizedBox(
                        height: 140,
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
              const SizedBox(height: 20),
              const Divider(height: 1),
              const SizedBox(height: 20),

              // Últimas Pichangas del jugador
              Text(
                'Últimas Pichangas Jugadas',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              if (latestPichangas.isEmpty)
                const _EmptyProfileSection(
                  icon: Icons.sports_soccer_outlined,
                  text: 'Aún no registra pichangas jugadas.',
                )
              else
                ...latestPichangas.map((item) {
                  final title = (item['title'] ?? 'Pichanga #${item['id']}')
                      .toString();
                  final startsAt = SpanishDateFormatter.pichangaDate(
                    item['starts_at']?.toString(),
                  );
                  final status = SpanishDateFormatter.status(
                    item['status']?.toString(),
                  );

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
                  );
                }),
            ],
          );
        },
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
  const _Metric({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color: colorScheme.primary,
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
