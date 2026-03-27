enum AppPermission {
  // Inventory
  viewInventory,
  manageInventory, // Create, Edit, Delete
  adjustStock,
  transferStock,
  exportInventory,

  // POS
  createSale,
  viewOwnSales,
  viewAllSales,
  approveSale, 
  approvePayment,
  approveRefund,
  refundSale,

  // Financials
  viewAnalytics,
  manageExpenses,

  // Management
  manageEmployees,
  editSettings,
}

enum AppRole {
  owner,
  admin,
  pharmacist, // Mapping Sales Rep to Documentation naming
  cashier,
  inventoryManager;

  static AppRole fromString(final String? role) {
    switch (role?.toLowerCase()) {
      case 'owner':
        return AppRole.owner;
      case 'admin':
        return AppRole.admin;
      case 'pharmacist':
      case 'sales_rep':
        return AppRole.pharmacist;
      case 'cashier':
        return AppRole.cashier;
      case 'inventory_manager':
        return AppRole.inventoryManager;
      default:
        return AppRole.pharmacist;
    }
  }

  bool get isSystem => this == AppRole.owner || this == AppRole.admin;

  Set<AppPermission> get permissions {
    switch (this) {
      case AppRole.owner:
        return AppPermission.values.toSet();
      case AppRole.admin:
        // Admin has everything except deleting the business (effectively everything in this app)
        return AppPermission.values.toSet();
      case AppRole.pharmacist:
        return {
          AppPermission.viewInventory,
          AppPermission.createSale,
          AppPermission.viewOwnSales,
        };
      case AppRole.cashier:
        return {
          AppPermission.viewInventory,
          AppPermission.createSale,
          AppPermission.viewAllSales,
          AppPermission.approvePayment,
        };
      case AppRole.inventoryManager:
        return {
          AppPermission.viewInventory,
          AppPermission.manageInventory,
          AppPermission.adjustStock,
          AppPermission.transferStock,
        };
    }
  }

  bool hasPermission(final AppPermission permission) => permissions.contains(permission);
}
