import 'package:flutter/material.dart';

class AppConfig {
  static const String appName = 'Biz Module';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'Modular Business Management System';

  // API Configuration
  static const String baseUrl =
      'https://api.bizmodule.com'; // Replace with your actual API URL
  static const int apiTimeout = 30000; // 30 seconds

  // Firebase Configuration
  static const bool enableFirebase = true;

  // App Theme Configuration
  static const Color primaryColor = Color(0xFF2563EB);
  static const Color secondaryColor = Color(0xFF3B82F6);
  static const Color accentColor = Color(0xFF10B981);
  static const Color errorColor = Color(0xFFEF4444);
  static const Color warningColor = Color(0xFFF59E0B);
  static const Color successColor = Color(0xFF10B981);

  // App Dimensions
  static const double defaultPadding = 16.0;
  static const double defaultRadius = 12.0;
  static const double defaultIconSize = 24.0;

  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);

  // Storage Keys
  static const String authTokenKey = 'auth_token';
  static const String userDataKey = 'user_data';
  static const String onboardingCompletedKey = 'onboarding_completed';
  static const String themeModeKey = 'theme_mode';
  static const String languageKey = 'language';

  // Feature Flags
  static const bool enableAnalytics = true;
  static const bool enableCrashlytics = true;
  static const bool enablePushNotifications = true;

  // Business Module Features
  static const List<String> availableModules = [
    'inventory',
    'sales',
    'customers',
    'employees',
    'finance',
    'reports',
    'settings',
  ];
}
