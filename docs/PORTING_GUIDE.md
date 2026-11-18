# BizModule Porting Guide — Flutter ↔ Next.js Wire Contract

> **Audience:** anyone porting the Next.js app (`/home/cipher/Desktop/Biz-module/Biz-Module`, "the web app")
> to the Flutter app (`/home/cipher/Desktop/biz_module`, "the mobile app"), or changing either side afterward.
>
> **Goal:** both clients share ONE Firestore database with live users. Every write from either
> client must be readable, correct, and financially consistent in the other client.
> When in doubt, the web app's *actual* write behavior (not its type annotations) is the source of truth.

---

## 0. Ground Rules (non-negotiable)

1. **Web is the wire-format source of truth.** Mirror what the web hooks actually write
   (`src/hooks/use-sales.tsx`, `src/hooks/use-inventory.tsx`, `src/hooks/use-transactions.tsx`),
   not just what `src/types/*.ts` declares.
2. **Additive-only writes.** Flutter may keep its extra fields (`id`, `businessId`, `userId`,
   ledger `category`, …). They are ignored by the web. But NEVER write a field with `null`
   over an existing value — with `set(..., merge: true)` a `null` **deletes** the field.
   Strip `null`s from every outbound payload (web's `cleanFirestoreData`, `src/lib/firestore-utils.ts`,
   only strips top-level `undefined`; Flutter must do the same for `null`).
3. **Never persist computed fields.** `Product.stock` is computed as the sum of
   `stockByLocation` on read (`use-inventory.tsx:172`); the web strips it before saving
   (`use-inventory.tsx:182-183`). Flutter must never write it as authoritative.
4. **Soft delete for products with sales history.** Products referenced by sales are
   archived (`isArchived: true` + audit fields), never hard-deleted (`use-inventory.tsx:432-477`).
   Flutter's hard `deleteProduct` is a parity violation to fix in M3.
5. **Money mutations are atomic.** Any write that moves stock, customer `outstandingBalance`,
   or creates a ledger entry must happen inside ONE Firestore `runTransaction` when online
   (see `use-sales.tsx:173-254`). The offline sync queue is the only exception (§7).
6. **Read tolerant, write canonical.** Both clients normalize legacy values on read
   (table §4) and write only canonical values (tables §3).
7. **New client-side fields must be documented here first.** A field that is not in this
   guide's entity tables may not be written to Firestore by either client.

---

## 1. Firestore Path Map

Source: web `src/lib/firebase-paths.ts`.

| Entity | Path | Notes |
| :--- | :--- | :--- |
| Sales | `businesses/{businessId}/sales` | doc id = sale id (web: `doc(collection(...))`, `use-sales.tsx:170`) |
| Products | `businesses/{businessId}/products` | doc id = product id |
| Transactions (ledger) | `businesses/{businessId}/transactions` | financial ledger; `orderBy('date')` queries |
| Locations | `businesses/{businessId}/locations` | doc id = location id |
| Inventory adjustments | `businesses/{businessId}/inventoryAdjustments` | audit trail |
| Customers | `businesses/{businessId}/customers` | holds `outstandingBalance` |
| Categories | `businesses/{businessId}/settings/inventoryCategories` | doc field: `list: string[]` |
| Transfers (bank) | `businesses/{businessId}/transfers` | created for `bank_transfer` sales |
| Workflow config | `businesses/{businessId}/settings/workflowConfig` | doc fields: `invoiceWorkflow.enabled`, `invoiceWorkflow.requireApproval` |
| Usage limits | `usage_limits/{businessId}` (+ `businesses/{id}/usage`) | **deferred** — see §9 |
| Customer payments (Flutter-only) | `businesses/{id}/customerPayments` | ⚠️ web never reads this; reconciliation deferred (§9) |
| Legacy user-scoped | `users/{uid}/...` | migration target only; never write from Flutter |

---

## 2. Timestamp & Date Policy (per field — they are NOT uniform)

