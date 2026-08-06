import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Stores the visual preference on this device only.
final themeModeProvider = StateNotifierProvider<ThemeModeController, ThemeMode>(
  (ref) {
    return ThemeModeController();
  },
);

class ThemeModeController extends StateNotifier<ThemeMode> {
  ThemeModeController() : super(ThemeMode.light) {
    _restore();
  }

  static const _storageKey = 'fulbii.dark_theme';

  Future<void> _restore() async {
    final preferences = await SharedPreferences.getInstance();
    state = preferences.getBool(_storageKey) == true
        ? ThemeMode.dark
        : ThemeMode.light;
  }

  Future<void> setDarkMode(bool enabled) async {
    state = enabled ? ThemeMode.dark : ThemeMode.light;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_storageKey, enabled);
  }
}
