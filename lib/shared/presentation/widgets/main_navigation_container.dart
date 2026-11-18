import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/config/router/app_router.dart';
import '../../../core/config/theme/app_theme.dart';
import '../../../core/constants/module_configs.dart';
import '../../models/module_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/modules_provider.dart';

class MainNavigationContainer extends ConsumerWidget {
  final Widget child;
  const MainNavigationContainer({super.key, required this.child});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final location = GoRouterState.of(context).uri.toString();
    final palette = AppTheme.paletteOf(context);

    return Scaffold(
      drawer: const _AppDrawer(),
      body: child,
      bottomNavigationBar: _CustomBottomNavBar(
        location: location,
        onNavigate: (final path) => context.go(path),
        palette: palette,
      ),
    );
  }
}

class _CustomBottomNavBar extends StatelessWidget {
  final String location;
  final ValueChanged<String> onNavigate;
  final AppPalette palette;

  const _CustomBottomNavBar({
    required this.location,
    required this.onNavigate,
    required this.palette,
  });

  @override
  Widget build(final BuildContext context) {
    final isHomeActive = location == '/dashboard' ||
        (location.startsWith('/dashboard') && !location.startsWith('/dashboard/'));
    final isStockActive = location.startsWith('/inventory') ||
        location.startsWith('/restock') ||
        location.startsWith('/suppliers');
    final isSellActive = location.startsWith('/pos') ||
        location.startsWith('/sales-history') ||
        location.startsWith('/sale-success');
    final isReportsActive = location.startsWith('/analytics') ||
        location.startsWith('/expenses');
    final isMoreActive = location.startsWith('/settings') ||
        location.startsWith('/more') ||
        location.startsWith('/menu') ||
        location.startsWith('/profile') ||
        location.startsWith('/business-profile') ||
        location.startsWith('/modules') ||
        location.startsWith('/receipt-designer') ||
        location.startsWith('/printer-settings') ||
        location.startsWith('/zakat');

    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      color: Colors.transparent,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          // Background Bar
          Container(
            height: 64.h + bottomPadding,
            padding: EdgeInsets.only(bottom: bottomPadding),
            decoration: BoxDecoration(
              color: palette.card,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1A1A2E).withValues(alpha: 0.08),
                  offset: const Offset(0, -2),
                  blurRadius: 10,
                ),
              ],
              border: Border(
                top: BorderSide(
                  color: palette.outline.withValues(alpha: 0.5),
                  width: 0.8,
                ),
              ),
            ),
            child: Row(
              children: [
                // 1. Home
                Expanded(
                  child: _NavItem(
                    icon: Icons.home_rounded,
                    label: 'Home',
                    isSelected: isHomeActive,
                    onTap: () => onNavigate('/dashboard'),
                    palette: palette,
                  ),
                ),
                // 2. Stock
                Expanded(
                  child: _NavItem(
                    icon: Icons.hexagon,
                    label: 'Stock',
                    isSelected: isStockActive,
                    onTap: () => onNavigate('/inventory'),
                    palette: palette,
                  ),
                ),
                // 3. Center Sell Column (Text below the raised floating button)
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onNavigate('/pos'),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        SizedBox(height: 38.h),
                        Text(
                          'Sell',
                          style: GoogleFonts.inter(
                            fontSize: 12.sp,
                            fontWeight: isSellActive ? FontWeight.w700 : FontWeight.w600,
                            color: isSellActive ? palette.primary : palette.textSecondary,
                          ),
                        ),
                        SizedBox(height: 7.h),
                      ],
                    ),
                  ),
                ),
                // 4. Reports
                Expanded(
                  child: _NavItem(
                    icon: Icons.bar_chart_rounded,
                    label: 'Reports',
                    isSelected: isReportsActive,
                    onTap: () => onNavigate('/analytics'),
                    palette: palette,
                  ),
                ),
                // 5. More
                Expanded(
                  child: _NavItem(
                    icon: Icons.grid_view_rounded,
                    label: 'More',
                    isSelected: isMoreActive,
                    onTap: () => onNavigate('/settings'),
                    palette: palette,
                  ),
                ),
              ],
            ),
          ),

          // Floating Center Button: Amber circle with shopping cart icon
          Positioned(
            top: -18.h,
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                onNavigate('/pos');
              },
              child: Container(
                width: 58.r,
                height: 58.r,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5A623),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF5A623).withValues(alpha: 0.45),
                      offset: const Offset(0, 4),
                      blurRadius: 12,
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.shopping_cart_rounded,
                  size: 28.sp,
                  color: const Color(0xFF1A1A2E),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final AppPalette palette;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.palette,
  });

  @override
  Widget build(final BuildContext context) {
    final activeColor = palette.primary;
    final inactiveColor = palette.textSecondary;
    final color = isSelected ? activeColor : inactiveColor;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 26.sp,
            color: color,
          ),
          SizedBox(height: 3.h),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _AppDrawer extends ConsumerWidget {
  const _AppDrawer();

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final enabledModules = ref.watch(modulesNotifierProvider);
    final business = ref.watch(currentBusinessProvider);
    final palette = AppTheme.paletteOf(context);

    return Drawer(
      backgroundColor: palette.card,
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: palette.surface,
              border: Border(bottom: BorderSide(color: palette.outline)),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 30.r,
                    backgroundColor: palette.primary.withValues(alpha: 0.12),
                    child: Icon(
                      Icons.business,
                      color: palette.primary,
                      size: 30.sp,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    business?.name ?? 'BizModule',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: palette.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
          _DrawerItem(
            icon: Icons.person_outline,
            label: 'Profile',
            palette: palette,
            onTap: () {
              Navigator.pop(context);
              context.push('/profile');
            },
          ),
          _DrawerItem(
            icon: Icons.apps,
            label: 'Module Manager',
            palette: palette,
            onTap: () {
              Navigator.pop(context);
              context.push('/modules');
            },
          ),
          Divider(color: palette.outline),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildModuleGroup(
                  context,
                  'CRM & Supply Chain',
                  const ['customers', 'suppliers'],
                  enabledModules,
                  palette,
                ),
                _buildModuleGroup(
                  context,
                  'Management & Finance',
                  const [
                    'employees',
                    'zakat_tracker',
                    'expenses',
                    'receipts',
                    'analytics',
                  ],
                  enabledModules,
                  palette,
                ),
              ],
            ),
          ),
          Divider(color: palette.outline),
          _DrawerItem(
            icon: Icons.logout,
            label: 'Logout',
            color: palette.error,
            palette: palette,
            onTap: () => ref.read(authProvider.notifier).signOut(),
          ),
          SizedBox(height: 12.h),
        ],
      ),
    );
  }

  Widget _buildModuleGroup(
    final BuildContext context,
    final String title,
    final List<String> moduleIds,
    final List<String> enabledModules,
    final AppPalette palette,
  ) {
    final displayedModules = moduleIds
        .where((final id) => enabledModules.contains(id))
        .toList();
    if (displayedModules.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          child: Text(
            title,
            style: GoogleFonts.inter(
              color: palette.textSecondary,
              fontWeight: FontWeight.bold,
              fontSize: 12.sp,
            ),
          ),
        ),
        ...displayedModules.map((final id) {
          final config = ModuleConfigs.getById(id);
          return _DrawerItem(
            icon: _getIconData(config.icon),
            label: config.name,
            palette: palette,
            onTap: () {
              Navigator.pop(context);
              _handleNavigation(context, config);
            },
          );
        }),
      ],
    );
  }

  void _handleNavigation(final BuildContext context, final ModuleModel config) {
    const implementedRoutes = [
      '/inventory',
      '/pos',
      '/dashboard',
      '/zakat',
      '/settings',
      '/customers',
      '/suppliers',
      '/employees',
      '/expenses',
      '/receipt-designer',
      '/analytics',
    ];

    if (implementedRoutes.any((final route) => config.path.startsWith(route))) {
      context.go(config.path);
    } else {
      context.push('${AppRouter.comingSoon}/${config.name}');
    }
  }

  IconData _getIconData(final String iconName) {
    switch (iconName) {
      case 'inventory_2':
        return Icons.inventory_2_outlined;
      case 'point_of_sale':
        return Icons.point_of_sale_outlined;
      case 'dashboard':
        return Icons.dashboard_outlined;
      case 'analytics':
        return Icons.analytics_outlined;
      case 'money_off':
        return Icons.money_off_outlined;
      case 'people':
        return Icons.people_outline;
      case 'payments':
        return Icons.payments_outlined;
      case 'receipt':
        return Icons.receipt_long_outlined;
      case 'people_outline':
        return Icons.people_outline;
      case 'local_shipping':
        return Icons.local_shipping_outlined;
      default:
        return Icons.apps;
    }
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final AppPalette palette;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.palette,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(final BuildContext context) {
    final itemColor = color ?? palette.textPrimary;
    return ListTile(
      leading: Icon(icon, color: itemColor),
      title: Text(
        label,
        style: GoogleFonts.inter(
          color: itemColor,
          fontSize: 14.sp,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }
}
