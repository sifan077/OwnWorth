import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Replaced in `main.dart` with the instance loaded before the first frame.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw StateError('SharedPreferences has not been initialized.');
});

class ThemeModeNotifier extends Notifier<ThemeMode> {
  static const String storageKey = 'theme_mode';

  @override
  ThemeMode build() {
    final stored = ref.read(sharedPreferencesProvider).getString(storageKey);
    return switch (stored) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Future<void> setMode(ThemeMode mode) async {
    if (state == mode) {
      return;
    }
    state = mode;
    await ref.read(sharedPreferencesProvider).setString(storageKey, mode.name);
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);
