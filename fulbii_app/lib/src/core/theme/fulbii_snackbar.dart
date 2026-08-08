import 'package:flutter/material.dart';

enum FulbiiSnackBarTone { success, error }

/// Semantic variants for the few feedback messages that must stand apart from
/// the global informational SnackBar theme.
SnackBar fulbiiSnackBar(String message, {required FulbiiSnackBarTone tone}) {
  final backgroundColor = switch (tone) {
    FulbiiSnackBarTone.success => const Color(0xFF1B5E2B),
    FulbiiSnackBarTone.error => const Color(0xFF71342E),
  };

  return SnackBar(
    backgroundColor: backgroundColor,
    content: Text(
      message,
      style: const TextStyle(
        color: Color(0xFFF5FFF5),
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}
