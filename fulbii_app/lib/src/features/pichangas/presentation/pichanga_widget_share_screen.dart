import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../data/pichangas_repository.dart';
import '../../../services/widget/widget_confirmed_mapper.dart';

enum PichangaWidgetShareInitialAction { none, shareLink, shareLineup }

final pichangaWidgetShareDetailProvider =
    FutureProvider.autoDispose.family<Map<String, dynamic>, int>((ref, pichangaId) {
  return ref.watch(pichangasRepositoryProvider).detail(pichangaId);
});

class PichangaWidgetShareScreen extends ConsumerStatefulWidget {
  const PichangaWidgetShareScreen({
    required this.pichangaId,
    this.initialAction = PichangaWidgetShareInitialAction.none,
    super.key,
  });

  final int pichangaId;
  final PichangaWidgetShareInitialAction initialAction;

  @override
  ConsumerState<PichangaWidgetShareScreen> createState() =>
      _PichangaWidgetShareScreenState();
}

class _PichangaWidgetShareScreenState
    extends ConsumerState<PichangaWidgetShareScreen> {
  final GlobalKey _lineupBoundaryKey = GlobalKey();
  bool _sharing = false;
  bool _autoActionTriggered = false;

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(
      pichangaWidgetShareDetailProvider(widget.pichangaId),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Compartir pichanga')),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text('No se pudo cargar la pichanga: $error'),
          ),
        ),
        data: (data) {
          final pichanga =
              (data['pichanga'] as Map?)?.cast<String, dynamic>() ??
              <String, dynamic>{};
          final teams = pichanga['teams'] is List
              ? (pichanga['teams'] as List)
                    .whereType<Map>()
                    .map((item) => item.cast<String, dynamic>())
                    .toList()
              : <Map<String, dynamic>>[];
          final lineupTeam = _pickLineupTeam(teams);

          _triggerInitialActionIfNeeded(pichanga, lineupTeam);

          return ListView(
            padding: const EdgeInsets.all(14),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (pichanga['title'] ?? 'Pichanga').toString(),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 6),
                      Text(_headerLine(pichanga)),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          FilledButton.icon(
                            onPressed: _sharing
                                ? null
                                : () => _shareLink(pichanga),
                            icon: const Icon(Icons.share_outlined),
                            label: const Text('Compartir'),
                          ),
                          OutlinedButton.icon(
                            onPressed: _sharing || lineupTeam == null
                                ? null
                                : () => _shareLineup(pichanga, lineupTeam),
                            icon: const Icon(Icons.sports_soccer_outlined),
                            label: const Text('Canchita'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _buildTeamsCard(context, teams),
              const SizedBox(height: 10),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Vista previa de canchita',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: RepaintBoundary(
                          key: _lineupBoundaryKey,
                          child: _LineupShareCanvas(
                            pichanga: pichanga,
                            team: lineupTeam,
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

  void _triggerInitialActionIfNeeded(
    Map<String, dynamic> pichanga,
    Map<String, dynamic>? lineupTeam,
  ) {
    if (_autoActionTriggered || widget.initialAction == PichangaWidgetShareInitialAction.none) {
      return;
    }

    _autoActionTriggered = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      switch (widget.initialAction) {
        case PichangaWidgetShareInitialAction.shareLink:
          _shareLink(pichanga);
          break;
        case PichangaWidgetShareInitialAction.shareLineup:
          if (lineupTeam != null) {
            _shareLineup(pichanga, lineupTeam);
          }
          break;
        case PichangaWidgetShareInitialAction.none:
          break;
      }
    });
  }

  String _headerLine(Map<String, dynamic> pichanga) {
    final startsAt = DateTime.tryParse((pichanga['starts_at'] ?? '').toString())
        ?.toLocal();
    final startsAtLabel = startsAt == null
        ? '-'
        : '${startsAt.day.toString().padLeft(2, '0')}/${startsAt.month.toString().padLeft(2, '0')} ${startsAt.hour.toString().padLeft(2, '0')}:${startsAt.minute.toString().padLeft(2, '0')}';
    final playersPerTeam = _toInt(pichanga['players_per_team']) ?? 0;
    final durationMinutes = _toInt(pichanga['duration_minutes']) ?? 0;

    if (playersPerTeam > 0) {
      return '$startsAtLabel • ${playersPerTeam}vs$playersPerTeam • ${durationMinutes}min';
    }
    return '$startsAtLabel • ${durationMinutes}min';
  }

  Widget _buildTeamsCard(BuildContext context, List<Map<String, dynamic>> teams) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Confirmados',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (teams.isEmpty)
              const Text('Sin confirmados aún.')
            else
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: teams.map((team) {
                  final code = (team['code'] ?? '-').toString();
                  final avg = team['avg_rating'];
                  final slots = team['slots'] is List
                      ? (team['slots'] as List)
                            .whereType<Map>()
                            .map((item) => item.cast<String, dynamic>())
                            .toList()
                      : <Map<String, dynamic>>[];
                  final names = slots
                      .map((slot) {
                        final user = slot['user'] is Map
                            ? (slot['user'] as Map).cast<String, dynamic>()
                            : null;
                        if (user == null) {
                          return '';
                        }
                        final nick = (user['nick'] ?? '').toString().trim();
                        final name = (user['name'] ?? '').toString().trim();
                        return nick.isNotEmpty ? nick : name;
                      })
                      .where((name) => name.isNotEmpty)
                      .toList();

                  return SizedBox(
                    width: 160,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Equipo $code (*${avg ?? '-'})',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        if (names.isEmpty)
                          const Text('- Sin confirmados')
                        else
                          for (var i = 0; i < names.length; i++)
                            Text('${i + 1}. ${names[i]}'),
                      ],
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic>? _pickLineupTeam(List<Map<String, dynamic>> teams) {
    if (teams.isEmpty) {
      return null;
    }

    for (final team in teams) {
      final slots = team['slots'] is List
          ? (team['slots'] as List)
                .whereType<Map>()
                .map((item) => item.cast<String, dynamic>())
                .toList()
          : <Map<String, dynamic>>[];
      final containsMe = slots.any((slot) {
        final user = slot['user'] is Map
            ? (slot['user'] as Map).cast<String, dynamic>()
            : null;
        return user?['is_me'] == true;
      });
      if (containsMe) {
        return team;
      }
    }

    return teams.first;
  }

  Future<void> _shareLink(Map<String, dynamic> pichanga) async {
    if (_sharing) {
      return;
    }

    setState(() => _sharing = true);
    try {
      final text = WidgetConfirmedMapper.buildShareText(pichanga);
      await SharePlus.instance.share(
        ShareParams(
          text: text,
          subject: (pichanga['title'] ?? 'Pichanga').toString(),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _sharing = false);
      }
    }
  }

  Future<void> _shareLineup(
    Map<String, dynamic> pichanga,
    Map<String, dynamic> team,
  ) async {
    if (_sharing) {
      return;
    }

    setState(() => _sharing = true);
    try {
      await Future<void>.delayed(const Duration(milliseconds: 30));
      final boundary = _lineupBoundaryKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) {
        throw StateError('No se pudo renderizar la imagen de alineación.');
      }

      final image = await boundary.toImage(pixelRatio: 3);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw StateError('No se pudo generar PNG de alineación.');
      }

      final filePath = await _writeShareFile(
        byteData.buffer.asUint8List(),
        pichangaId: _toInt(pichanga['id']) ?? widget.pichangaId,
      );

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(filePath)],
          text:
              'Alineación propuesta para ${(pichanga['title'] ?? 'la pichanga').toString()}',
          subject: (pichanga['title'] ?? 'Pichanga').toString(),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _sharing = false);
      }
    }
  }

  Future<String> _writeShareFile(
    Uint8List bytes, {
    required int pichangaId,
  }) async {
    final tempDir = await getTemporaryDirectory();
    final file = File(
      '${tempDir.path}/fulbii_lineup_${pichangaId}_${DateTime.now().millisecondsSinceEpoch}.png',
    );
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  int? _toInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }
}