The web mixes formats. Match it **per field**; do not apply one blanket rule.

| Field | Canonical (what web writes) | Read tolerance (both apps) |
| :--- | :--- | :--- |
| `Sale.date` | **ISO 8601 string** (`now.toISOString()`, `pos/page.tsx:369`) | web `toDate()` / `new Date(s)`; Flutter `DateTime.tryParse` |
| `Sale.createdAt`, `Sale.updatedAt` | **Firestore Timestamp** (`new Date()`, `use-sales.tsx:230,383`) | web `toDate()` handles Timestamp + string |
| `Transaction.date`, `Transaction.createdAt` | **Firestore Timestamp** (`Timestamp.fromDate`, `use-sales.tsx:246`) | `toDate()` |
| `Product.archivedAt` | **Firestore Timestamp** | `toDate()` |
| `InventoryAdjustment.timestamp` | **ISO 8601 string** (`new Date().toISOString()`, `use-inventory.tsx:697`) | both |
| `Product.expirationDate` | **`yyyy-MM-dd` string** (e.g. `"2025-12-31"`, `inventory.ts:71`) | web treats as plain string |
| `Sale.workflowHistory[].performedAt` | **Date → Timestamp** | `toDate()` |

**Why `Sale.date` must stay a string:** web's installment FIFO sorter does
`new Date(sale.date)` on raw doc data (`use-sales.tsx:773`) — a Firestore Timestamp
object yields *Invalid Date* there and silently mis-sorts credit invoices.

**Flutter `sanitizeForFirestore` hazard — fixed (M1–M6)**
(`lib/core/services/firestore_service.dart`): every entity writer now passes an
explicit `timestampFields` allowlist (`SaleModel` / `TransactionModel` /
`ProductModel` / `InventoryAdjustmentModel` `.firestoreTimestampFields`), and
the sync worker applies the same allowlist to queued payloads at push time
(`SyncService._timestampFieldsForPath`, §7.2) — offline-written docs get
identical wire shapes to online ones. The legacy substring heuristic remains
ONLY as the default for settings/business/user-style shared writers (no
`date`/`time` string fields in those contracts).

---

## 3. Entity Contracts

Legend: ✅ already matching · ⚠️ gap (missing, add in milestone) · ❌ mismatch (fix) · ➕ additive (Flutter-only, keep, ignored by web)

### 3.1 `Sale` — `businesses/{b}/sales/{id}` *(M1 implemented — pending staging dual-client sign-off)*

