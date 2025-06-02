import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeState {
  final ThemeMode themeMode;

  const ThemeState({
    this.themeMode = ThemeMode.system,
  });

  ThemeState copyWith({
    ThemeMode? themeMode,
  }) {
    return ThemeState(
      themeMode: themeMode ?? this.themeMode,
    );
  }
}

class ThemeNotifier extends StateNotifier<ThemeState> {
  final SharedPreferences _prefs;
  static const _themeModeKey = 'theme_mode';

  ThemeNotifier(this._prefs) : super(const ThemeState()) {
    _loadSavedPreferences();
  }

  void _loadSavedPreferences() {
    final themeModeIndex = _prefs.getInt(_themeModeKey);
    state = ThemeState(
      themeMode: themeModeIndex != null ? ThemeMode.values[themeModeIndex] : ThemeMode.system,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await _prefs.setInt(_themeModeKey, mode.index);
    state = state.copyWith(themeMode: mode);
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeState>((ref) {
  throw UnimplementedError('Initialize with SharedPreferences instance');
});

// Provider for the base theme data without dynamic colors
final baseThemeDataProvider = Provider<ThemeData>((ref) {
  final themeState = ref.watch(themeProvider);
  final brightness = themeState.themeMode == ThemeMode.dark
      ? Brightness.dark
      : (themeState.themeMode == ThemeMode.light 
          ? Brightness.light 
          : WidgetsBinding.instance.platformDispatcher.platformBrightness);

  // Use deep purple as the fallback seed color
  final colorScheme = ColorScheme.fromSeed(
    seedColor: Colors.deepPurple,
    brightness: brightness,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    brightness: brightness,
  );
}); 