import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/config/router/app_router.dart';
import '../../../../core/config/theme/app_theme.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/sync_service.dart';
import '../../../../shared/providers/app_settings_provider.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../../shared/providers/modules_provider.dart';
import '../../../../shared/providers/theme_provider.dart' as app_theme_mode;

typedef MenuPage = SettingsPage;

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  @override
  Widget build(final BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final business = authState.activeBusiness;
    final enabledModules = ref.watch(modulesNotifierProvider);
    final isDarkMode = ref.watch(app_theme_mode.isDarkModeProvider);
    final appSettings = ref.watch(appSettingsNotifierProvider);
    final palette = AppTheme.paletteOf(context);

    final businessName = business?.name?.trim().isNotEmpty == true
        ? business!.name!.trim()
        : 'Bello Provisions';
    final businessInitial = businessName.isNotEmpty
        ? businessName[0].toUpperCase()
        : 'B';

    final userName = user?.name?.trim().isNotEmpty == true
        ? user!.name!.trim()
        : 'Alhaji Bello';
    final userInitial = userName.isNotEmpty ? userName[0].toUpperCase() : 'A';

    final userContact = business?.phone?.trim().isNotEmpty == true
        ? business!.phone!.trim()
        : (user?.email?.trim().isNotEmpty == true
            ? user!.email!.trim()
            : '+234 803 123 4567');

    final isOffline = appSettings.offlineModeEnabled;

    return Scaffold(
      backgroundColor: palette.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Top Bar: Business avatar, business dropdown, sync badge, bell icon
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
                child: Row(
                  children: [
                    // Business Avatar Circle
                    Container(
                      width: 44.r,
                      height: 44.r,
                      decoration: const BoxDecoration(
                        color: Color(0xFF0D7377),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        businessInitial,
                        style: GoogleFonts.inter(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    SizedBox(width: 10.w),

                    // Business Name Selector Dropdown
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _showBusinessSwitcher(context),
                        behavior: HitTestBehavior.opaque,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                businessName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.w700,
                                  color: palette.textPrimary,
                                ),
                              ),
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              '▾',
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                                color: palette.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),

                    // Sync Status Badge
                    GestureDetector(
                      onTap: () {
                        ref.read(syncServiceProvider).pushPendingChanges();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isOffline
                                  ? 'Offline mode is currently active'
                                  : 'Syncing with cloud...',
                              style: GoogleFonts.inter(),
                            ),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 7.h,
                        ),
                        decoration: BoxDecoration(
                          color: isOffline
                              ? (isDarkMode
                                  ? const Color(0xFF2E1E14)
                                  : const Color(0xFFFFEED9))
                              : (isDarkMode
                                  ? const Color(0xFF14281E)
                                  : const Color(0xFFE3F5EA)),
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        child: Text(
                          isOffline ? 'Offline' : 'Synced',
                          style: GoogleFonts.inter(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                            color: isOffline
                                ? (isDarkMode
                                    ? const Color(0xFFF0A060)
                                    : const Color(0xFF8A4308))
                                : (isDarkMode
                                    ? const Color(0xFF5BD98B)
                                    : const Color(0xFF14663A)),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 10.w),

                    // Notification Bell Icon
                    GestureDetector(
                      onTap: () => _showNotificationsDialog(context),
                      behavior: HitTestBehavior.opaque,
                      child: SizedBox(
                        width: 28.r,
                        height: 28.r,
                        child: Icon(
                          Icons.notifications,
                          size: 28.r,
                          color: palette.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 2. Title: "More"
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 8.h),
                child: Text(
                  'More',
                  style: GoogleFonts.inter(
                    fontSize: 26.sp,
                    fontWeight: FontWeight.w800,
                    color: palette.textPrimary,
                  ),
                ),
              ),

              // 3. User Profile Card
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                child: InkWell(
                  onTap: () => context.push(AppRouter.profile),
                  borderRadius: BorderRadius.circular(16.r),
                  child: Container(
                    padding: EdgeInsets.all(14.w),
                    decoration: BoxDecoration(
                      color: palette.card,
                      borderRadius: BorderRadius.circular(16.r),
                      border: isDarkMode
                          ? Border.all(
                              color: const Color(0xFF4A5268),
                              width: 1,
                            )
                          : null,
                      boxShadow: isDarkMode
                          ? null
                          : [
                              BoxShadow(
                                color: const Color(0xFF1A1A2E).withValues(alpha: 0.14),
                                offset: const Offset(0, 1),
                                blurRadius: 3,
                              ),
                            ],
                    ),
                    child: Row(
                      children: [
                        // User Avatar
                        Container(
                          width: 52.r,
                          height: 52.r,
                          decoration: const BoxDecoration(
                            color: Color(0xFF0D7377),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            userInitial,
                            style: GoogleFonts.inter(
                              fontSize: 20.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        SizedBox(width: 12.w),

                        // User Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                userName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 17.sp,
                                  fontWeight: FontWeight.w700,
                                  color: palette.textPrimary,
                                ),
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                userContact,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 14.sp,
                                  color: palette.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // 4. "My modules" Section
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
                child: Text(
                  'My modules',
                  style: GoogleFonts.inter(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                    color: palette.textPrimary,
                  ),
                ),
              ),

              // Modules Card Container
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: palette.card,
                    borderRadius: BorderRadius.circular(16.r),
                    border: isDarkMode
                        ? Border.all(
                            color: const Color(0xFF4A5268),
                            width: 1,
                          )
                        : null,
                    boxShadow: isDarkMode
                        ? null
                        : [
                            BoxShadow(
                              color: const Color(0xFF1A1A2E).withValues(alpha: 0.14),
                              offset: const Offset(0, 1),
                              blurRadius: 3,
                            ),
                          ],
                  ),
                  child: Column(
                    children: [
                      // 1. Inventory
                      _ModuleToggleRow(
                        title: 'Inventory',
                        subtitle: 'Track products and stock',
                        value: enabledModules.contains('inventory'),
                        onChanged: (final _) {
                          ref
                              .read(modulesNotifierProvider.notifier)
                              .toggleModule('inventory');
                        },
                      ),
                      _buildDivider(palette),

                      // 2. Point of Sale
                      _ModuleToggleRow(
                        title: 'Point of Sale',
                        subtitle: 'Sell and record payments',
                        value: enabledModules.contains('pos'),
                        onChanged: (final _) {
                          ref
                              .read(modulesNotifierProvider.notifier)
                              .toggleModule('pos');
                        },
                      ),
                      _buildDivider(palette),

                      // 3. Expense Tracker
                      _ModuleToggleRow(
                        title: 'Expense Tracker',
                        subtitle: 'Track business expenses',
                        value: enabledModules.contains('expenses'),
                        onChanged: (final _) {
                          ref
                              .read(modulesNotifierProvider.notifier)
                              .toggleModule('expenses');
                        },
                      ),
                      _buildDivider(palette),

                      // 4. Zakat Calculator
                      _ModuleToggleRow(
                        title: 'Zakat Calculator',
                        subtitle: 'Calculate and track zakat',
                        value: enabledModules.contains('zakat_tracker'),
                        onChanged: (final _) {
                          ref
                              .read(modulesNotifierProvider.notifier)
                              .toggleModule('zakat_tracker');
                        },
                      ),
                      _buildDivider(palette),

                      // 5. Customer Manager
                      _ModuleToggleRow(
                        title: 'Customer Manager',
                        subtitle: 'Track customers and credit',
                        value: enabledModules.contains('customers'),
                        onChanged: (final _) {
                          ref
                              .read(modulesNotifierProvider.notifier)
                              .toggleModule('customers');
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // 5. "Settings" Section
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
                child: Text(
                  'Settings',
                  style: GoogleFonts.inter(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                    color: palette.textPrimary,
                  ),
                ),
              ),

              // Settings Card Container
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  decoration: BoxDecoration(
                    color: palette.card,
                    borderRadius: BorderRadius.circular(16.r),
                    border: isDarkMode
                        ? Border.all(
                            color: const Color(0xFF4A5268),
                            width: 1,
                          )
                        : null,
                    boxShadow: isDarkMode
                        ? null
                        : [
                            BoxShadow(
                              color: const Color(0xFF1A1A2E).withValues(alpha: 0.14),
                              offset: const Offset(0, 1),
                              blurRadius: 3,
                            ),
                          ],
                  ),
                  child: Column(
                    children: [
                      // 1. Business details
                      _SettingsNavRow(
                        title: 'Business details',
                        onTap: () => context.push(AppRouter.businessProfile),
                      ),
                      _buildDivider(palette),

                      // 2. Receipt settings
                      _SettingsNavRow(
                        title: 'Receipt settings',
                        onTap: () => context.push(AppRouter.receiptDesigner),
                      ),
                      _buildDivider(palette),

                      // 3. Transfers
                      _SettingsNavRow(
                        title: 'Transfers',
                        onTap: () => context.push(AppRouter.transfers),
                      ),
                      _buildDivider(palette),

                      // 4. Notifications
                      _SettingsNavRow(
                        title: 'Notifications',
                        onTap: () => _showNotificationsDialog(context),
                      ),
                      _buildDivider(palette),

                      // 5. Language
                      _SettingsNavRow(
                        title: 'Language',
                        onTap: () => _showLanguageModal(context),
                      ),
                      _buildDivider(palette),

                      // 6. Dark mode
                      _DarkModeToggleRow(
                        isDarkMode: isDarkMode,
                        onChanged: (final value) {
                          final newMode = value
                              ? app_theme_mode.ThemeMode.dark
                              : app_theme_mode.ThemeMode.light;
                          ref
                              .read(app_theme_mode.themeProvider.notifier)
                              .setThemeMode(newMode);
                          final currentSettings =
                              ref.read(appSettingsNotifierProvider);
                          ref
                              .read(appSettingsNotifierProvider.notifier)
                              .updateSettings(
                                currentSettings.copyWith(
                                  themeMode: value ? 'dark' : 'light',
                                ),
                              );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // 7. Sign Out Button
              Padding(
                padding: EdgeInsets.all(16.w),
                child: SizedBox(
                  width: double.infinity,
                  height: 56.h,
                  child: OutlinedButton(
                    onPressed: () => _showSignOutDialog(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDarkMode
                          ? const Color(0xFFFF8A7A)
                          : const Color(0xFF9A2B1F),
                      side: BorderSide(
                        color: isDarkMode
                            ? const Color(0xFFFF8A7A)
                            : const Color(0xFF9A2B1F),
                        width: 2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      backgroundColor: Colors.transparent,
                    ),
                    child: Text(
                      'Sign out',
                      style: GoogleFonts.inter(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w700,
                        color: isDarkMode
                            ? const Color(0xFFFF8A7A)
                            : const Color(0xFF9A2B1F),
                      ),
                    ),
                  ),
                ),
              ),

              SizedBox(height: 24.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider(final AppPalette palette) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Divider(
      height: 1,
      thickness: 1,
      color: isDark
          ? const Color(0xFF303047)
          : const Color(0xFFF2F2EE),
    );
  }

  void _showBusinessSwitcher(final BuildContext context) {
    final authState = ref.read(authProvider);
    final user = authState.user;
    final activeBusiness = authState.activeBusiness;
    final palette = AppTheme.paletteOf(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: palette.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (final sheetContext) {
        final businessIds = user?.businessIds ?? [];
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 16.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: palette.outline,
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
                Text(
                  'Switch Business',
                  style: GoogleFonts.inter(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                    color: palette.textPrimary,
                  ),
                ),
                SizedBox(height: 12.h),
                if (businessIds.isEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    child: Text(
                      activeBusiness?.name ?? 'No other business available',
                      style: GoogleFonts.inter(color: palette.textSecondary),
                    ),
                  )
                else
                  ...businessIds.map((final id) {
                    final isCurrent = id == activeBusiness?.id;
                    return FutureBuilder<String?>(
                      future: AuthService.getBusinessNameFromFirestore(id),
                      builder: (final _, final snapshot) {
                        final name = snapshot.data ?? (isCurrent ? activeBusiness?.name ?? id : id);
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFF0D7377),
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : 'B',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text(
                            name,
                            style: GoogleFonts.inter(
                              fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                              color: palette.textPrimary,
                            ),
                          ),
                          trailing: isCurrent
                              ? const Icon(Icons.check_circle, color: Color(0xFF0D7377))
                              : null,
                          onTap: () {
                            Navigator.pop(sheetContext);
                            if (!isCurrent) {
                              ref.read(authProvider.notifier).switchBusiness(id);
                            }
                          },
                        );
                      },
                    );
                  }),
                SizedBox(height: 8.h),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showNotificationsDialog(final BuildContext context) {
    final settings = ref.read(appSettingsNotifierProvider);
    final palette = AppTheme.paletteOf(context);

    showDialog(
      context: context,
      builder: (final dialogContext) {
        var enabled = settings.notificationsEnabled;
        return StatefulBuilder(
          builder: (final _, final setDialogState) {
            return AlertDialog(
              backgroundColor: palette.card,
              title: Text(
                'Notifications',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  color: palette.textPrimary,
                ),
              ),
              content: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Push notifications for business alerts',
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        color: palette.textPrimary,
                      ),
                    ),
                  ),
                  BizSwitch(
                    value: enabled,
                    onChanged: (final val) {
                      setDialogState(() => enabled = val);
                      ref
                          .read(appSettingsNotifierProvider.notifier)
                          .updateSettings(
                            settings.copyWith(notificationsEnabled: val),
                          );
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(
                    'Done',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0D7377),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showLanguageModal(final BuildContext context) {
    final settings = ref.read(appSettingsNotifierProvider);
    final palette = AppTheme.paletteOf(context);
    final languages = [
      {'code': 'en', 'name': 'English'},
      {'code': 'ha', 'name': 'Hausa'},
      {'code': 'yo', 'name': 'Yoruba'},
      {'code': 'ig', 'name': 'Igbo'},
      {'code': 'fr', 'name': 'Français'},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: palette.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (final sheetContext) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 16.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: palette.outline,
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
                Text(
                  'Select Language',
                  style: GoogleFonts.inter(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                    color: palette.textPrimary,
                  ),
                ),
                SizedBox(height: 12.h),
                ...languages.map((final lang) {
                  final isSelected = settings.language == lang['code'];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      lang['name']!,
                      style: GoogleFonts.inter(
                        fontSize: 16.sp,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: palette.textPrimary,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check, color: Color(0xFF0D7377))
                        : null,
                    onTap: () {
                      ref
                          .read(appSettingsNotifierProvider.notifier)
                          .updateSettings(
                            settings.copyWith(language: lang['code']!),
                          );
                      Navigator.pop(sheetContext);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSignOutDialog(final BuildContext context) {
    final palette = AppTheme.paletteOf(context);

    showDialog(
      context: context,
      builder: (final dialogContext) {
        return AlertDialog(
          backgroundColor: palette.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          title: Text(
            'Sign Out',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              color: palette.textPrimary,
            ),
          ),
          content: Text(
            'Are you sure you want to sign out of your account?',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              color: palette.textSecondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: palette.textSecondary,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                ref.read(authProvider.notifier).signOut();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9A2B1F),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              child: Text(
                'Sign Out',
                style: GoogleFonts.inter(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Exact 56x32 toggle switch matching HTML mockup
class BizSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const BizSwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(final BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const activeColor = Color(0xFF0D7377);
    final inactiveColor = isDark
        ? const Color(0xFF566078)
        : const Color(0xFF8A96A3);

    return GestureDetector(
      onTap: () => onChanged(!value),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        width: 56.w,
        height: 32.h,
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.h),
        decoration: BoxDecoration(
          color: value ? activeColor : inactiveColor,
          borderRadius: BorderRadius.circular(16.r),
        ),
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: 24.w,
          height: 24.h,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Color.fromRGBO(0, 0, 0, 0.2),
                offset: Offset(0, 1),
                blurRadius: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModuleToggleRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ModuleToggleRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(final BuildContext context) {
    final palette = AppTheme.paletteOf(context);

    return SizedBox(
      height: 64.h,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: palette.textPrimary,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    color: palette.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          BizSwitch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _SettingsNavRow extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const _SettingsNavRow({
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(final BuildContext context) {
    final palette = AppTheme.paletteOf(context);

    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 56.h,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: palette.textPrimary,
              ),
            ),
            Text(
              '›',
              style: TextStyle(
                fontSize: 22.sp,
                fontWeight: FontWeight.w400,
                color: palette.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DarkModeToggleRow extends StatelessWidget {
  final bool isDarkMode;
  final ValueChanged<bool> onChanged;

  const _DarkModeToggleRow({
    required this.isDarkMode,
    required this.onChanged,
  });

  @override
  Widget build(final BuildContext context) {
    final palette = AppTheme.paletteOf(context);

    return SizedBox(
      height: 64.h,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dark mode',
                  style: GoogleFonts.inter(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: palette.textPrimary,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  'Easier on the eyes at night',
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    color: palette.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          BizSwitch(
            value: isDarkMode,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
