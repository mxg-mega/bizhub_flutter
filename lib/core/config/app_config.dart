import 'package:flutter/material.dart';

import '../../shared/models/module_model.dart';

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
  static const String businessDataKey = 'business_data';
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

  // available modules can be used to dynamically generate the dashboard and settings pages
  static const Map<String, String> moduleIcons = {
    'inventory': 'assets/icons/inventory.svg',
    'sales': 'assets/icons/sales.svg',
    'customers': 'assets/icons/customers.svg',
    'employees': 'assets/icons/employees.svg',
    'finance': 'assets/icons/finance.svg',
    'reports': 'assets/icons/reports.svg',
    'settings': 'assets/icons/settings.svg',
  };

  static const Map<String, String> moduleTitles = {
    'inventory': 'Inventory',
    'sales': 'Sales',
    'customers': 'Customers',
    'employees': 'Employees',
    'finance': 'Finance',
    'reports': 'Reports',
    'settings': 'Settings',
  };

  // This can be used to provide detailed descriptions for each module in the dashboard and settings pages
  // moduleDescriptions can be used to show tooltips or info dialogs in the dashboard and settings pages
  // moduleModels can be used to manage the state of each module (enabled/disabled, premium features, settings, etc.) and can be stored in a database or local storage
  // The moduleModels list can be used to generate the dashboard cards and settings toggles dynamically based on the available modules and their states
  // The moduleModels can also be used to manage dependencies between modules (e.g., if sales module requires inventory module to be enabled) and to handle premium features (e.g., if finance module has premium features that require a subscription)
  // The moduleModels can be updated based on user interactions in the dashboard and settings pages, and the changes can be persisted in a database or local storage for future sessions
  // The moduleModels can also be used to generate reports and analytics based on the enabled modules and their settings, providing insights into the business operations and performance

  // TODO: for now these are hardcoded, but in the future they should be fetched from an API or a database to allow for dynamic updates and customization based on user preferences and business needs
  static List<ModuleModel> moduleModels = [
    ModuleModel(
      id: 'dashboard',
      name: 'Dashboard',
      path: '/dashboard',
      icon: 'dashboard',
      description: 'An overview of all your activities',
      category: 'admin',
      isActive: true,
      isPremium: false,
      settings: const {},
      dependencies: const [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    ModuleModel(
      id: 'inventory',
      name: 'Inventory',
      path: '/inventory',
      icon: 'inventory_2',
      description: 'Manage your stock and supplies',
      category: 'inventory',
      isActive: false,
      isPremium: false,
      settings: const {},
      dependencies: const [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    ModuleModel(
      id: 'customers',
      name: 'Customers',
      path: '/customers',
      icon: 'people',
      description: 'Manage your customer relationships',
      category: 'sales',
      isActive: false,
      isPremium: false,
      settings: const {},
      dependencies: const [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  ];
  static const Map<String, String> moduleDescriptions = {
    'inventory': 'Manage your stock and supplies',
    'sales': 'Track your sales and revenue',
    'customers': 'Manage your customer relationships',
    'employees': 'Handle your staff and payroll',
    'finance': 'Oversee your financials and accounting',
    'reports': 'Generate insights and analytics',
    'settings': 'Configure your app preferences',
  };
}
