# Roles, Teams, and Membership System Documentation

## 1. Overview
The Roles and Teams system provides a multi-tenant membership architecture where users can belong to multiple businesses with different roles. It supports a dual-layer permission model: **Legacy (Module-level)** and **Enhanced (Action-level)**.

---

## 2. Data Architecture & Schemas

### 2.1 The Membership Model
User-business relationships are stored in two locations to allow for efficient bidirectional querying.

- **Business Perspective**: `businesses/{businessId}/team/{userId}`
  - Defines the user's role and status within that specific business.
- **User Perspective**: `users/{userId}/memberships/{businessId}`
  - Allows the user to quickly list all businesses they have access to.

### 2.2 Role Schema (`Role`)
Located in `src/types/user.ts`:
```typescript
{
  id: string;
  name: string;
  isSystem: boolean;        // Protects core roles (Owner, Admin)
  permissions: string[];     // Legacy (e.g., ["sales", "inventory"])
  permissionsMap?: {         // Enhanced (e.g., { sales: { create: true, delete: false } })
    [module: string]: {
      view: boolean;
      create: boolean;
      edit: boolean;
      delete: boolean;
      approve?: boolean;
      export?: boolean;
    }
  }
}
```

---

## 3. Dual-Layer Permission System

### 3.1 Simple (Legacy) Mode
- **Logic**: A flat array of strings. If `'sales'` is in the array, the user has full access to the Sales module.
- **UI**: Displayed as a simple list of checkboxes for modules.
- **Enforcement**: `hasPermission(role, 'sales', 'any', false)`.

### 3.2 Fine-Grained (Enhanced) Mode
- **Logic**: A nested object (`permissionsMap`). Access is granted per action (view, create, etc.).
- **UI**: A **Permission Matrix** (`src/components/settings/permission-matrix.tsx`) that allows toggling individual capabilities.
- **Enforcement**: `hasPermission(role, 'sales', 'approve_payment', true)`.

---

## 4. Key Components & UI Relations

### 4.1 Role Manager (`src/app/(app)/settings/roles/page.tsx`)
- **Function**: CRUD operations for roles.
- **Form**: Uses `react-hook-form` and `zod` for validation.
- **Logic Flow**:
  1. User toggles "Fine-Grained Permissions" switch.
  2. UI switches between the **Checkbox List** and the **Permission Matrix**.
  3. On Save: The `updateRole` or `addRole` hook is called, persisting the data to `businesses/{id}/roles`.

### 4.2 Team Table (`src/components/users/users-table.tsx`)
- **Function**: Managing memberships and invitations.
- **UI Relations**:
  - **Invite Member**: A dialog form (`inviteSchema`) that takes an email and a Role object.
  - **Change Role**: A dropdown that triggers `updateMemberRole`, updating both the team sub-collection and the user's membership link.

---

## 5. Logic Flows & Expected Outputs

### Flow A: Creating a Fine-Grained Role
1. **User Action**: Clicks "Add Role", enters "Cashier", enables "Fine-Grained".
2. **UI Output**: Matrix appears. User checks `sales.view`, `sales.create`, and `sales.approve_payment`.
3. **Logic Output**: 
   - `permissionsMap` is constructed.
   - `addRole` executes `setDoc(doc(db, 'businesses/.../roles/...'), { name: 'Cashier', permissionsMap: { ... } })`.

### Flow B: Permission Verification (Hook Level)
1. **Trigger**: Cashier clicks "Confirm Payment" in the POS.
2. **Logic Check**:
   ```typescript
   const canApprove = hasPermission(userRole, 'sales', 'approve_payment');
   // Evaluates role.permissionsMap['sales']['approve_payment']
   ```
3. **Expected Result**: 
   - If `true`: The `runTransaction` for payment confirmation proceeds.
   - If `false`: The button is disabled in the UI, and the API throws a "Permission Denied" error if bypassed.

---

## 6. Security & Best Practices
1. **System Role Protection**: Roles marked `isSystem: true` cannot have their `permissionsMap` modified. This prevents accidental deletion of the `Owner`'s root access.
2. **JIT Migration**: When a business enables Fine-Grained permissions, the system performs a **Just-In-Time (JIT) Migration** of all existing roles, mapping legacy module strings to a full set of fine-grained permissions.
3. **Atomic Operations**: Changing a user's role uses a `writeBatch` to ensure the `team` sub-collection and the `memberships` sub-collection stay in sync.
