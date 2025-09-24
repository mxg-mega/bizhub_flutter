# Biz Module - Flutter Mobile App

A modular business management system that helps users manage their businesses by enabling or disabling features/systems they need to customize it for their business needs.

## 🚀 Features

- **Modular Design**: Enable/disable business modules as needed
- **Firebase Integration**: Authentication, Firestore, Storage, and Push Notifications
- **Modern UI**: Clean and responsive design with Material 3
- **State Management**: Riverpod for efficient state management
- **Navigation**: GoRouter for declarative routing
- **Responsive Design**: Flutter ScreenUtil for adaptive layouts

## 📱 Available Modules

- **Inventory Management**: Track stock levels and products
- **Sales Management**: Manage sales and transactions
- **Customer Management**: Store and manage customer information
- **Employee Management**: Handle employee data and roles
- **Finance Management**: Track financial transactions and reports
- **Reports & Analytics**: Generate business insights
- **Settings**: Configure app preferences

## 🏗️ Project Structure

```
lib/
├── core/
│   ├── config/
│   │   ├── app_config.dart          # App-wide configuration
│   │   ├── firebase/
│   │   │   └── firebase_config.dart # Firebase setup
│   │   └── router/
│   │       └── app_router.dart      # Navigation configuration
│   ├── constants/                   # App constants
│   ├── errors/                      # Error handling
│   ├── network/                     # Network utilities
│   └── utils/                       # Utility functions
├── features/
│   ├── auth/                        # Authentication feature
│   │   ├── data/                    # Data layer
│   │   ├── domain/                  # Business logic
│   │   └── presentation/            # UI layer
│   ├── onboarding/                  # Onboarding feature
│   ├── dashboard/                   # Dashboard feature
│   ├── modules/                     # Modules management
│   ├── profile/                     # User profile
│   └── settings/                    # App settings
└── shared/
    ├── models/                      # Shared data models
    ├── widgets/                     # Reusable widgets
    └── providers/                   # State management providers
```

## 🛠️ Tech Stack

- **Framework**: Flutter 3.8+
- **State Management**: Riverpod
- **Navigation**: GoRouter
- **Backend**: Firebase (Auth, Firestore, Storage, Messaging)
- **Local Storage**: SharedPreferences, Hive
- **HTTP Client**: Dio with Retrofit
- **UI**: Material 3, Google Fonts, Flutter ScreenUtil
- **Code Generation**: build_runner, json_serializable

## 📋 Prerequisites

- Flutter SDK 3.8.1 or higher
- Dart SDK 3.8.1 or higher
- Android Studio / VS Code
- Firebase project setup

## 🚀 Getting Started

### 1. Clone the repository
```bash
git clone <repository-url>
cd biz_module
```

### 2. Install dependencies
```bash
flutter pub get
```

### 3. Firebase Setup
1. Create a Firebase project at [Firebase Console](https://console.firebase.google.com/)
2. Add Android and iOS apps to your Firebase project
3. Download the configuration files:
   - `google-services.json` for Android
   - `GoogleService-Info.plist` for iOS
4. Place them in the respective platform directories
5. Update the Firebase configuration in `lib/core/config/firebase/firebase_config.dart`

### 4. Run the app
```bash
flutter run
```

## 🔧 Configuration

### App Configuration
Edit `lib/core/config/app_config.dart` to customize:
- App colors and theme
- API endpoints
- Feature flags
- Available modules

### Firebase Configuration
Update Firebase settings in `lib/core/config/firebase/firebase_config.dart`:
- API keys
- Project ID
- Storage bucket
- Messaging sender ID

## 📱 Screenshots

### Splash Screen
- Animated logo and app name
- Loading indicator
- Automatic navigation to onboarding/login

### Onboarding
- 4-step introduction to app features
- Swipeable pages with progress indicators
- Skip functionality

### Authentication
- Login with email/password
- Registration with validation
- Form validation and error handling

### Dashboard
- Overview of enabled modules
- Quick access to main features
- Responsive grid layout

### Modules Management
- Enable/disable business modules
- Real-time state updates
- Visual feedback for module status

### Profile & Settings
- User profile management
- App preferences
- Theme and language settings

## 🎨 Design System

### Colors
- **Primary**: #2563EB (Blue)
- **Secondary**: #3B82F6 (Light Blue)
- **Accent**: #10B981 (Green)
- **Error**: #EF4444 (Red)
- **Warning**: #F59E0B (Orange)

### Typography
- **Font Family**: Inter
- **Weights**: Regular (400), Medium (500), SemiBold (600), Bold (700)

### Spacing
- **Default Padding**: 16.0
- **Default Radius**: 12.0
- **Default Icon Size**: 24.0

## 🔄 State Management

The app uses Riverpod for state management with the following providers:

### Auth Provider
- User authentication state
- Login/logout functionality
- User data management

### Modules Provider
- Module enable/disable state
- Available modules list
- Module configuration

## 🧪 Testing

Run tests with:
```bash
flutter test
```

## 📦 Building

### Android
```bash
flutter build apk --release
```

### iOS
```bash
flutter build ios --release
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

For support and questions:
- Create an issue in the repository
- Contact the development team
- Check the documentation

## 🔮 Roadmap

- [ ] Dark mode support
- [ ] Offline functionality
- [ ] Push notifications
- [ ] Multi-language support
- [ ] Advanced analytics
- [ ] Export/import functionality
- [ ] API integration
- [ ] Unit and widget tests
- [ ] CI/CD pipeline

## 📝 Changelog

### Version 1.0.0
- Initial release
- Basic authentication
- Module management
- Dashboard and settings
- Firebase integration
