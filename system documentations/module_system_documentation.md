# Module System Architecture & Configuration

## 1. Overview
The application follows a modular architecture where features (e.g., POS, Zakat, Inventory) are treated as standalone "plug-and-play" units. This allows for a flexible "Marketplace" model where business owners can enable or disable specific functionalities based on their needs.

---

## 2. Module Configuration (`ModuleConfig`)

Modules are defined as static constants in `src/modules/config.ts`. Every module must implement the `ModuleConfig` interface.

### 2.1 The `ModuleConfig` Interface
```typescript
{
  id: string;               // Unique internal ID (e.g., 'pos')
  name: string;             // Display name
  path: string;             // Root URL path
  icon: LucideIcon;         // Menu icon
  component: React.ComponentType; // Main entry-point component
  isActive: boolean;        // Runtime status (enabled/disabled)
  isInstalled: boolean;     // Availability status
  enabledByDefault: boolean; // Initial state for new businesses
  isPremium: boolean;       // Billing category
  category: string;         // 'sales' | 'inventory' | 'finance' | 'admin'
  permissionId?: string;    // (Optional) Required permission to access
}
```

---

## 3. Persistence & State Management

### 3.1 Firestore Collection Path
The "Enabled" state of modules for a specific business is stored in:
`businesses/{businessId}/settings/modules`

This document contains a map of module IDs and their boolean states.

### 3.2 The `moduleService` layer
`src/services/module-service.ts` (abstracted) provides the bridge to Firestore:
- `getEnabledModules()`: Fetches the current set of active IDs.
- `setModuleEnabled(id, bool)`: Updates the state in Firestore.
- `subscribeToModules(callback)`: Provides a real-time listener for multi-user synchronization.

### 3.3 Hybrid Persistence (Offline Support)
The `ModuleManagerProvider` (`src/hooks/use-module-manager.tsx`) uses a dual-layer strategy:
1. **Primary**: Firestore real-time listener.
2. **Fallback**: `localStorage` (`bizmodule-enabled-modules`).
If the user is offline or Firebase fails to load, the system falls back to the locally cached state to prevent UI breakdown.

---

## 4. Enabling & Disabling Flow

### 4.1 Logical Workflow
1. **User Action**: User toggles a switch in the **Module Manager** UI (`src/app/(app)/modules/page.tsx`).
2. **Optimistic Update**: The `useModuleManager` hook immediately updates the local `enabledModuleIds` Set.
3. **Firestore Commit**: The `moduleService` attempts to persist the change to the business settings.
4. **Rebuild**: The sidebar and router re-evaluate the `enabledModules` array, hiding/showing navigation items and granting/revoking access to routes.

---

## 5. Developer Guide: Adding a New Module

1. **Create Feature**: Build the pages and components in `src/app/(app)/[your-module]`.
2. **Register Config**: Add the module metadata to `ALL_MODULES` in `src/modules/config.ts`.
3. **Define Permissions**: (Optional) Add a corresponding entry in `src/types/user.ts` under `PermissionsMap` to enable fine-grained access control within the new module.
4. **Set Default State**: Decide if `enabledByDefault` should be `true` (Core) or `false` (Marketplace).
