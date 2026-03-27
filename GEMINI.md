# Biz Module - Project Context

A modular business management system built with Flutter, designed to allow users to customize their business tools by enabling or disabling specific modules.

## 🚀 Project Overview

- **Framework**: Flutter (Dart 3.8.1+) with Material 3.
- **Architecture**: Feature-based modular structure following Clean Architecture principles (Presentation, Domain, Data layers).
- **State Management**: Riverpod (utilizing `riverpod_annotation` and code generation).
- **Navigation**: GoRouter for declarative routing.
- **Backend**: Firebase (Authentication, Firestore, Storage, Messaging).
- **Networking**: Dio with Retrofit for API interactions.
- **Local Storage**: Hive and SharedPreferences.
- **UI & UX**: Responsive design using `flutter_screenutil`, `google_fonts`, `flutter_svg`, and `lottie` animations.

## 🏗️ Project Structure

- `lib/core/`: Foundation of the app (configs, constants, network utilities, etc.).
- `lib/features/`: Independent business modules (auth, dashboard, inventory, etc.).
- `lib/shared/`: Reusable components (models, widgets, providers).
- `assets/`: Centralized assets (fonts, icons, images, svgs).

## 🛠️ Key Commands

### Development
- **Install Dependencies**: `flutter pub get`
- **Code Generation**: `flutter pub run build_runner build --delete-conflicting-outputs`
- **Watch Mode (Code Gen)**: `flutter pub run build_runner watch --delete-conflicting-outputs`
- **Format Code**: `dart format .`
- **Static Analysis**: `flutter analyze`

### Running & Testing
- **Run App**: `flutter run`
- **Run Tests**: `flutter test`
- **Build Android**: `flutter build apk --release`
- **Build iOS**: `flutter build ios --release`

## 📏 Development Conventions

### Coding Style
- **Immutability**: Prefer `final` for all variables and parameters. Use `const` constructors for widgets whenever possible.
- **Imports**: Always prefer **relative imports** within the `lib/` directory.
- **Naming**: Follow standard Dart conventions (`PascalCase` for classes, `camelCase` for variables/functions).
- **Parameters**: Use `final` for function parameters as enforced by the linter.

### Architecture Guidelines
- **Features**: Each feature should ideally contain `data`, `domain`, and `presentation` sub-directories.
- **Models**: Use `json_serializable` for all data models. Always include `factory Model.fromJson` and `Map<String, dynamic> toJson()` methods.
- **Providers**: Use Riverpod's code generation (`@riverpod`) for creating providers.
- **UI**: Use `ScreenUtil` for responsive dimensions (e.g., `16.w`, `24.h`, `14.sp`, `8.r`).

### Firebase
- Firebase is initialized in `main.dart` based on `AppConfig.enableFirebase`.
- Configuration is centralized in `lib/core/config/firebase/firebase_config.dart`.

## 📋 To-Do / Roadmap
- [ ] Complete Firebase Auth implementation.
- [ ] Implement Domain and Data layers for all features.
- [ ] Add unit and widget tests (current coverage is 0%).
- [ ] Implement Dark Mode support.
- [ ] Add offline-first capabilities with Hive.