| Field | Web type / value | Flutter today | Status → action |
| :--- | :--- | :--- | :--- |
| *(doc id)* | doc.id, no `id` field in data | `id` field written | ➕ keep (same value as doc.id) |
| `customerId` | `string \| null` | `String?` | ✅ (write `null`, not absent, for walk-in) |
| `customer` | `string` (display name) | `String?` | ✅ ensure non-null at write |
| `locationId` | `string` | selected POS location; checkout aborts (no `'main'` invention) | ✅ M5 |
| `date` | ISO string | ISO string (explicit sanitize allowlist) | ✅ M1 |
| `createdAt` | Timestamp | Timestamp (explicit sanitize allowlist) | ✅ M1 (offline queue still writes ISO string until M6) |
| `updatedAt` | Timestamp | Timestamp | ✅ M1 |
| `status` | `SaleStatus` enum (§3.2) | same set; read-default by payment method | ✅ M1 (refund states M7) |
| `items` | `SaleItem[]` (§3.3) | extra `totalPrice` per item | ➕ keep; ensure shared fields match |
| `totalAmount` | `Σ quantity × unitPrice` (web ignores tax/discount here! `use-sales.tsx:143`) | items sum (`state.subtotal`), per §5 decision | ✅ M1 |
| `subtotal` | number | ✅ | ✅ |
| `tax` | number | ✅ | ✅ |
| `taxRate` | **percentage** (10 = 10%, `pos/page.tsx:376`) | percentage (cart fraction × 100) | ✅ M1 |
| `discount` | number | ✅ | ✅ |
| `discountType` | `'percentage' \| 'fixed'` | `'fixed'` written (percentage-discount UI is M5) | ✅ M1 (write side) |
| `amountPaid` | number (installments) | present | ✅ |
| `paymentMethod` | enum (§4) | canonical write + read normalizer; POS offers Cash / Card / Bank Transfer / On Credit | ✅ M5 |
| `salesPerson` | `string` | present | ✅ |
| `referenceNumber` | `INV-{yy}{mm}{rand4}` (`pos/page.tsx:315-321`) | same format generated | ✅ M1 |
| `notes` | `string` | present | ✅ |
| `workflowEnabled` | `bool` | flat bool written; legacy nested object only read | ✅ M1 |
| `workflowHistory[]` | `{stage, performedBy, performedByName, performedAt, notes}` | same shape; legacy `{status, actorId, createdAt}` entries lifted on read | ✅ M1 |
| `createdBy` / `createdByName` | user uid / displayName | written flat | ✅ M1 |
| `approvedBy` / `approvedByName` / `approvedAt` | set by `confirmPayment` | fields exist; stamped in M3 with confirm-payment rerouting | ⚠️ M3 |
| `barcode` | `SALE-{ms}-{id6}` (`use-sales.tsx:224`) | generated at checkout | ✅ M1 |
| `transferDetails` | `{transferFee, bankName, accountNumber, routingNumber, status:'pending'}` | POS Bank Transfer sheet captures all fields | ✅ M5 |
| `pendingSync` | client-side only flag | — | local-only, never write |

### 3.2 `SaleStatus` enum (both apps must use these exact strings)

`'Draft'` → `'PendingPayment'` → `'Paid'`; `'Pending'` (credit); `'RefundRequested'`; `'Refunded'`.
Stock is deducted **only** when status ∈ {`'Paid'`, `'Pending'`} — for `Draft`/`PendingPayment`
no deduction, no ledger entry (`use-sales.tsx:186,205,243`).

### 3.3 `SaleItem` (inside `Sale.items`)

| Field | Web | Flutter | Status |
| :--- | :--- | :--- | :--- |
| `productId` | string | string | ✅ |
| `name` | string | string | ✅ |
| `category` | string (required) | `String?` (stripped when null) | ⚠️ M5: always write, default `'Uncategorized'` |
| `quantity` | number, **raw, in sold unit** | double | ✅ |
| `unitPrice` | number per sold unit | double | ✅ |
| `unitCost` | `cost / conversionFactor` (`pos/page.tsx:174`) | `double?` | ⚠️ M5: populate |
| `unit` | sold unit name | string | ✅ |
| `totalPrice` | not written by web | `quantity × unitPrice` | ➕ keep |
| `description` | line-item subtitle/spec (optional) | `String?`, round-trips (M8) | ✅ M8 |
| `itemType` | `'product' \| 'service' \| 'fee' \| 'custom'` | `String?`, round-trips | ✅ M8 |
| `isCustom` | `boolean` — non-catalog line item | `bool?`; `isInventory` getter mirrors web `isInventoryProduct` | ✅ M8 |

**Non-inventory lines never touch product docs or stock** (web `isInventoryProduct`,
`use-sales.tsx:33`): `isCustom == true`, `itemType != 'product'`, empty `productId`,
or a `custom_` prefix all bypass product reads/stock writes. Flutter applies the same
guard in `cart_provider.checkout` and `sales_providers.approveSale` (online + offline).
Totals and the ledger still include those lines.

### 3.3b `TransferDetails` (inside `Sale.transferDetails`)

