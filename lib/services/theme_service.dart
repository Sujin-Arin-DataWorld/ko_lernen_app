import 'package:flutter/material.dart';

import 'storage_service.dart';

/// Globaler Theme-Modus. Listener triggert MaterialApp rebuild.
final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier<ThemeMode>(_loadInitial());

ThemeMode _loadInitial() {
  switch (Storage.themeMode) {
    case 'light': return ThemeMode.light;
    case 'dark':  return ThemeMode.dark;
    default:      return ThemeMode.system;
  }
}

Future<void> setThemeMode(ThemeMode mode) async {
  final code = switch (mode) {
    ThemeMode.light  => 'light',
    ThemeMode.dark   => 'dark',
    ThemeMode.system => '',
  };
  await Storage.setThemeMode(code);
  themeModeNotifier.value = mode;
}
