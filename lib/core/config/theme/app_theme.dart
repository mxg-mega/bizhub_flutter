import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_config.dart';

class AppPalette {
  final Color surface;
  final Color card;
  final Color raised;
  final Color outline;
  final Color textPrimary;
  final Color textSecondary;
  final Color primary;
  final Color onPrimary;
  final Color success;
  final Color error;
  final Color warning;
  final Color accent;
  final Color onAccent;
  final Color offline;
  final Color lowStock;

  const AppPalette({
    required this.surface,
    required this.card,
    required this.raised,
    required this.outline,
    required this.textPrimary,
    required this.textSecondary,
    required this.primary,
    required this.onPrimary,
    required this.success,
    required this.error,
    required this.warning,
    required this.accent,
    required this.onAccent,
    required this.offline,
    required this.lowStock,
  });
}

class AppTheme {
  static const lightPalette = AppPalette(
    surface: Color(0xFFFAFAF8),
    card: Color(0xFFFFFFFF),
    raised: Color(0xFFFFFFFF),
    outline: Color(0xFFE2E5E7),
    textPrimary: Color(0xFF1A1A2E),
    textSecondary: Color(0xFF5B6470),
    primary: Color(0xFF0D7377),
    onPrimary: Color(0xFFFFFFFF),
    success: Color(0xFF14663A),
    error: Color(0xFFC4392C),
    warning: Color(0xFFD9961F),
    accent: Color(0xFFF5A623),
    onAccent: Color(0xFF1A1A2E),
    offline: Color(0xFF8A4308),
    lowStock: Color(0xFFFFF1CC),
  );

  static const darkPalette = AppPalette(
    surface: Color(0xFF0E0D0C),
    card: Color(0xFF232335),
    raised: Color(0xFF303047),
    outline: Color(0xFF566078),
    textPrimary: Color(0xFFF2F2EE),
    textSecondary: Color(0xFFC2CBD3),
    primary: Color(0xFF0D7377),
    onPrimary: Color(0xFF5CCFD2),
    success: Color(0xFF5BD98B),
    error: Color(0xFFFF8A7A),
    warning: Color(0xFFD9961F),
    accent: Color(0xFFD9961F),
    onAccent: Color(0xFF1A1A2E),
    offline: Color(0xFFF0A060),
    lowStock: Color(0xFF3A2E1B),
  );

  static AppPalette paletteOf(final BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? darkPalette
      : lightPalette;

  static ThemeData get lightTheme => _build(Brightness.light, lightPalette);

  static ThemeData get darkTheme => _build(Brightness.dark, darkPalette);

  static ThemeData _build(final Brightness brightness, final AppPalette p) {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: AppConfig.primaryColor,
          brightness: brightness,
        ).copyWith(
          primary: p.primary,
          onPrimary: p.onPrimary,
          primaryContainer: p.raised,
          onPrimaryContainer: p.primary,
          secondary: p.primary,
          onSecondary: p.onPrimary,
          surface: p.surface,
          onSurface: p.textPrimary,
          surfaceTint: Colors.transparent,
          outline: p.outline,
          error: p.error,
          onError: p.onPrimary,
        );

    final textTheme = GoogleFonts.interTextTheme().copyWith(
      displayLarge: GoogleFonts.inter(
        fontSize: 28.sp,
        fontWeight: FontWeight.w700,
        color: p.textPrimary,
      ),
      headlineMedium: GoogleFonts.inter(
        fontSize: 20.sp,
        fontWeight: FontWeight.w700,
        color: p.textPrimary,
      ),
      titleLarge: GoogleFonts.inter(
        fontSize: 18.sp,
        fontWeight: FontWeight.w700,
        color: p.textPrimary,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 16.sp,
        fontWeight: FontWeight.w400,
        color: p.textPrimary,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14.sp,
        fontWeight: FontWeight.w400,
        color: p.textSecondary,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 14.sp,
        fontWeight: FontWeight.w600,
        color: p.textPrimary,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      primaryColor: p.primary,
      primarySwatch: Colors.teal,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: p.surface,
      canvasColor: p.surface,
      cardColor: p.card,
      dividerColor: p.outline,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: p.card,
        foregroundColor: p.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20.sp,
          fontWeight: FontWeight.w700,
          color: p.textPrimary,
        ),
        iconTheme: IconThemeData(color: p.textPrimary),
      ),
      cardTheme: CardThemeData(
        color: p.card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
          side: BorderSide(color: p.outline),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.card,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: p.card,
        modalElevation: 0,
        elevation: 0,
        showDragHandle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: p.card,
        surfaceTintColor: Colors.transparent,
        indicatorColor: p.primary.withValues(alpha: 0.14),
        iconTheme: WidgetStateProperty.resolveWith<IconThemeData?>(
          (final states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? p.primary
                : p.textSecondary,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle?>(
          (final states) => GoogleFonts.inter(
            fontSize: 12.sp,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.w400,
            color: states.contains(WidgetState.selected)
                ? p.primary
                : p.textSecondary,
          ),
        ),
        elevation: 0,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: p.card,
        selectedItemColor: p.primary,
        unselectedItemColor: p.textSecondary,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: p.primary,
          foregroundColor: p.onPrimary,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: p.primary,
          side: BorderSide(color: p.outline),
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: p.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: p.primary,
        foregroundColor: p.onPrimary,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: brightness == Brightness.dark ? p.raised : p.card,
        hintStyle: GoogleFonts.inter(color: p.textSecondary),
        labelStyle: GoogleFonts.inter(color: p.textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: p.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: p.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: AppConfig.primaryColor, width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: p.card,
        selectedColor: p.primary,
        disabledColor: p.raised,
        surfaceTintColor: Colors.transparent,
        side: BorderSide(color: p.outline),
        labelStyle: GoogleFonts.inter(fontSize: 12.sp, color: p.textPrimary),
        secondaryLabelStyle: GoogleFonts.inter(
          fontSize: 12.sp,
          color: p.onPrimary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
      ),
      dividerTheme: DividerThemeData(color: p.outline, thickness: 1),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: p.raised,
        contentTextStyle: GoogleFonts.inter(color: p.textPrimary),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: p.primary),
      iconTheme: IconThemeData(color: p.textPrimary),
    );
  }
}