| Field | Web | Flutter | Status |
| :--- | :--- | :--- | :--- |
| `bankName` | string | `String?` | ✅ |
| `accountName` | string (NEW) | `String?` (M8) | ✅ M8 |
| `accountNumber`, `routingNumber` | string | `String?` | ✅ |
| `transferFee` | number | double (default 0) | ✅ |
| `transferId` | string | `String?` | ✅ |
| `status` | `'pending' \| 'completed' \| 'failed'` | String (default `'pending'`) | ✅ |

### 3.4 `Transaction` (financial ledger) — `businesses/{b}/transactions/{id}` *(M2 implemented — pending staging dual-client sign-off)*

| Field | Web type / value | Flutter today | Status → action |
| :--- | :--- | :--- | :--- |
| `date` | **Timestamp** | Timestamp via explicit sanitize allowlist (`TransactionModel.firestoreTimestampFields`); read-fallback to `createdAt` for legacy docs | ✅ M2 |
| `type` | `'Sale' \| 'Expense' \| 'Customer Payment' \| 'Refund' \| 'Adjustment'` (capitalized) | canonical on all writers; `normalizeType()` on read maps `'income'/'sale'/'expenses'` + casing | ✅ M2 |
| `amount` | positive number (items sum for sales) | `sale.totalAmount` | ✅ |
| `description` | `Sale to {customer}` | same phrasing (walk-in fallback) | ✅ M2 |
| `relatedEntityId` | sale id (for `type:'Sale'`) | written alongside `referenceId` | ✅ keep both (➕ `referenceId`) |
| `createdAt` | Timestamp | Timestamp (explicit allowlist); offline queue still ISO string until M6 | ✅ M2 |
| `paymentMethod` | string | canonical enum (§4) | ✅ |
| `performedBy` / `performedByName` | optional audit (web sets on confirmPayment) | model fields exist; stamped at checkout (additive) | ✅ M2 |
| `workflowStage` | `'payment_confirmed'` on confirm | model field exists; stamped in M3 with confirm-payment rerouting | ⚠️ M3 |
| `category` (Flutter enum) | not on web | `'revenue'` | ➕ keep, never map to web fields |
| `businessId` (Flutter) | not on web | written | ➕ keep |

**Exactly one ledger entry per confirmed sale.** The web used to create TWO
(inside the runTransaction AND via `TransactionsApi.addTransaction`, `use-sales.tsx`)
— fixed on web in M2 (both checkout and `confirmPayment`); Flutter never copied it.
The POS page's `paymentMethod.toLowerCase()` bug (`'bank transfer'`, `'on credit'`
with spaces) is also fixed on web with an explicit label→enum map.

### 3.5 `Product` — `businesses/{b}/products/{id}`

| Field | Web type / value | Flutter today | Status → action |
| :--- | :--- | :--- | :--- |
| `name`, `sku`, `description`, `category` | required strings | defaults `''` on parse; form writes trimmed strings | ✅ M4 |
| `stockByLocation` | `{ [locationId]: number }`, **denominated in `sellingUnit`** | `Map<String,double>` | ✅ (see §6 for denomination rule) |
| `stock` | computed, **never persisted** | `includeToJson: false` — never in any payload | ✅ M4 |
| `price` | per selling unit | `double` default 0.0 | ✅ M3: stock/archive writes are now field-targeted patches — `price` can no longer be zeroed by a partial rebuild |
| `unitPrices` | `[{unit, price, isDefault}]` | passthrough map list (form preserves on edit) | ✅ |
| `cost` | per purchase unit | double | ✅ |
| `purchaseUnit`, `sellingUnit` | strings | fromJson defaults (→ sellingUnit), form passthrough on edit | ✅ M4 |
| `conversionFactor` | number (restock: `qty × factor`, `use-inventory.tsx:564`) | always written; derived from `unitChain.getFactor(purchaseUnit → sellingUnit)` when absent, else 1.0 | ✅ M4 |
| `unitSystemVersion` | `'legacy' \| 'enhanced'` | `'enhanced'` | ✅ |
| `unitChain`, `priceConfigs`, `unitChainTemplate` | enhanced system | all three present; template + chain preserved on form edit | ✅ |
| `expirationDate` | `yyyy-MM-dd` string | `FlexibleDateConverter` — writes date-only string, reads date-only / ISO / Timestamp | ✅ M4 |
| `bagUnit` | `{piecesPerBag, pricingType, piecePrices?}` | read-only passthrough | ➕ M4 (full bag pricing later) |
| `isArchived` + `archivedAt/By/Name/Reason` | soft delete | archive patches all five fields with actor + reason | ✅ M4 |
| `createdBy`, `createdByName`, `lastModifiedBy`, `lastModifiedByName` | optional audit | provider stamps creator once + modifier always | ✅ M4 |

