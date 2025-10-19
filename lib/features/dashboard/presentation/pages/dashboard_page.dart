import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/app_config.dart';
import '../../../../shared/providers/auth_provider.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Dashboard',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppConfig.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authProvider.notifier).signOut();
              if (context.mounted) {
                context.go('/login');
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back, ${user?.name ?? 'User'}!',
              style: GoogleFonts.inter(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Manage your business efficiently',
              style: GoogleFonts.inter(
                fontSize: 16.sp,
                color: Colors.grey[600],
              ),
            ),
            if (user != null) ...[
              SizedBox(height: 16.h),
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20.r,
                      backgroundImage: user.photoUrl != null
                          ? NetworkImage(user.photoUrl!)
                          : null,
                      child: user.photoUrl == null
                          ? Icon(Icons.person, size: 20.r)
                          : null,
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            // TODO: Add role and businessId and fix the name issue
                            user.name ?? 'User',
                            style: GoogleFonts.inter(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            user.email,
                            style: GoogleFonts.inter(
                              fontSize: 14.sp,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            SizedBox(height: 32.h),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16.w,
                mainAxisSpacing: 16.h,
                children: [
                  _DashboardCard(
                    title: 'Modules',
                    subtitle: 'Manage features',
                    icon: Icons.apps,
                    color: AppConfig.primaryColor,
                    onTap: () {
                      // TODO: Navigate to modules
                    },
                  ),
                  _DashboardCard(
                    title: 'Profile',
                    subtitle: 'Account settings',
                    icon: Icons.person,
                    color: AppConfig.secondaryColor,
                    onTap: () {
                      // TODO: Navigate to profile
                    },
                  ),
                  _DashboardCard(
                    title: 'Settings',
                    subtitle: 'App preferences',
                    icon: Icons.settings,
                    color: AppConfig.accentColor,
                    onTap: () {
                      // TODO: Navigate to settings
                    },
                  ),
                  _DashboardCard(
                    title: 'Analytics',
                    subtitle: 'View reports',
                    icon: Icons.analytics,
                    color: AppConfig.successColor,
                    onTap: () {
                      // TODO: Navigate to analytics
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _DashboardCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48.w, color: color),
            SizedBox(height: 16.h),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
