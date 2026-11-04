import '../../shared/models/module_model.dart';

class ModuleConfigs {
  static const List<ModuleModel> allModules = [
    ModuleModel(
      id: 'inventory',
      name: 'Inventory',
      path: '/inventory',
      icon: 'inventory_2',
      category: 'inventory',
      enabledByDefault: true,
      description: 'Manage your products, stock, and suppliers.',
    ),
    ModuleModel(
      id: 'pos',
      name: 'POS',
      path: '/pos',
      icon: 'point_of_sale',
      category: 'sales',
      enabledByDefault: true,
      description: 'Point of Sale system for processing sales.',
    ),
    ModuleModel(
      id: 'dashboard',
      name: 'Dashboard',
      path: '/dashboard',
      icon: 'dashboard',
      category: 'admin',
      enabledByDefault: true,
      description: 'Overview of your business performance.',
    ),
    ModuleModel(
      id: 'analytics',
      name: 'Analytics',
      path: '/analytics',
      icon: 'analytics',
      category: 'admin',
      description: 'Detailed reports and business insights.',
    ),
    ModuleModel(
      id: 'expenses',
      name: 'Expenses',
      path: '/expenses',
      icon: 'money_off',
      category: 'finance',
      description: 'Track and manage business expenses.',
    ),
    ModuleModel(
      id: 'employees',
      name: 'Employees',
      path: '/employees',
      icon: 'people',
      category: 'admin',
      description: 'Manage your team and permissions.',
    ),
    ModuleModel(
      id: 'zakat_tracker',
      name: 'Zakat Tracker',
      path: '/zakat',
      icon: 'payments',
      category: 'finance',
      description: 'Track and calculate Zakat obligations.',
    ),
    ModuleModel(
      id: 'receipts',
      name: 'Receipts',
      path: '/receipts',
      icon: 'receipt',
      category: 'finance',
      description: 'Customize and manage business receipts.',
    ),
  ];

  static ModuleModel getById(final String id) {
    return allModules.firstWhere(
      (final m) => m.id == id,
      orElse: () => allModules.first,
    );
  }
}