**Partial-update rule (fixed in M3):** stock-only updates must be
field-targeted patches (`{'stockByLocation': {...}, 'updatedAt': ...}`), never a
full-model `set(merge:true)` rebuilt from a subset of fields.
`ProductRepositoryImpl.updateStock/archiveProduct` now patch via
`_patchProduct` (local JSON read-modify-write + queued patch payload; sync
pushes with `merge:true`) — `price`, `category`, units, and expiration can no
longer be clobbered. `SaleActions.approveSale` was rerouted through a real
Firestore transaction (`sales_providers.dart`) with `confirmPayment` parity:
approval stamps `approvedBy/Name/At` + `updatedAt`, deducts stock exactly once
(unit-aware via `unitChain`), writes exactly one ledger entry with
`workflowStage: 'payment_confirmed'`, logs a web-shaped adjustment doc, and
grows the customer balance for credit sales. A guard skips already-`Paid` /
`Pending` sales to prevent double effects.

### 3.6 `Location` — `businesses/{b}/locations/{id}` *(M4 implemented)*

| Field | Web | Flutter | Status |
| :--- | :--- | :--- | :--- |
| `name` | string | string | ✅ |
| `updatedAt` | Timestamp on update (`use-locations.tsx:85-88`) | stamped on every save (ISO string in queue until M6) | ✅ M4 |
| delete guard | web blocks deleting a location that still holds stock (`use-locations.tsx:98-112`) | provider guard mirrors it | ✅ M4 |

### 3.7 `InventoryAdjustment` — `businesses/{b}/inventoryAdjustments/{id}` *(M3 implemented)*

