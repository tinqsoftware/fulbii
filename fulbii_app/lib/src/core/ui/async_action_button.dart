import 'package:flutter/material.dart';

class AsyncActionButton extends StatefulWidget {
  const AsyncActionButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.icon,
    this.style,
  });

  final Future<void> Function() onPressed;
  final String label;
  final IconData? icon;
  final ButtonStyle? style;

  @override
  State<AsyncActionButton> createState() => _AsyncActionButtonState();
}

class _AsyncActionButtonState extends State<AsyncActionButton> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: _loading
          ? null
          : () async {
              setState(() => _loading = true);
              try {
                await widget.onPressed();
              } finally {
                if (mounted) {
                  setState(() => _loading = false);
                }
              }
            },
      style: widget.style,
      icon: _loading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(widget.icon ?? Icons.check),
      label: Text(widget.label),
    );
  }
}