class _LineupShareCanvas extends StatelessWidget {
  const _LineupShareCanvas({
    required this.pichanga,
    required this.team,
  });

  final Map<String, dynamic> pichanga;
  final Map<String, dynamic>? team;

  static const _templatePath = 'assets/share/lineup_7v7_template.png';

  @override
  Widget build(BuildContext context) {
    final code = (team?['code'] ?? '-').toString();
    final avg = team?['avg_rating'];
    final slots = team?['slots'] is List
        ? (team!['slots'] as List)
              .whereType<Map>()
              .map((item) => item.cast<String, dynamic>())
              .toList()
        : <Map<String, dynamic>>[];

    final playersBySlot = <int, String>{};
    for (final slot in slots) {
      final slotNumber = slot['slot'] is int
          ? slot['slot'] as int
          : int.tryParse((slot['slot'] ?? '').toString()) ?? 0;
      if (slotNumber <= 0) {
        continue;
      }
      final user = slot['user'] is Map
          ? (slot['user'] as Map).cast<String, dynamic>()
          : null;
      if (user == null) {
        continue;
      }
      final nick = (user['nick'] ?? '').toString().trim();
      final name = (user['name'] ?? '').toString().trim();
      final display = nick.isNotEmpty ? nick : name;
      if (display.isEmpty) {
        continue;
      }
      playersBySlot[slotNumber] = display;
    }

    return Container(
      width: 320,
      height: 560,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            _templatePath,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF1E7A45), Color(0xFF0F4F2D)],
                  ),
                ),
              );
            },
          ),
          Container(color: Colors.black.withValues(alpha: 0.16)),
          Positioned(
            top: 14,
            left: 12,
            right: 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (pichanga['title'] ?? 'Pichanga').toString(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Equipo $code (*${avg ?? '-'})',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          ..._slotWidgets(playersBySlot),
        ],
      ),
    );
  }

  List<Widget> _slotWidgets(Map<int, String> playersBySlot) {
    const positions = <int, Alignment>{
      1: Alignment(0.00, 0.80),
      2: Alignment(-0.60, 0.43),
      3: Alignment(0.60, 0.43),
      4: Alignment(-0.42, 0.05),
      5: Alignment(0.42, 0.05),
      6: Alignment(-0.22, -0.37),
      7: Alignment(0.22, -0.37),
    };

    return positions.entries.map((entry) {
      final slot = entry.key;
      final name = playersBySlot[slot] ?? '—';
      return Align(
        alignment: entry.value,
        child: Container(
          width: 118,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.56),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.30)),
          ),
          child: Text(
            '$slot. $name',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      );
    }).toList();
  }
}
