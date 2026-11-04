import '../../shared/models/permission_model.dart';

enum AppPermission {
  inventory,
  pos,
  analytics,
  expenses,
  employees,
  settings,
  zakat_tracker,
  receipts;

  static AppPermission fromString(final String? value) {
    return AppPermission.values.firstWhere(
      (final e) => e.name == value,
      orElse: () => AppPermission.pos,
    );
  }
}

class PermissionManager {
  static bool hasPermission({
    required final RoleModel role,
    required final String module,
    final String action = 'view',
    final bool useFineGrained = false,
  }) {
    // If it's a system role (Owner/Admin), they have full access
    if (role.isSystem) return true;

    if (!useFineGrained) {
      // Legacy check: list of module IDs
      return role.permissions.contains(module);
    }

    // Enhanced check: permissionsMap
    final map = role.permissionsMap;
    if (map == null || !map.containsKey(module)) return false;

    final actions = map[module]!;
    switch (action.toLowerCase()) {
      case 'view':
        return actions.view;
      case 'create':
        return actions.create;
      case 'edit':
        return actions.edit;
      case 'delete':
        return actions.delete;
      case 'approve':
        return actions.approve;
      case 'export':
        return actions.export;
      default:
        return false;
    }
  }
}
