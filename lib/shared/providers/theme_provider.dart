import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/config/app_config.dart';
import '../../core/config/theme/app_theme.dart';

enum ThemeMode { light, dark, system }

class ThemeState {
  final ThemeMode themeMode;
  final bool isDarkMode;

  const ThemeState({
    this.themeMode = ThemeMode.system,
    this.isDarkMode = false,
  });

  ThemeState copyWith({
    final ThemeMode? themeMode,
    final bool? isDarkMode,
  }) {
    return ThemeState(
      themeMode: themeMode ?? this.themeMode,
      isDarkMode: isDarkMode ?? this.isDarkMode,
    );
  }
}

class ThemeNotifier extends StateNotifier<ThemeState> {
  ThemeNotifier() : super(const ThemeState()) {
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeModeIndex = prefs.getInt(AppConfig.themeModeKey) ?? 2; // Default to system
      final themeMode = ThemeMode.values[themeModeIndex];
      
      state = state.copyWith(themeMode: themeMode);
      _updateDarkMode(themeMode);
    } catch (e) {
      // Use default theme if loading fails
      state = state.copyWith(themeMode: ThemeMode.system);
    }
  }

  Future<void> setThemeMode(final ThemeMode themeMode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(AppConfig.themeModeKey, themeMode.index);
      
      state = state.copyWith(themeMode: themeMode);
      _updateDarkMode(themeMode);
    } catch (e) {
      // Handle error
    }
  }

  void _updateDarkMode(final ThemeMode themeMode) {
    bool isDark;
    
    switch (themeMode) {
      case ThemeMode.light:
        isDark = false;
        break;
      case ThemeMode.dark:
        isDark = true;
        break;
      case ThemeMode.system:
        isDark = WidgetsBinding.instance.platformDispatcher.platformBrightness ==
            Brightness.dark;
        break;
    }
    
    state = state.copyWith(isDarkMode: isDark);
  }

  ThemeData getLightTheme() => AppTheme.lightTheme;

  ThemeData getDarkTheme() => AppTheme.darkTheme;

}

// Providers
final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeState>((final ref) {
  return ThemeNotifier();
});

final themeModeProvider = Provider<ThemeMode>((final ref) {
  final themeState = ref.watch(themeProvider);
  return themeState.themeMode;
});

final isDarkModeProvider = Provider<bool>((final ref) {
  final themeState = ref.watch(themeProvider);
  return themeState.isDarkMode;
});
