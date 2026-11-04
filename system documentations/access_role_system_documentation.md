# Access Control & Role-Based System (RBAC) Documentation

## 1. Overview
The system employs a sophisticated Role-Based Access Control (RBAC) architecture that supports both legacy module-level permissions and modern fine-grained action-level control. This system governs UI visibility, API execution, and automated notification distribution.

---

## 2. Core Data Structures

### 2.1 The `Role` Object
Located in `src/types/user.ts`, a Role defines the capabilities of a user within a business.
```typescript
{
  id: string;
  name: string;
  isSystem: boolean;        // System-protected roles (Owner, Admin)
  permissions: string[];     // Legacy flat list (e.g., ['sales', 'inventory'])
  permissionsMap?: {         // Fine-grained action map
    [module: string]: {
      view: boolean;
      create: boolean;
      edit: boolean;
      delete: boolean;
      approve?: boolean;
      export?: boolean;
      approve_payment?: boolean;
      approve_refund?: boolean;
    }
  }
}
```

### 2.2 System Roles (Presets)
Default roles are automatically seeded upon business creation:
- **Owner**: Root access to all modules and billing.
- **Admin**: Full operational access, can manage team members but not delete the business.
- **Pharmacist / Sales Rep**: Restricted to order creation and inventory lookup.
- **Cashier**: Specialized for payment confirmation and receipt printing.
- **Inventory Manager**: Dedicated to restocking and warehouse transfers.

---

## 3. Permission Enforcement Logic

### 3.1 The `hasPermission` Utility
Permissions are verified using a centralized utility (`src/lib/permission-utils.ts`) that handles the transition between legacy and fine-grained modes.

- **Legacy Mode**: Checks if the module string (e.g., `'sales'`) exists in the `permissions` array.
- **Fine-Grained Mode**: Checks the specific boolean flag in the `permissionsMap` (e.g., `permissionsMap.sales.approve_payment`).
- **Safety Fallback**: If a role lacks a `permissionsMap`, the system falls back to legacy module checks to ensure no one is locked out during updates.

### 3.2 UI-Level Guarding
Components use the `useAuth` and `useRoles` hooks to conditionally render elements:
```tsx
const { currentUserRole } = useAuth();
const canDelete = hasPermission(currentUserRole, 'inventory', 'delete');

{canDelete && <DeleteButton />}
```

---

## 4. Role-Based Notification System

Notifications are not broadcasted to everyone. They follow strict distribution rules defined in `RoleBasedNotificationService`.

### 4.1 Distribution Rules
Each notification type has a target audience:
- **`new_sale`**: Sent to `Owner` and `Admin`. The `actor` (Pharmacist) also receives a confirmation.
- **`low_stock`**: Targeted at `Inventory Manager`, `Admin`, and `Owner`.
- **`zakat_calculation`**: Strictly limited to the `Owner` for financial privacy.
- **`refund_requested`**: Escalated to `Owner` and `Admin` for mandatory approval.

### 4.2 Implementation
The service queries the `businesses/{id}/team` collection to identify all users holding the required roles for a specific event and creates individual notification documents for them.

---

## 5. Administrative Controls

### 5.1 System Protection
- **Immutable Roles**: Core system roles (Owner, Admin) are protected. Their permissions cannot be modified via the UI to prevent "Self-Lockout" scenarios.
- **Automatic Repair**: The `useRoles` hook includes a `repairMissingRoles` function. If it detects a business has no roles (due to a failed migration or manual deletion), it automatically re-seeds the default role set.

### 5.2 Team Management Paths
- **Team Collection**: `businesses/{businessId}/team/{userId}`
- **Invitations**: Handled via the `accept-invite` flow, which assigns the `RoleName` specified in the invite metadata to the new user upon joining.

---

## 6. Security Mandates for Developers
1. **Never Hardcode IDs**: Role checks must always use the `name` or `permissionsMap` flags, never the Firestore `id`, as IDs can vary between tenants.
2. **Double-Sided Verification**: UI guarding is for UX; always perform a second `hasPermission` check inside the corresponding state-change hook (e.g., `useInventory.deleteProduct`).
3. **Audit Trail**: Any action requiring `approve` or `edit` permissions should log an audit entry using `logAudit` to track who exercised the privilege.
