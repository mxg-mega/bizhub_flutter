import '../../shared/models/permission_model.dart';

class RoleConfigs {
  static const String ownerId = 'owner';
  static const String adminId = 'admin';
  static const String managerId = 'manager';
  static const String staffId = 'staff';

  static RoleModel get ownerRole => const RoleModel(
        id: ownerId,
        name: 'Owner',
        isSystem: true,
        permissions: [
          'inventory',
          'pos',
          'analytics',
          'expenses',
          'employees',
          'customers',
          'suppliers',
          'zakat_tracker',
          'receipts',
          'settings',
        ],
      );

  static RoleModel get adminRole => const RoleModel(
        id: adminId,
        name: 'Admin',
        isSystem: true,
        permissions: [
          'inventory',
          'pos',
          'analytics',
          'expenses',
          'employees',
          'customers',
          'suppliers',
          'zakat_tracker',
          'receipts',
          'settings',
        ],
      );

  static RoleModel get managerRole => const RoleModel(
        id: managerId,
        name: 'Manager',
        isSystem: false,
        permissions: [
          'inventory',
          'pos',
          'analytics',
          'expenses',
          'customers',
          'suppliers',
          'receipts',
        ],
        permissionsMap: {
          'inventory': PermissionActions(view: true, create: true, edit: true, export: true),
          'pos': PermissionActions(view: true, create: true, edit: true, approve: true),
          'analytics': PermissionActions(view: true, export: true),
          'expenses': PermissionActions(view: true, create: true, edit: true),
        },
      );

  static RoleModel get staffRole => const RoleModel(
        id: staffId,
        name: 'Staff',
        isSystem: false,
        permissions: [
          'inventory',
          'pos',
        ],
        permissionsMap: {
          'inventory': PermissionActions(view: true),
          'pos': PermissionActions(view: true, create: true),
        },
      );

  static List<RoleModel> get defaultRoles => [
        ownerRole,
        adminRole,
        managerRole,
        staffRole,
      ];
}
