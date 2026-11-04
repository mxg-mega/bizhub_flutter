import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../providers/modules_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/module_model.dart';
import '../../../core/constants/module_configs.dart';
import '../../../core/config/router/app_router.dart';

class MainNavigationContainer extends ConsumerWidget {
  final Widget child;
  const MainNavigationContainer({super.key, required this.child});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final location = GoRouterState.of(context).uri.toString();
    final enabledModules = ref.watch(modulesNotifierProvider);
    
    // Define the core navigation items that should always be present or mapped to modules
    final List<_NavDestination> allDestinations = [
      _NavDestination(
        id: 'dashboard',
        label: 'Home',
        icon: Icons.dashboard_outlined,
        selectedIcon: Icons.dashboard,
        path: '/dashboard',
      ),
      _NavDestination(
        id: 'pos',
        label: 'Sales',
        icon: Icons.point_of_sale_outlined,
        selectedIcon: Icons.point_of_sale,
        path: '/pos',
      ),
      _NavDestination(
        id: 'inventory',
        label: 'Inventory',
        icon: Icons.inventory_2_outlined,
        selectedIcon: Icons.inventory_2,
        path: '/inventory',
      ),
      _NavDestination(
        id: 'zakat_tracker',
        label: 'Zakat',
        icon: Icons.account_balance_wallet_outlined,
        selectedIcon: Icons.account_balance_wallet,
        path: '/zakat',
      ),
      _NavDestination(
        id: 'settings',
        label: 'Settings',
        icon: Icons.settings_outlined,
        selectedIcon: Icons.settings,
        path: '/settings',
      ),
    ];

    // Filter based on enabled modules (Dashboard and Settings are usually core)
    final filteredDestinations = allDestinations.where((final d) {
      if (d.id == 'dashboard' || d.id == 'settings') return true;
      return enabledModules.contains(d.id);
    }).toList();

    int currentIndex = filteredDestinations.indexWhere((final d) => location.startsWith(d.path));
    if (currentIndex == -1) currentIndex = 0;

    return Scaffold(
      drawer: const _AppDrawer(),
      body: child,
      bottomNavigationBar: filteredDestinations.isNotEmpty 
        ? NavigationBar(
            selectedIndex: currentIndex,
            onDestinationSelected: (final index) {
              final dest = filteredDestinations[index];
              context.go(dest.path);
            },
            destinations: filteredDestinations.map((final d) => NavigationDestination(
              icon: Icon(d.icon),
              selectedIcon: Icon(d.selectedIcon),
              label: d.label,
            )).toList(),
          )
        : null,
    );
  }
}

class _NavDestination {
  final String id;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final String path;

  _NavDestination({
    required this.id,
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.path,
  });
}

class _AppDrawer extends ConsumerWidget {
  const _AppDrawer();

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final enabledModules = ref.watch(modulesNotifierProvider);
    final business = ref.watch(currentBusinessProvider);
    
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 30.r,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.business, color: Theme.of(context).primaryColor, size: 30.sp),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    business?.name ?? 'BizModule',
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Profile'),
            onTap: () {
              Navigator.pop(context);
              context.push('/profile');
            },
          ),
          ListTile(
            leading: const Icon(Icons.apps),
            title: const Text('Module Manager'),
            onTap: () {
              Navigator.pop(context);
              context.push('/modules');
            },
          ),
          const Divider(),
          
          // Dynamic Modules
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildModuleGroup(
                  context, 
                  'CRM & Supply Chain', 
                  ['customers', 'suppliers'], 
                  enabledModules,
                ),
                _buildModuleGroup(
                  context, 
                  'Management & Finance', 
                  ['employees', 'zakat_tracker', 'expenses', 'receipts', 'analytics'], 
                  enabledModules,
                ),
              ],
            ),
          ),
          
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () {
              ref.read(authProvider.notifier).signOut();
            },
          ),
          SizedBox(height: 20.h),
        ],
      ),
    );
  }

  Widget _buildModuleGroup(
    final BuildContext context, 
    final String title, 
    final List<String> moduleIds, 
    final List<String> enabledModules,
  ) {
    // Only show group if at least one module is enabled
    // Actually, according to the placeholder requirement, we might want to show them anyway if they are in Firestore?
    // But for now let's only show enabled ones, and if they are not implemented, they go to coming soon.
    
    final displayedModules = moduleIds.where((final id) => enabledModules.contains(id)).toList();
    if (displayedModules.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          child: Text(
            title, 
            style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12.sp),
          ),
        ),
        ...displayedModules.map((final id) {
          final config = ModuleConfigs.getById(id);
          return ListTile(
            leading: Icon(_getIconData(config.icon)),
            title: Text(config.name),
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
    // Check if the route exists in AppRouter or is implemented
    // For now, let's assume if it's in this list, it might be implemented or needs placeholder
    final implementedRoutes = [
      '/inventory', '/pos', '/dashboard', '/zakat', '/settings', 
      '/customers', '/suppliers', '/employees', '/expenses', 
      '/receipt-designer', '/analytics'
    ];

    if (implementedRoutes.any((final r) => config.path.startsWith(r))) {
      context.go(config.path);
    } else {
      context.push('${AppRouter.comingSoon}/${config.name}');
    }
  }

  IconData _getIconData(final String iconName) {
    switch (iconName) {
      case 'inventory_2': return Icons.inventory_2_outlined;
      case 'point_of_sale': return Icons.point_of_sale_outlined;
      case 'dashboard': return Icons.dashboard_outlined;
      case 'analytics': return Icons.analytics_outlined;
      case 'money_off': return Icons.money_off_outlined;
      case 'people': return Icons.people_outline;
      case 'payments': return Icons.payments_outlined;
      case 'receipt': return Icons.receipt_long_outlined;
      case 'people_outline': return Icons.people_outline;
      case 'local_shipping': return Icons.local_shipping_outlined;
      default: return Icons.apps;
    }
  }
}
