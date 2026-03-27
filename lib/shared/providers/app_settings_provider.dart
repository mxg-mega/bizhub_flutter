import 'dart:convert';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_settings.dart';

part 'app_settings_provider.g.dart';

@riverpod
class AppSettingsNotifier extends _$AppSettingsNotifier {
  static const String _key = 'app_settings';

  @override
  AppSettings build() {
    // Initial state is default, will be loaded from prefs
    _loadSettings();
    return AppSettings.defaultSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_key);
    if (jsonString != null) {
      try {
        state = AppSettings.fromJson(jsonDecode(jsonString));
      } catch (e) {
        state = AppSettings.defaultSettings();
      }
    }
  }

  Future<void> updateSettings(AppSettings settings) async {
    state = settings;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(settings.toJson()));
  }

  Future<void> toggleOfflineMode(bool enabled) async {
    final newSettings = state.copyWith(
      offlineModeEnabled: enabled,
      lastUpdated: DateTime.now(),
    );
    await updateSettings(newSettings);
  }
}
