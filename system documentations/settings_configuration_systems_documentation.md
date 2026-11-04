# Settings & Configuration System Documentation

## 1. Overview
The settings module is the administrative backbone of the application, managing business identity, localization (currency/units), operational workflows, and UI preferences. It follows a modular "Setting-as-a-Document" pattern in Firestore.

---

## 2. Firestore Storage Architecture

All configuration is scoped under the business document:
`businesses/{businessId}/settings/{settingType}`

### 2.1 Core Setting Documents
| Setting Type | Path | Purpose |
| :--- | :--- | :--- |
| **Business Info** | `.../settings/info` | Identity (Name, Address, Tax ID, Logo). |
| **Currency** | `.../settings/currency` | Localization (Currency code, Symbol). |
| **Unit System** | `.../settings/unit-system` | Enhanced unit templates and custom conversion chains. |
| **Preferences** | `.../settings/userPreferences` | UI toggles (Demo data, Receipt templates, Language). |
| **Workflows** | `.../settings/workflowConfig` | Approval rules for Sales and Refunds. |
| **Categories** | `.../settings/inventoryCategories` | Global list of product categories. |

---

## 3. Localization & Formatting

### 3.1 Currency Management (`useCurrency`)
- **Storage**: Stores the `currencyCode` (e.g., `'NGN'`, `'USD'`).
- **Formatting Engine**: Uses `Intl.NumberFormat` to provide a globally consistent `formatCurrency(amount)` utility. 
- **Auto-Initialization**: If no currency is set, the system defaults to the regional currency based on the initial business setup.

### 3.2 Enhanced Unit System (`useUnitSystem`)
This is the most complex configuration module, supporting hierarchical units.
- **Templates**: Pre-defined chains (Retail, Pharmacy, Metric).
- **BFS Pathfinder**: A Breadth-First Search algorithm (`findConversionPath`) is used to calculate conversion factors between any two units in a chain (e.g., Carton to Piece through Box).
- **Price Calculation**: Supports `isAutoCalculated` flags where smaller units automatically derive their price from a base unit + optional markup.

---

## 4. Operational Workflows (`WorkflowService`)

Governs the "Checks and Balances" within the business.
- **Invoice Workflow**:
  - `enabled`: Toggles multi-stage sales.
  - `requireApproval`: If true, sales move to `PendingPayment` instead of `Paid` until an authorized role (Cashier/Owner) confirms.
- **Refund Workflow**:
  - `maxAmountWithoutApproval`: Defines a threshold for automatic refunds. Anything above requires `Owner` intervention.

---

## 5. Multi-Location Infrastructure (`useLocations`)

Locations are stored in a dedicated sub-collection:
`businesses/{businessId}/locations/{locationId}`

- **Primary Location**: The first created location acts as the default for all new products and sales.
- **Inventory Isolation**: Every product tracks stock individually per `locationId` in its `stockByLocation` map.

---

## 6. Developer Integration Guide

### 6.1 Adding a New Setting
1. **Define Type**: Add the interface to `src/types/settings.ts`.
2. **Create Hook**: Implement a `use-[setting-name].tsx` hook that uses `BusinessApi` to fetch/update the Firestore document.
3. **Register Provider**: Wrap the `SettingsProvider` in `src/app/layout.tsx` (if global) or in the settings page sub-layout.

### 6.2 Best Practices
- **Atomic Updates**: Settings are updated using `{ merge: true }` to prevent accidental overwrites of unrelated configuration keys.
- **Optimistic UI**: Hooks should update local state immediately and handle rollbacks if the Firestore write fails.
- **Permission Guarding**: Only roles with `settings.edit` (Owners/Admins) should be allowed to modify documents in the `/settings` sub-path.
