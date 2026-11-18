import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'core/config/app_config.dart';
import 'core/config/firebase/firebase_config.dart';
import 'core/config/router/app_router.dart';
import 'core/config/theme/app_theme.dart';
import 'core/database/isar_service.dart';
import 'core/services/sync_service.dart';
import 'shared/providers/theme_provider.dart' as app_theme_mode;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: '.env');

  // Initialize Firebase
  if (AppConfig.enableFirebase) {
    await FirebaseConfig.initialize();
    FirebaseConfig.configureMessagingHandlers();
  }

  // Initialize Offline-First Layer
  final container = ProviderContainer();
  try {
    // 1. Open Isar Database
    await container.read(isarDatabaseProvider.future);
    // 2. Start Sync Engine & Connectivity Listener
    container.read(syncServiceProvider);
  } catch (e) {
    debugPrint('Offline-First Initialization Failed: $e');
  }

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const BizModuleApp(),
    ),
  );
}

class BizModuleApp extends ConsumerWidget {
  const BizModuleApp({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeState = ref.watch(app_theme_mode.themeProvider);

    return ScreenUtilInit(
      designSize: const Size(375, 812), // iPhone X design size
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (final context, final child) => MaterialApp.router(
          title: AppConfig.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: switch (themeState.themeMode) {
            app_theme_mode.ThemeMode.light => ThemeMode.light,
            app_theme_mode.ThemeMode.dark => ThemeMode.dark,
            app_theme_mode.ThemeMode.system => ThemeMode.system,
          },
          routerConfig: router,
        ),
    );
  }
}