| Field | Web | Flutter | Status → action |
| :--- | :--- | :--- | :--- |
| `productId`, `userId` | string | string | ✅ |
| `productName` | string | written | ✅ M3 |
| `changes` | `{ [locationId]: {old, new} }` | same shape | ✅ |
| `timestamp` | ISO string | ISO string (empty timestamp allowlist on write) | ✅ M3 |
| `type` | `'adjustment' \| 'restock' \| 'sale' \| ...` | constant `'adjustment'` (what web's writers emit); semantic kind moved to additive `kind` field | ✅ M3 |
| `notes` | string | written (legacy `reason` kept ➕) | ✅ M3 |
| `referenceId`, `costPerUnit`, `totalCost` | optional | absent | ⚠️ M4+ |

### 3.8 `Customer` (payments) — *(M7 implemented — pending staging dual-client sign-off)*

Shared today: `name`, `phone`, `outstandingBalance` (double).
Web ledger behavior: credit sale adds `totalAmount`; installment payment applies FIFO
across `'Pending'` sales, sets `amountPaid`, and writes a `'Customer Payment'` ledger entry
in the same transaction (`use-sales.tsx:752-849`). **Implemented** as
`CustomerRepository.recordInstallmentPayment` — Firestore transaction, FIFO by
`date`, `max(0, balance − totalApplied)`, one `'Customer Payment'` ledger with
`performedBy/Name` + `relatedEntityId = customerId`, local Isar cache mirrored.
`CustomerActions.recordPayment` now routes through it; the Flutter-only
`customerPayments` collection is no longer written (read paths remain for
legacy local data).

---

### 3.9 `Transfer` — `businesses/{b}/transfers/{id}` *(M9 implemented)*

Written by the web after a successful bank-transfer checkout (`use-sales.tsx:294`),
non-fatal (`try/catch`). Flutter writes the same doc via
`TransferRepository.saveTransfer` (local Isar + queue) and manages it in the
Transfers screen (Settings → Transfers). Web has no transfers UI page — its
`use-transfers.tsx` contract is the source of truth.

| Field | Web type / value | Flutter |
| :--- | :--- | :--- |
| `saleId` | string | ✅ |
| `customerId` / `customerName` | string (nullable) | ✅ (`customerId` null for walk-in) |
| `amount`, `transferFee` | number | ✅ |
| `bankName`, `accountName`, `accountNumber`, `routingNumber` | string (written as `''` when absent) | `String?`, stripped when null |
| `status` | `'pending' \| 'processing' \| 'completed' \| 'failed' \| 'cancelled'` | ✅ all 5 |
| `transferId`, `notes` | optional | ✅ |
| `createdAt`, `updatedAt` | **Timestamp** | Timestamp via `TransferModel.firestoreTimestampFields` |
| `processedAt` | Timestamp (set on completed/failed) | ✅ stamped by `updateStatus` |
| `businessId` (Flutter) | not on web | ➕ keep (also the Isar query key) |

**Status updates** mirror `updateTransferStatus`: `updatedAt` always, `processedAt`
on terminal statuses, `notes` only when provided. No role gate (web has none).

### 3.10 Receipt design settings — `businesses/{b}/settings/receiptDesign`

Web receipt designer schema (`src/types/receipt-designer.ts`). **M10 deferred (no
designer port).** Consistency slice only: Flutter reads the doc (read-only,
`webReceiptDesignProvider`) and renders `bankDetails`/`savedBankAccounts` (when
`showPaymentDetails`), `notesAndTerms`, `footerText` fallback, and `subFooterText`
on PDF/thermal receipts. Flutter's own `settings/receipt_template` doc and designer
keep working unchanged (separate document — no clobbering). Bank accounts are merged
primary-first and deduped by `accountNumber`, matching `use-receipt-design.tsx`.

Revisit when onboarding business types beyond supermarkets/retail.

## 4. Canonical Enums & Read-Side Normalization

**Payment methods (canonical write set):** `cash`, `card`, `bank_transfer`, `on_credit`, `other`.

Normalize on read (both apps, before display/logic):

| Raw values seen in DB | Normalize to |
| :--- | :--- |
| `'bank_transfer'`, `'bank transfer'` (web bug, `pos/page.tsx:379`), `'transfer'` (Flutter customer page), `'Bank Transfer'` | `bank_transfer` |
| `'Cash'`/`'Card'`/`'On Credit'` (any case) | lowercase canonical |
| missing / `null` | `cash` (web default on read, `use-sales.tsx:897`) |

**Transaction types:** write only `'Sale' | 'Expense' | 'Customer Payment' | 'Refund' | 'Adjustment'`.
On read, tolerate lowercase legacy (`'income'`, `'sale'`) by case-folding + mapping
`'income' → 'Sale'` for display only.

**Sale statuses:** exact strings from §3.2; on read treat missing as `'Paid'` only when
`paymentMethod != 'on_credit'`, else `'Pending'` (matches web defaults + credit logic).

---

## 5. Money Math Contract (pin this or amounts will drift)

Web POS (`pos/page.tsx:340-343`):
- `subtotal = Σ quantity × unitPrice`
- `tax = isTaxEnabled ? (subtotal − discount) × taxRate : 0`
- `discount` — applied before tax
- `totalAmount = subtotal + tax − discount`

⚠️ Known web inconsistency: the ledger and `Sale.totalAmount` are computed as
`Σ items quantity × unitPrice` (tax/discount ignored) inside `addSale`
(`use-sales.tsx:143`) while the POS page sends `subtotal + tax − discount` in
`totalAmount`… `addSale` then **overwrites** `totalAmount` from the items sum
(`use-sales.tsx:229`). Meaning: **on the web, `totalAmount` currently excludes tax and
discount.** Flutter's cart (`cart.total = subtotal + tax − discount`) is *more correct*
but writes a different number than the web for the same cart. Decision recorded here:
- **Canonical = web behavior** (items-sum) until the web fixes it, because live
  web dashboards and the ledger are built on it.
- Flutter must switch to items-sum in M1 and store tax/discount in their own fields
  (they already are) so a future web fix is a two-line change on both sides.
- The porting checklist (§8) includes "recompute totalAmount" as a marked divergence.

---

## 6. Stock Denomination & Unit Semantics

- `stockByLocation[id]` is denominated in the product's **`unitChain.baseUnit`** for
  enhanced products (the unit Flutter's checkout already assumed); legacy products
  (no `unitChain`) stay in their `sellingUnit`.
- **Both clients now convert sale quantities to stock units before deducting.** Web's
  `saleQuantityToStockUnits()` (`src/lib/units/convert.ts`) mirrors Flutter's
  `unitChain.getFactor(saleUnit → baseUnit)` (`cart_provider.dart:260`): single-hop
  chain lookup, bidirectional via `reverseFactor`, fallback 1.0; legacy passthrough,
  with `purchaseUnit` sales scaled by `conversionFactor`. Applied at every stock write
  in `use-sales.tsx`: checkout validation + deduction (addSale), `confirmPayment`
  Paid-path deduction, and `updateSale`'s revert/re-apply pair.
- **Restock multiplies** purchase units by `conversionFactor` (`use-inventory.tsx:564`).
- ✅ **Divergence resolved (web fixed):** web's checkout previously deducted the raw
  sale-unit quantity — selling 1 Carton (50-piece chain) removed only 1 piece of
  stock. It now converts exactly like Flutter. Web POS's decorative unit/conversion
  editor in the admin Edit-Item dialog was removed (`pos/page.tsx`) — it never saved
  those fields. Staging gate: sell 1 Carton (50-piece chain) on Flutter and 1
  sellingUnit on web — both clients must show the same resulting stock.
  Residual edge for the matrix: enhanced products where `sellingUnit ≠ baseUnit`
  plus the legacy restock path (`conversionFactor` is purchase→selling) — verify
  restock + sale round-trips land on the same stock value on both clients.

---

## 7. Offline Sync Queue Rules

1. Queued payloads are pushed with `set(merge: true)` **after sanitize-at-push**
   (`SyncService._syncItem` + `_timestampFieldsForPath`, M6): each payload is
   run through `sanitizeForFirestore` with the matching model's
   `firestoreTimestampFields` allowlist — ISO strings for `createdAt`/`date`/
   `archivedAt`/`updatedAt` become Firestore Timestamps, nulls are stripped,
   and adjustment `timestamp` values stay ISO strings. Payloads may therefore
   remain raw model JSON at enqueue time.
2. An offline sale must enqueue ALL effects together: the sale doc, the ledger doc
   (with `date`!), and `{'stockByLocation': …}` per affected product
   (`cart_provider.dart:436-457` is the reference implementation).
3. Known accepted risk: queued sales cannot validate stock server-side → over-selling
   across clients is possible while offline. Documented, accepted for now
   (Cloud Function reconciliation deferred — §9).
4. Queue order is FIFO by timestamp; one failed item stops the drain (`sync_service.dart:74-91`)
   — keep it that way so later effects never land before earlier ones.

---

## 8. Translation Checklist — "a file changed on web, what do I do here?"

When a web file in the table's left column changes, walk the row:

| Web file changed | Flutter counterpart | Do |
| :--- | :--- | :--- |
| `src/types/sale.ts` | `lib/features/pos/data/models/sale_model.dart` | Diff field table §3.1; update model + regen (`build_runner`); update this guide |
| `src/types/inventory.ts` / `unit-system.ts` | `lib/features/inventory/data/models/product_model.dart` (+ unit models) | Diff §3.5/§6 |
| `src/types/transaction.ts` | `lib/core/models/transaction_model.dart` | Diff §3.4 |
| `src/hooks/use-sales.tsx` | `cart_provider.dart`, `sales_providers.dart` | Diff write shapes + transaction body (stock/ledger/balance) |
| `src/hooks/use-inventory.tsx` | `product_repository_impl.dart`, `inventory_providers.dart` | Diff write shapes, adjustment writes |
| `src/hooks/use-locations.tsx` | `location_repository_impl.dart` | Diff §3.6 |
| `src/hooks/use-transactions.tsx` | ledger reads in Flutter | Diff §3.4 |
| `src/app/(app)/sales/pos/page.tsx` | `pos_page.dart`, `cart_provider.dart` | Diff UX matrix (filtering, remaining stock, payment methods) |
| `src/lib/firebase-paths.ts` | path constants in repos | Diff §1 |
| `src/lib/date-utils.ts` / `firestore-utils.ts` | `datetime_converter.dart`, `firestore_service.dart` | Diff §2 |

For each changed field, answer: new/renamed/type-changed/default-changed?
Then: update canonical write → add read normalizer → update this guide's table →
add/extend emulator test → run the dual-client matrix (§10).

---

## 9. Deferred Work (tracked, not designed yet)

- **Usage limits / payment monitoring rework** — web calls `checkLimit('invoicing')` /
  `incrementUsage('invoicing', 1)` around sales (`use-sales.tsx:112-136,328-335`) and
  `checkLimit('inventory')` around products. Flutter deliberately does NOT mirror this
  until the planned payment-system redesign lands. Flutter-created sales therefore do not
  consume web quota — revisit at rework time.
- **Customer payments reconciliation** (`customerPayments` collection vs
  `'Customer Payment'` ledger entries) + installments + refunds (M7).
- **Receipt designer port (M10)** — Flutter renders the web `settings/receiptDesign`
  config read-only (bank details/notes/footers) but has no designer UI for it;
  the saving flow (new bank account → `savedBankAccounts`, dedupe by accountNumber)
  is web-only for now. Revisit with the business-type/module expansion.
- **Custom/service line items in Flutter POS (M8)** — Flutter tolerates and displays
  web-authored custom/service/fee lines (no stock math, survives approval round-trips)
  but has no UI to create them. The web's `/sales/add` invoice builder is the
  creation path for now.
- **Cloud Function reconciliation** for offline-queued stock effects.
- **Web bug backlog** (fix on web, don't mirror in Flutter): duplicate ledger creation
  (`use-sales.tsx:242-271`) — *fixed in M2*, `"bank transfer"` spacing (`pos/page.tsx:379`) — *fixed in M2*,
  `SalesApi.getSale` querying an `id` field the web never writes (`sales-api.ts:25-28`),
  `totalAmount` excluding tax/discount (§5).

---

## 10. Verification Protocol (every milestone gate)

1. `flutter analyze` clean; `dart run build_runner build` regen checked in.
2. **Emulator integration test** for the touched writer: seed fixture JSON → run the
   Flutter write → assert the resulting Firestore doc against a **golden JSON fixture**
   (canonical shape from this guide). Fixtures live in `test/fixtures/`.
3. **Dual-client matrix** on the staging business (`STAGING_BUSINESS_ID` in CI env):
   - Sale created in Flutter → visible & correct on web (sale detail, sales table,
     ledger, stock at the sale location).
   - Sale created on web → visible & correct in Flutter sales history.
   - Credit sale: customer balance consistent from both sides.
   - Offline sale (airplane mode) → reconnect → same assertions as above.
   - Approve/confirm payment flow from both sides.
4. No milestone ships with a "will fix later" in its own entity's table (§3).
   Divergences are either fixed or explicitly re-scoped to a later milestone in §9.
