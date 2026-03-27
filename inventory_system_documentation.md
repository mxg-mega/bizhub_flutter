# Inventory Management System Documentation

## 1. Overview

The inventory system is a multi-tenant, multi-location, and unit-aware architecture designed for scalability and data integrity. It supports advanced features like hierarchical unit conversions (e.g., Carton → Box → Piece), transactional stock transfers, and automated migration paths for legacy data.

---

## 2. Data Architecture (Models & Types)

### Product (`Product`)

The central entity representing an item. It uses a hybrid schema to support both legacy and modern unit systems.

- **`id`**: Unique identifier (UUID).
- **`stockByLocation`**: `{ [locationId: string]: number }` — The authoritative source for stock levels.
- **`stock`**: Computed total across all locations (sum of `stockByLocation`).
- **`unitPrices`**: Array of `UnitPrice` `{ unit, price, isDefault }`.
- **`cost`**: Purchase cost per unit.
- **Unit System Versioning**:
  - `unitSystemVersion`: `'legacy' | 'enhanced'`.
  - `unitChain`: (Enhanced only) Defines hierarchical unit relationships.
  - `priceConfigs`: (Enhanced only) Rules for auto-calculating or overriding unit prices.

### Location (`Location`)

- **`id`**: Unique identifier.
- **`name`**: Display name (e.g., "Main Warehouse").

### Inventory Adjustment (`InventoryAdjustment`)

- **`type`**: `'adjustment' | 'restock' | 'sale' | 'return' | 'damage' | 'loss'`.
- **`changes`**: `{ [locationId: string]: { old: number, new: number } }`.
- **`timestamp`**: ISO 8601 string.
- **`userId`**: ID of the user performing the action.

---

## 3. Multi-Location Management

### State Handling

Stock is never stored as a single integer. It is always a map where keys are location IDs.

- **UI Logic**: When a product is updated, the UI must iterate through all locations to display current levels.
- **Computation**: Total stock is derived via `computeTotalStock(stockByLocation)`.

### Transactional Integrity

All stock updates use **Firestore Transactions** to prevent race conditions:

1. **Stock Transfer**: A single atomic operation that decreases stock in `SourceLocation` and increases it in `TargetLocation`. It validates that `sourceStock >= transferQuantity` before committing.
2. **Increase/Decrease**: Direct modifications to specific keys in the `stockByLocation` map.

---

## 4. Advanced Unit System (Unit Chains)

The system allows for complex unit hierarchies using the **Unit Chain** pattern.

### Unit Chains (`UnitChain`)

- **`baseUnit`**: The primary/largest unit in the hierarchy.
- **`units`**: A list of all units in the chain, ordered by size.
- **`conversions`**: Defines the relationship between units (e.g., `1 Box = 12 Pieces`).

### Unit Templates

Standardized chains for specific industries:

- **Retail**: Carton → Box → Pack → Piece.
- **Pharmacy**: Bottle → Strip → Tablet → mg.
- **Metric**: kg → g → mg.

### Price Calculation (`PriceConfig`)

- **Auto-Calculation**: Smaller units automatically derive their price from the base unit using conversion factors.
- **Manual Overrides**: Users can set custom prices for specific units (e.g., offering a discount for buying a full "Carton" vs. individual "Pieces").

---

## 5. Data Migration & Legacy Support

### The "Safety Wrapper" (use-inventory hook)

The system includes a proactive migration layer to protect users who joined during the "single-stock" era:

1. **Detection**: If a product has legacy fields (`quantity` or `stock`) but no `stockByLocation`.
2. **Auto-Mapping**: The hook automatically moves the legacy value to the first available location.
3. **Firestore Sync**: It triggers a background `writeBatch` to update the document schema permanently.
4. **Resilience**: This ensures that no data is lost during structural upgrades.

### Unit Migration Path

Users can upgrade from simple units to "Enhanced Chains" using a non-destructive wizard:

- **Preview Mode**: Shows how existing pricing maps to a new hierarchy (e.g., converting a legacy `Box` unit into a `Retail Template`).
- **Data Preservation**: Existing selling prices are locked in as "Manual Overrides" during migration to prevent accidental price changes.

---

## 6. Auditing & Compliance

### The Audit Trail

Every manual stock correction creates an entry in `inventoryAdjustments`. This log captures:

- The delta (difference).
- The auditor (user).
- The reason (notes).
- The timestamp.

### Soft Deletion (Archiving)

Products cannot be hard-deleted if they have associated sales records:

- **Validation**: Before deletion, the system queries the `sales` collection for the `productId`.
- **Action**: If sales exist, the product is marked as `isArchived: true`.
- **Benefit**: Preserves referential integrity for historical financial reports while removing the item from active inventory views.

---

## 7. Operational Guardrails

### Usage Limits

- **Plan Enforcement**: The system checks `inventory` limits before allowing new products or imports.
- **Proactive Alerts**: Notifies users when they are within 5 items of their plan limit.

---

## 8. Implementation Guide for Other Frameworks (Flutter/Mobile)

To replicate this system in another framework, adhere to these architectural mandates:

1. **Map-Based Stock**: Use a `Map<String, double>` for stock levels to avoid "Single Point of Failure" stock values.
2. **Transaction-First API**: Never perform stock updates with simple "Set" operations; always use transactions or atomic increments.
3. **BFS Pathfinder**: Implement a Breadth-First Search utility to calculate conversion factors across complex `UnitChain` paths.
4. **Migration Interceptor**: Implement a service that "cleans" incoming JSON data, transforming legacy schemas into modern ones before they hit the state manager.
5. **Event Logging**: Bind every successful stock mutation to a secondary "Event Log" (Adjustment record) creation.
