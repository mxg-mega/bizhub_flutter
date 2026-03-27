# Sales & POS System Technical Documentation

## 1. Overview
The Sales and POS module is a high-performance, transactional engine designed for multi-tenant business environments. It supports complex workflows (Draft → Approval → Payment), real-time inventory synchronization, and multi-currency/multi-location operations.

---

## 2. Firestore Data Architecture

### 2.1 Authoritative Paths
All business data is scoped under a unique `businessId`.
- **Sales Collection**: `businesses/{businessId}/sales/{saleId}`
- **Products Collection**: `businesses/{businessId}/products/{productId}`
- **Transactions (Financials)**: `businesses/{businessId}/transactions/{transactionId}`
- **Workflow Configuration**: `businesses/{businessId}/settings/workflowConfig`
- **Customer Balance**: `businesses/{businessId}/customers/{customerId}`

### 2.2 Document Schemas (`Sale` Object)
```typescript
{
  id: string;
  referenceNumber: string;    // e.g., INV-2403-9021
  barcode: string;            // e.g., SALE-1709...
  locationId: string;         // The specific branch/warehouse
  customerId: string | null;  // Linked customer for CRM/Credit
  status: 'Draft' | 'PendingPayment' | 'Paid' | 'Pending' | 'Refunded';
  
  items: [
    {
      productId: string,
      name: string,
      quantity: number,
      unitPrice: number,
      unit: string
    }
  ];
  
  financials: {
    subtotal: number,
    discount: number,
    discountType: 'percentage' | 'fixed',
    tax: number,
    taxRate: number,
    totalAmount: number
  };
  
  payment: {
    method: 'cash' | 'card' | 'bank_transfer' | 'on_credit',
    transferDetails?: {
      bankName: string,
      accountNumber: string,
      transferFee: number
    }
  };
  
  workflow: {
    enabled: boolean,
    createdBy: string,
    createdByName: string,
    approvedBy?: string,       // Cashier ID
    history: SaleWorkflowStage[]
  };
}
```

---

## 3. The `useSales` Hook (Logic & State)

The `useSales` hook acts as the **Orchestrator** for the sales lifecycle. It handles cross-module communication using Firestore Transactions to ensure data consistency.

### 3.1 `addSale` Transaction Logic
When a sale is finalized, the following atomic steps occur:
1. **Stock Verification**: Reads the current `stockByLocation` for every item in the cart.
2. **Usage Limit Check**: Verifies if the business has remaining "Invoicing" units on their plan.
3. **Inventory Deduction**: Subtracts quantities from the `stockByLocation` map in the `products` collection.
4. **Financial Logging**: Creates a record in the `transactions` collection for accounting.
5. **Customer Update**: If payment is `on_credit`, it increments the customer's `outstandingBalance`.
6. **Notification**: Distributes a `new_sale` notification via the `RoleBasedNotificationService`.

### 3.2 Workflow Interceptors
The hook checks the `WorkflowService` before finalizing:
- If `requireApproval` is enabled, the sale status is set to `PendingPayment`.
- Inventory is **only** deducted when the status moves to `Paid` or `Pending` (Credit).

---

## 4. POS Engine Specifications

### 4.1 Rapid Entry Logic
- **Barcode Scanner**: Listens for `Enter` key events on the search input. It performs an O(1) lookup via `getProductBySku` from the local inventory cache.
- **Cart Consolidation**: If a duplicate SKU is scanned, the engine increments the `quantity` of the existing line item instead of adding a new row.

### 4.2 Pricing Engine
- **Bag Units**: If a product is configured with `bagUnit`, the POS calculates price based on `pricingType`:
  - `per_piece`: `product.price * pieces`.
  - `per_bag`: `product.price * (pieces / piecesPerBag)`.
- **Dynamic Discounts**: Applied in real-time. The formula is: 
  `FinalTotal = (Subtotal - Discount) + ((Subtotal - Discount) * TaxRate)`.

---

## 5. Role & Permission Mapping

The system enforces strict role-based access control (RBAC):

| Role | Permissions | Responsibilities |
| :--- | :--- | :--- |
| **Pharmacist / Sales Rep** | `create`, `view_own` | Builds orders, selects units, sets status to `Draft` or `PendingPayment`. |
| **Cashier** | `confirm_payment`, `view_all` | Validates payment method, moves status to `Paid`, triggers inventory deduction. |
| **Manager / Owner** | `delete`, `refund`, `edit_settings` | Authorizes refunds, modifies tax/discount rules, views total analytics. |

---

## 6. Modular Interconnectivity

### 6.1 Sales → Inventory
- **Trigger**: Status transition to `Paid` or `Pending`.
- **Action**: Updates `stockByLocation[locationId]` using `runTransaction`.
- **Audit**: Generates an `inventoryAdjustment` record of type `sale`.

### 6.2 Sales → Customers
- **Trigger**: Sale to specific `customerId`.
- **Action**: If `on_credit`, updates `outstandingBalance`. All sales append to the customer's `purchaseHistory` (derived view).

### 6.3 Sales → Financials
- **Trigger**: Every confirmed sale.
- **Action**: Creates a `transaction` document with `type: 'Sale'`. This feeds the Profit/Loss and Revenue reports.

---

## 7. Security & Integrity Mandates
1. **No "Set" Updates**: Stock and balances must **never** be updated using `setDoc` or `updateDoc` outside of a transaction.
2. **Idempotency**: Every sale has a `referenceNumber`. The UI checks for existing references to prevent double-charging on network lag.
3. **Archiving over Deletion**: Products with associated `saleId`s are marked `isArchived: true` to prevent breaking historical reports.
