import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class MainNavigationContainer extends ConsumerWidget {
  final Widget child;
  const MainNavigationContainer({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.toString();
    
    int currentIndex = 0;
    if (location.startsWith('/dashboard')) currentIndex = 0;
    else if (location.startsWith('/pos')) currentIndex = 1;
    else if (location.startsWith('/inventory')) currentIndex = 2;
    else if (location.startsWith('/zakat')) currentIndex = 3;
    else if (location.startsWith('/settings')) currentIndex = 4;

    return Scaffold(
      drawer: const _AppDrawer(),
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          switch (index) {
            case 0: context.go('/dashboard'); break;
            case 1: context.go('/pos'); break;
            case 2: context.go('/inventory'); break;
            case 3: context.go('/zakat'); break;
            case 4: context.go('/settings'); break;
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.point_of_sale_outlined),
            selectedIcon: Icon(Icons.point_of_sale),
            label: 'Sales',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Inventory',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: 'Zakat',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class _AppDrawer extends StatelessWidget {
  const _AppDrawer();

  @override
  Widget build(BuildContext context) {
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
                  const Text(
                    'BizModule',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
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
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('CRM & Supply Chain', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ListTile(
            leading: const Icon(Icons.people_outline),
            title: const Text('Customers'),
            onTap: () {
              Navigator.pop(context);
              context.go('/customers');
            },
          ),
          ListTile(
            leading: const Icon(Icons.local_shipping_outlined),
            title: const Text('Suppliers'),
            onTap: () {
              Navigator.pop(context);
              context.go('/suppliers');
            },
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Management', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ListTile(
            leading: const Icon(Icons.admin_panel_settings_outlined),
            title: const Text('Employees'),
            onTap: () {
              Navigator.pop(context);
              context.go('/employees');
            },
          ),
          ListTile(
            leading: const Icon(Icons.account_balance_wallet_outlined),
            title: const Text('Zakat Tracker'),
            onTap: () {
              Navigator.pop(context);
              context.go('/zakat');
            },
          ),
          const Spacer(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () {
              // TODO: Implement logout logic
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
