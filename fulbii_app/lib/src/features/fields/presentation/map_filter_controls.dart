import 'package:flutter/material.dart';

/// Compact, accessible controls shared by the map filter sheet.
class PichangaRangeSelector extends StatelessWidget {
  const PichangaRangeSelector({
    required this.selectedValue,
    required this.customLabel,
    required this.onSelected,
    super.key,
  });

  final String selectedValue;
  final String customLabel;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    const ranges = <String>['today', 'today_tomorrow', 'custom'];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: SizedBox(
        height: 48,
        child: Row(
          children: ranges
              .map(
                (value) => Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: value == 'custom' ? 0 : 6),
                    child: _RangeChoice(
                      value: value,
                      label: switch (value) {
                        'today' => 'Hoy',
                        'today_tomorrow' => 'Hoy y\nmañana',
                        _ => customLabel,
                      },
                      selected: selectedValue == value,
                      onTap: () => onSelected(value),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class CompactFilterChoice extends StatelessWidget {
  const CompactFilterChoice({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.fontSize = 12,
    this.maxLines = 1,
    this.controlKey,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  final double fontSize;
  final int maxLines;
  final Key? controlKey;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final foreground = selected ? Colors.white : colorScheme.onSurface;
    return Semantics(
      button: true,
      selected: selected,
      label: label.replaceAll('\n', ' '),
      child: Material(
        color: selected ? const Color(0xFF1B8F24) : colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          key: controlKey,
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            height: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected
                    ? const Color(0xFF38D430)
                    : colorScheme.outlineVariant,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: icon == null
                ? Center(
                    child: _ChoiceLabel(label, foreground, fontSize, maxLines),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, size: 18, color: foreground),
                      const SizedBox(height: 2),
                      _ChoiceLabel(label, foreground, fontSize, maxLines),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _RangeChoice extends StatelessWidget {
  const _RangeChoice({
    required this.value,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String value;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => CompactFilterChoice(
    label: label,
    selected: selected,
    onTap: onTap,
    maxLines: 2,
    fontSize: 11.5,
    controlKey: Key('map-filter-range-$value'),
  );
}

class _ChoiceLabel extends StatelessWidget {
  const _ChoiceLabel(this.label, this.color, this.fontSize, this.maxLines);

  final String label;
  final Color color;
  final double fontSize;
  final int maxLines;

  @override
  Widget build(BuildContext context) => Text(
    label,
    maxLines: maxLines,
    overflow: TextOverflow.ellipsis,
    textAlign: TextAlign.center,
    style: TextStyle(
      color: color,
      fontWeight: FontWeight.w700,
      fontSize: fontSize,
      height: 1.05,
    ),
  );
}
