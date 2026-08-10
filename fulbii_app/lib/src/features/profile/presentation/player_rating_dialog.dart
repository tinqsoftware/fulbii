import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class PlayerRatingCandidate {
  const PlayerRatingCandidate({required this.id, required this.name});

  final int id;
  final String name;
}

typedef PlayerRatingSubmit =
    Future<void> Function(
      int playerId,
      Map<String, double> values,
      String comment,
    );

Future<bool?> showPlayerRatingDialog(
  BuildContext context, {
  required List<PlayerRatingCandidate> candidates,
  required PlayerRatingSubmit onSubmit,
}) {
  return showDialog<bool>(
    context: context,
    builder: (_) =>
        _PlayerRatingDialog(candidates: candidates, onSubmit: onSubmit),
  );
}

class _PlayerRatingDialog extends StatefulWidget {
  const _PlayerRatingDialog({required this.candidates, required this.onSubmit});

  final List<PlayerRatingCandidate> candidates;
  final PlayerRatingSubmit onSubmit;

  @override
  State<_PlayerRatingDialog> createState() => _PlayerRatingDialogState();
}

class _PlayerRatingDialogState extends State<_PlayerRatingDialog> {
  static const _skills =
      <({String key, String label, IconData icon, Color color})>[
        (
          key: 'delantero',
          label: 'Delantero',
          icon: Icons.sports_soccer_rounded,
          color: Color(0xFF78C86E),
        ),
        (
          key: 'mediocampo',
          label: 'Mediocampo',
          icon: Icons.hub_rounded,
          color: Color(0xFF78C86E),
        ),
        (
          key: 'defensa',
          label: 'Defensa',
          icon: Icons.shield_rounded,
          color: Color(0xFF78C86E),
        ),
        (
          key: 'arquero',
          label: 'Arquero',
          icon: Icons.sports_handball_rounded,
          color: Color(0xFF58B9D8),
        ),
        (
          key: 'fisico',
          label: 'Físico',
          icon: Icons.directions_run_rounded,
          color: Color(0xFFF0AE52),
        ),
      ];

  final _commentController = TextEditingController();
  final _values = <String, double>{
    'fisico': 3,
    'arquero': 3,
    'delantero': 3,
    'mediocampo': 3,
    'defensa': 3,
  };
  late int _selectedPlayerId;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _selectedPlayerId = widget.candidates.first.id;
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  double get _fieldAverage =>
      ((_values['delantero'] ?? 0) +
          (_values['mediocampo'] ?? 0) +
          (_values['defensa'] ?? 0)) /
      3;
  double get _playerAverage => (_fieldAverage + (_values['fisico'] ?? 0)) / 2;
  double get _goalkeeperAverage =>
      ((_values['arquero'] ?? 0) + (_values['fisico'] ?? 0)) / 2;
  bool get _isGoalkeeper => _goalkeeperAverage > _playerAverage;
  double get _primaryAverage =>
      _isGoalkeeper ? _goalkeeperAverage : _playerAverage;

  String get _suggestedPosition {
    if (_isGoalkeeper) return 'Arquero';
    final positions = <String, double>{
      'Delantero': _values['delantero'] ?? 0,
      'Mediocampo': _values['mediocampo'] ?? 0,
      'Defensa': _values['defensa'] ?? 0,
    };
    final best = positions.values.reduce(
      (left, right) => left > right ? left : right,
    );
    return positions.entries.firstWhere((entry) => entry.value == best).key;
  }

  Future<void> _save() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      await widget.onSubmit(
        _selectedPlayerId,
        _values,
        _commentController.text.trim(),
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo guardar la calificación: $error')),
        );
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      title: const Text('Calificar jugador'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.candidates.length > 1)
              DropdownButtonFormField<int>(
                initialValue: _selectedPlayerId,
                decoration: const InputDecoration(
                  labelText: 'Jugador confirmado',
                ),
                items: widget.candidates
                    .map(
                      (candidate) => DropdownMenuItem(
                        value: candidate.id,
                        child: Text(candidate.name),
                      ),
                    )
                    .toList(),
                onChanged: _submitting
                    ? null
                    : (value) => setState(
                        () => _selectedPlayerId = value ?? _selectedPlayerId,
                      ),
              )
            else
              Text(
                widget.candidates.first.name,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
            const SizedBox(height: 12),
            _RatingSummary(
              playerAverage: _playerAverage,
              goalkeeperAverage: _goalkeeperAverage,
              primaryAverage: _primaryAverage,
              suggestedPosition: _suggestedPosition,
              isGoalkeeper: _isGoalkeeper,
            ),
            const SizedBox(height: 10),
            Text(
              'Físico potencia tanto el perfil de campo como el de arquero. Tu puntaje principal toma el mejor de ambos.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
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
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: _submitting ? null : _save,
          icon: _submitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.check_rounded),
          label: Text(_submitting ? 'Guardando' : 'Guardar'),
        ),
      ],
    );
  }

  Widget _buildSkillControl(
    ({String key, String label, IconData icon, Color color}) skill,
  ) {
    final value = _values[skill.key] ?? 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          Row(
            children: [
              Icon(skill.icon, size: 20, color: skill.color),
              const SizedBox(width: 8),
              Expanded(child: Text(skill.label)),
              Container(
                constraints: const BoxConstraints(minWidth: 44),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: skill.color.withValues(alpha: .17),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  value.toStringAsFixed(1),
                  style: TextStyle(
                    color: skill.color,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: skill.color,
              inactiveTrackColor: skill.color.withValues(alpha: .22),
              thumbShape: _IconThumbShape(icon: skill.icon, color: skill.color),
              overlayColor: skill.color.withValues(alpha: .16),
            ),
            child: Slider(
              value: value,
              min: 0,
              max: 5,
              divisions: 50,
              label: value.toStringAsFixed(1),
              semanticFormatterCallback: (score) =>
                  '${skill.label}: ${score.toStringAsFixed(1)} de 5',
              onChanged: _submitting
                  ? null
                  : (score) => setState(
                      () => _values[skill.key] = double.parse(
                        score.toStringAsFixed(1),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RatingSummary extends StatelessWidget {
  const _RatingSummary({
    required this.playerAverage,
    required this.goalkeeperAverage,
    required this.primaryAverage,
    required this.suggestedPosition,
    required this.isGoalkeeper,
  });

  final double playerAverage;
  final double goalkeeperAverage;
  final double primaryAverage;
  final String suggestedPosition;
  final bool isGoalkeeper;

  @override
  Widget build(BuildContext context) {
    final color = isGoalkeeper
        ? const Color(0xFF58B9D8)
        : Theme.of(context).colorScheme.primary;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isGoalkeeper
                    ? Icons.sports_handball_rounded
                    : Icons.sports_soccer_rounded,
                color: color,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Posición sugerida: $suggestedPosition',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              Text(
                '${primaryAverage.toStringAsFixed(1)} / 5',
                style: TextStyle(color: color, fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            'Campo ${playerAverage.toStringAsFixed(1)} · Arquero ${goalkeeperAverage.toStringAsFixed(1)}',
          ),
        ],
      ),
    );
  }
}

class _IconThumbShape extends SliderComponentShape {
  const _IconThumbShape({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) => const Size(32, 32);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final canvas = context.canvas;
    canvas.drawCircle(center, 15, Paint()..color = color);
    final painter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: 17,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          color: Colors.white,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      center - Offset(painter.width / 2, painter.height / 2),
    );
  }
}
