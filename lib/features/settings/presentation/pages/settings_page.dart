import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/config/app_config.dart';
import '../../../../shared/presentation/widgets/common_app_bar.dart';
import '../../../../shared/providers/app_settings_provider.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../../core/auth/role_permissions.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appSettingsNotifierProvider);
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final business = authState.activeBusiness;

    return Scaffold(
      appBar: const CommonAppBar(),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Settings',
              style: GoogleFonts.inter(fontSize: 24.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 24.h),
            
            // App Settings Section (Device local)
            _SettingsSection(
              title: 'App Settings',
              children: [
                _SettingsSwitch(
                  icon: Icons.notifications,
                  title: 'Push Notifications',
                  subtitle: 'Receive notifications about your business',
                  value: settings.notificationsEnabled,
                  onChanged: (value) {
                    ref.read(appSettingsNotifierProvider.notifier).updateSettings(
                      settings.copyWith(notificationsEnabled: value),
                    );
                  },
                ),
                _SettingsSwitch(
                  icon: Icons.cloud_off,
                  title: 'Force Offline Mode',
                  subtitle: 'Pause cloud synchronization',
                  value: settings.offlineModeEnabled,
                  onChanged: (value) {
                    ref.read(appSettingsNotifierProvider.notifier).toggleOfflineMode(value);
                  },
                ),
                _SettingsSwitch(
                  icon: Icons.dark_mode,
                  title: 'Dark Mode',
                  subtitle: 'Use dark theme',
                  value: settings.themeMode == 'dark',
                  onChanged: (value) {
                    ref.read(appSettingsNotifierProvider.notifier).updateSettings(
                      settings.copyWith(themeMode: value ? 'dark' : 'light'),
                    );
                  },
                ),
              ],
            ),

            SizedBox(height: 24.h),

            // Business Rules Section (Manager/Owner only, synced to Cloud)
            if (user?.hasPermission(AppPermission.editSettings) ?? false) ...[
              _SettingsSection(
                title: 'Business Rules',
                children: [
                  _SettingsSwitch(
                    icon: Icons.assignment_turned_in,
                    title: 'Require Sales Approval',
                    subtitle: 'Managers must approve sales before stock deduction',
                    value: business?.settings?['requireApproval'] ?? false,
                    onChanged: (value) {
                      ref.read(authProvider.notifier).updateBusinessSettings({'requireApproval': value});
                    },
                  ),
                ],
              ),
              SizedBox(height: 24.h),
            ],

            // Language Section
            _SettingsSection(
              title: 'Language',
              children: [
                _SettingsDropdown(
                  icon: Icons.language,
                  title: 'App Language',
                  subtitle: 'Choose your preferred language',
                  value: settings.language == 'en' ? 'English' : 'Spanish',
                  items: const ['English', 'Spanish', 'French', 'German'],
                  onChanged: (value) {
                    ref.read(appSettingsNotifierProvider.notifier).updateSettings(
                      settings.copyWith(language: value == 'English' ? 'en' : 'es'),
                    );
                  },
                ),
              ],
            ),

            SizedBox(height: 24.h),

            // Hardware & Design Section
            _SettingsSection(
              title: 'Hardware & Design',
              children: [
                _SettingsOption(
                  icon: Icons.receipt_long,
                  title: 'Receipt Designer',
                  subtitle: 'Customize how your receipts look',
                  onTap: () => context.push('/receipt-designer'),
                ),
                _SettingsOption(
                  icon: Icons.print,
                  title: 'Printer Settings',
                  subtitle: 'Connect to thermal printers',
                  onTap: () => context.push('/printer-settings'),
                ),
              ],
            ),

            SizedBox(height: 24.h),

            // About Section
            _SettingsSection(
              title: 'About',
              children: [
                _SettingsOption(
                  icon: Icons.info,
                  title: 'App Version',
                  subtitle: AppConfig.appVersion,
                  onTap: null,
                ),
                _SettingsOption(
                  icon: Icons.description,
                  title: 'Terms of Service',
                  subtitle: 'Read our terms and conditions',
                  onTap: () {
                    // TODO: Navigate to terms
                  },
                ),
                _SettingsOption(
                  icon: Icons.privacy_tip,
                  title: 'Privacy Policy',
                  subtitle: 'Read our privacy policy',
                  onTap: () {
                    // TODO: Navigate to privacy policy
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 12.h),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
            side: BorderSide(color: Colors.grey[200]!),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _SettingsSwitch extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsSwitch({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppConfig.primaryColor),
      title: Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 12.sp),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppConfig.primaryColor,
      ),
    );
  }
}

class _SettingsDropdown extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _SettingsDropdown({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppConfig.primaryColor),
      title: Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 12.sp),
      ),
      trailing: DropdownButton<String>(
        value: value,
        items: items.map((String item) {
          return DropdownMenuItem<String>(value: item, child: Text(item));
        }).toList(),
        onChanged: onChanged,
        underline: Container(),
      ),
    );
  }
}

class _SettingsOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _SettingsOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppConfig.primaryColor),
      title: Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 12.sp),
      ),
      trailing: onTap != null
          ? const Icon(Icons.arrow_forward_ios, size: 16)
          : null,
      onTap: onTap,
    );
  }
}
