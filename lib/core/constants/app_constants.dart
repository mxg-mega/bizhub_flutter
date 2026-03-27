class AppConstants {
  // API Endpoints
  static const String baseUrl = 'https://api.bizmodule.com';
  static const String authEndpoint = '/auth';
  static const String usersEndpoint = '/users';
  static const String modulesEndpoint = '/modules';
  static const String baseGoldUrl = 'https://api.metalpriceapi.com/v1/latest';
  
  // Storage Keys
  static const String userTokenKey = 'user_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userPreferencesKey = 'user_preferences';
  static const String appSettingsKey = 'app_settings';
  
  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);
  
  // Validation Rules
  static const int minPasswordLength = 6;
  static const int maxPasswordLength = 128;
  static const int maxNameLength = 100;
  static const int maxDescriptionLength = 500;
  
  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
  
  // Error Messages
  static const String networkErrorMessage = 'Network error. Please check your connection.';
  static const String serverErrorMessage = 'Server error. Please try again later.';
  static const String unknownErrorMessage = 'An unknown error occurred.';
  static const String invalidCredentialsMessage = 'Invalid email or password.';
  static const String emailAlreadyExistsMessage = 'Email already exists.';
  
  // Success Messages
  static const String loginSuccessMessage = 'Login successful!';
  static const String registrationSuccessMessage = 'Account created successfully!';
  static const String profileUpdateSuccessMessage = 'Profile updated successfully!';
  static const String moduleToggleSuccessMessage = 'Module updated successfully!';
  
  // Business Types
  static const List<String> businessTypes = [
    'Retail',
    'Restaurant',
    'Service',
    'Manufacturing',
    'Healthcare',
    'Education',
    'Technology',
    'Finance',
    'Real Estate',
    'Other',
  ];
  
  // Industries
  static const List<String> industries = [
    'Agriculture',
    'Automotive',
    'Beauty & Personal Care',
    'Clothing & Fashion',
    'Electronics',
    'Food & Beverage',
    'Health & Wellness',
    'Home & Garden',
    'Sports & Recreation',
    'Travel & Tourism',
  ];
}
