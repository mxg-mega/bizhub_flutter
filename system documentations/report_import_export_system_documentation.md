# Data Ingestion & Extraction (Import/Export) System Documentation

## 1. Overview
The system provides a robust framework for bulk data operations, featuring an AI-assisted import wizard for external data (CSV/Excel) and a multi-format export engine for business reporting (PDF/CSV).

---

## 2. The AI-Powered Import Wizard

The Import Wizard (`src/components/shared/import-wizard`) is a multi-step state machine designed to handle structural mismatches between user files and the internal system schema.

### 2.1 The 4-Step Pipeline
1. **Upload (`UploadStep.tsx`)**: Accepts `.csv`, `.xlsx`, and `.xls` files. It uses `PapaParse` for CSV and `xlsx` for Excel parsing.
2. **Column Mapping (`ColumnMappingStep.tsx`)**:
   - **AI Assistance**: The system uses a fuzzy-matching and semantic analysis engine (`src/actions/column-mapping.ts`) to automatically suggest mappings (e.g., mapping a user's "Item Name" column to the system's "name" field).
   - **Manual Override**: Users can manually correct or ignore columns.
3. **Data Preview & Validation (`PreviewStep.tsx`)**:
   - Displays a grid of the mapped data.
   - Highlights validation errors (e.g., missing SKUs, invalid prices, or unrecognized units).
4. **Final Process (`ImportWizard.tsx`)**:
   - **Batching**: Large datasets are processed in batches of 100 to avoid Firestore timeout.
   - **Transaction Integrity**: Uses `writeBatch` to ensure that either the entire batch succeeds or fails.

### 2.2 Date & Unit Normalization
- **Date Detector**: `src/actions/date-format-detector.ts` automatically identifies common date formats (DD/MM/YYYY vs MM/DD/YYYY) to ensure expiration dates are parsed correctly.
- **Unit Mapper**: Normalizes units (e.g., "ctn", "CTN", "Carton") to the standard system unit codes using the `useUnitSystem` logic.

---

## 3. The Export Engine (Reports)

The reporting system extracts live Firestore data and transforms it into formatted documents.

### 3.1 Sales Reports
- **PDF Export**: Uses `jsPDF` and `jspdf-autotable`.
  - **Contents**: Header with business info, summary stats (Total Sales, Paid, Pending), and a detailed transaction table.
  - **Naming**: `sales_report_YYYY-MM-DD.pdf` (appends filters like `_paid` or `_pending`).
- **CSV Export**: Uses `PapaParse` to flatten complex `Sale` objects.
  - **Flattening Logic**: Sales items are unrolled so that each row in the CSV represents a single line item, with parent sale metadata (Invoice ID, Date) repeated for each row to facilitate Excel pivot table analysis.

### 3.2 Inventory Reports
- **PDF Export**: Focuses on "Stock Health".
  - **Features**: Highlights low-stock items (< 10 units) and upcoming expirations.
  - **Location Scoping**: Can generate reports filtered by a specific `locationId`.
- **CSV Export**: Provides a full schema backup of the `products` collection, compatible with the Import Wizard for bulk price/stock updates.

---

## 4. Technical Implementation Details

### 4.1 Libraries & Utilities
- **`jsPDF`**: Low-level PDF generation.
- **`jspdf-autotable`**: Handles table spanning, zebra-striping, and pagination in PDFs.
- **`PapaParse` / `xlsx`**: Robust file parsing and generation.
- **`date-fns`**: Ensures all report timestamps are localized and formatted consistently.

### 4.2 Data Transformation Logic
The system uses a "Flattening Strategy" before export:
1. **Fetch**: Retrieves data via `getDocs` with active filters (date, status, category).
2. **Transform**: Converts Firestore `Timestamp` objects to ISO strings and resolves foreign keys (e.g., replacing `customerId` with the customer's `name`).
3. **Render**: Passes the flattened array to the PDF/CSV generators.

---

## 5. Security & Performance Mandates
1. **Client-Side Generation**: All reports and imports are processed in the user's browser. This ensures that sensitive business data is never sent to a secondary "Export Server."
2. **Pagination Enforcement**: Large exports (> 1000 records) trigger a warning. Developers are encouraged to use date filters to keep report sizes manageable.
3. **Schema Versioning**: The Import Wizard checks the `unitSystemVersion`. If importing into a business with "Enhanced Units," it requires a `unitChain` mapping.
4. **Audit Logging**: Every successful import creates a system notification for the `Owner` and `Admin`, detailing the number of records added/updated.
