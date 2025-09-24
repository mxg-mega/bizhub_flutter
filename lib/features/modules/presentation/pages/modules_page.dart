import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/config/app_config.dart';

class ModulesPage extends StatelessWidget {
  const ModulesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Modules',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppConfig.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Available Modules',
              style: GoogleFonts.inter(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Enable or disable features as needed',
              style: GoogleFonts.inter(
                fontSize: 16.sp,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 24.h),
            Expanded(
              child: ListView.builder(
                itemCount: AppConfig.availableModules.length,
                itemBuilder: (context, index) {
                  final module = AppConfig.availableModules[index];
                  return _ModuleCard(
                    title: module.toUpperCase(),
                    subtitle: 'Manage your $module',
                    icon: _getModuleIcon(module),
                    isEnabled: true, // TODO: Get from state
                    onToggle: (value) {
                      // TODO: Toggle module
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getModuleIcon(String module) {
    switch (module) {
      case 'inventory':
        return Icons.inventory;
      case 'sales':
        return Icons.point_of_sale;
      case 'customers':
        return Icons.people;
      case 'employees':
        return Icons.badge;
      case 'finance':
        return Icons.account_balance_wallet;
      case 'reports':
        return Icons.assessment;
      case 'settings':
        return Icons.settings;
      default:
        return Icons.apps;
    }
  }
}

class _ModuleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isEnabled;
  final ValueChanged<bool> onToggle;

  const _ModuleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isEnabled,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      child: ListTile(
        leading: Container(
          width: 48.w,
          height: 48.w,
          decoration: BoxDecoration(
            color: isEnabled ? AppConfig.primaryColor : Colors.grey[300],
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Icon(
            icon,
            color: isEnabled ? Colors.white : Colors.grey[600],
            size: 24.w,
          ),
        ),
        title: Text(
          title,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: isEnabled ? Colors.black87 : Colors.grey[600],
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.inter(
            color: isEnabled ? Colors.grey[600] : Colors.grey[400],
          ),
        ),
        trailing: Switch(
          value: isEnabled,
          onChanged: onToggle,
          activeColor: AppConfig.primaryColor,
        ),
      ),
    );
  }
}
