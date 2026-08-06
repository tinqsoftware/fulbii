import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    final appLinkBaseUrl = ref.watch(appConfigProvider).appLinkBaseUrl;
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil deportivo')),
      body: profile.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('No se pudo cargar el perfil: $error'),
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

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              Text(
                'Miembro de ${club['nombre'] ?? 'este grupo'}',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
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
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          member['rol']?.toString() == 'admin'
                              ? 'Administrador del grupo'
                              : 'Integrante del grupo',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  SizedBox(
                    width: 164,
                    child: _Metric(
                      label: 'Estrellas',
                      value: stars == null
                          ? '—'
                          : '★ ${stars.toDouble().toStringAsFixed(1)}',
                    ),
                  ),
                  SizedBox(
                    width: 164,
                    child: _Metric(
                      label: 'Promedio jugador',
                      value: playerAverage == null
                          ? '—'
                          : playerAverage.toDouble().toStringAsFixed(1),
                    ),
                  ),
                  SizedBox(
                    width: 164,
                    child: _Metric(
                      label: 'Como arquero',
                      value: goalkeeperAverage == null
                          ? '—'
                          : goalkeeperAverage.toDouble().toStringAsFixed(1),
                    ),
                  ),
                  SizedBox(
                    width: 164,
                    child: _Metric(
                      label: 'Pichangas',
                      value: '${stats['pichangas_played'] ?? 0}',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Text(
                'Habilidades',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              if (stars == null)
                const _EmptyProfileSection(
                  icon: Icons.bar_chart_outlined,
                  text: 'Todavía no tiene calificaciones deportivas.',
                )
              else
                ...const [
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
              const SizedBox(height: 28),
              Text(
                'Clips',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              clips.when(
                loading: () => const SizedBox(
                  height: 156,
                  child: Center(child: CircularProgressIndicator()),
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
                        height: 180,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: items.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 10),
                          itemBuilder: (_, index) => _ClipCard(
                            clip: {
                              ...items[index],
                              'mp4_url': _resolvePublicClipUrl(
                                (items[index]['mp4_url'] ?? '').toString(),
                                appLinkBaseUrl,
                              ),
                            },
                          ),
                        ),
                      ),
              ),
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

class _PublicAvatar extends StatelessWidget {
  const _PublicAvatar({required this.name, required this.url});
  final String name;
  final String url;

  @override
  Widget build(BuildContext context) => CircleAvatar(
    radius: 42,
    child: url.isEmpty
        ? Text(
            name.isEmpty ? '?' : name.substring(0, 1).toUpperCase(),
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
          )
        : ClipOval(
            child: Image.network(
              url,
              width: 84,
              height: 84,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Center(
                child: Text(
                  name.isEmpty ? '?' : name.substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
  );
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      children: [
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 3),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    ),
  );
}

class _SkillBar extends StatelessWidget {
  const _SkillBar({required this.label, required this.value});
  final String label;
  final double? value;

  @override
  Widget build(BuildContext context) {
    final safeValue = (value ?? 0).clamp(0, 5);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(width: 92, child: Text(label)),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: safeValue / 5,
                minHeight: 8,
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 30,
            child: Text(
              value == null ? '—' : value!.toStringAsFixed(1),
              textAlign: TextAlign.end,
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
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      children: [
        Icon(icon),
        const SizedBox(width: 10),
        Expanded(child: Text(text)),
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
      width: 118,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
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
            borderRadius: BorderRadius.circular(14),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.play_circle_fill_outlined, size: 42),
                const SizedBox(height: 10),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
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
