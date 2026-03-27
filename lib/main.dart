import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/config/app_config.dart';
import 'core/config/firebase/firebase_config.dart';
import 'core/config/router/app_router.dart';
import 'core/database/isar_service.dart';
import 'core/services/sync_service.dart';

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

    return ScreenUtilInit(
      designSize: const Size(375, 812), // iPhone X design size
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (final context, final child) => MaterialApp.router(
          title: AppConfig.appName,
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            primarySwatch: Colors.blue,
            primaryColor: AppConfig.primaryColor,
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppConfig.primaryColor,
              brightness: Brightness.light,
            ),
            textTheme: GoogleFonts.interTextTheme(),
            useMaterial3: true,
            appBarTheme: AppBarTheme(
              backgroundColor: AppConfig.primaryColor,
              foregroundColor: Colors.white,
              elevation: 0,
              centerTitle: true,
              titleTextStyle: GoogleFonts.inter(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConfig.primaryColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: 12.h,
              ),
            ),
          ),
          routerConfig: router,
        ),
    );
  }
}
