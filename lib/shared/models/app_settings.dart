import 'package:json_annotation/json_annotation.dart';

part 'app_settings.g.dart';

@JsonSerializable()
class AppSettings {
  final String themeMode; // 'light', 'dark', 'system'
  final String language;
  final bool notificationsEnabled;
  final bool analyticsEnabled;
  final bool crashlyticsEnabled;
  final Map<String, dynamic> customSettings;
  final DateTime lastUpdated;

  const AppSettings({
    required this.themeMode,
    required this.language,
    required this.notificationsEnabled,
    required this.analyticsEnabled,
    required this.crashlyticsEnabled,
    required this.customSettings,
    required this.lastUpdated,
  });

  factory AppSettings.fromJson(Map<String, dynamic> json) =>
      _$AppSettingsFromJson(json);
  Map<String, dynamic> toJson() => _$AppSettingsToJson(this);

  factory AppSettings.defaultSettings() {
    return AppSettings(
      themeMode: 'system',
      language: 'en',
      notificationsEnabled: true,
      analyticsEnabled: true,
      crashlyticsEnabled: true,
      customSettings: {},
      lastUpdated: DateTime.now(),
    );
  }

  AppSettings copyWith({
    String? themeMode,
    String? language,
    bool? notificationsEnabled,
    bool? analyticsEnabled,
    bool? crashlyticsEnabled,
    Map<String, dynamic>? customSettings,
    DateTime? lastUpdated,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      language: language ?? this.language,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      analyticsEnabled: analyticsEnabled ?? this.analyticsEnabled,
      crashlyticsEnabled: crashlyticsEnabled ?? this.crashlyticsEnabled,
      customSettings: customSettings ?? this.customSettings,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
