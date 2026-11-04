import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../shared/presentation/widgets/common_app_bar.dart';
import '../../../../shared/providers/modules_provider.dart';
import '../../../../shared/models/module_model.dart';
import '../../../../core/constants/module_configs.dart';


class ModulesPage extends ConsumerWidget {
  const ModulesPage({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final enabledModules = ref.watch(modulesNotifierProvider);
    const allModules = ModuleConfigs.allModules;

    return Scaffold(
      appBar: const CommonAppBar(title: 'Module Manager'),
      body: GridView.builder(
        padding: EdgeInsets.all(16.w),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16.w,
          mainAxisSpacing: 16.h,
          childAspectRatio: 0.85,
        ),
        itemCount: allModules.length,
        itemBuilder: (final context, final index) {
          final module = allModules[index];
          final isEnabled = enabledModules.contains(module.id);
          return _ModuleCard(
            module: module,
            isEnabled: isEnabled,
            onToggle: () => ref.read(modulesNotifierProvider.notifier).toggleModule(module.id),
          );
        },
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  final ModuleModel module;
  final bool isEnabled;
  final VoidCallback onToggle;

  const _ModuleCard({
    required this.module,
    required this.isEnabled,
    required this.onToggle,
  });

  IconData _getIcon(final String iconName) {
    switch (iconName) {
      case 'inventory_2': return Icons.inventory_2;
      case 'point_of_sale': return Icons.point_of_sale;
      case 'dashboard': return Icons.dashboard;
      case 'analytics': return Icons.analytics;
      case 'money_off': return Icons.money_off;
      case 'people': return Icons.people;
      case 'payments': return Icons.payments;
      case 'receipt': return Icons.receipt_long;
      default: return Icons.extension;
    }
  }

  @override
  Widget build(final BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
        side: BorderSide(color: isEnabled ? Colors.blue : Colors.grey[200]!, width: 2),
      ),
      color: isEnabled ? Colors.blue[50] : Colors.white,
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(16.r),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(_getIcon(module.icon), size: 40.r, color: isEnabled ? Colors.blue : Colors.grey),
              SizedBox(height: 12.h),
              Text(
                module.name,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: isEnabled ? Colors.blue[900] : Colors.grey[800],
                ),
              ),
              SizedBox(height: 12.h),
              Switch.adaptive(
                value: isEnabled,
                onChanged: (_) => onToggle(),
                activeColor: Colors.blue,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
