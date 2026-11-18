import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:biz_module/shared/models/business_model.dart';
import 'package:biz_module/core/services/firestore_service.dart';
import 'package:biz_module/features/pos/data/models/sale_item_model.dart';
import 'package:biz_module/features/pos/data/models/sale_model.dart';
import 'package:biz_module/features/inventory/data/models/product_model.dart';
import 'package:biz_module/shared/models/membership_model.dart';
import 'package:biz_module/shared/models/module_state_model.dart';
import 'package:biz_module/core/models/transaction_model.dart';
import 'package:biz_module/features/dashboard/data/models/expense_model.dart';
import 'package:biz_module/features/inventory/data/models/inventory_adjustment_model.dart';
import 'package:biz_module/features/payments/data/models/transfer_model.dart';
import 'package:biz_module/features/receipts/data/models/receipt_design_model.dart';

void main() {
  group('NextJS -> Flutter Deserialization Tests', () {
    test('NextJS Sale document deserializes cleanly into SaleModel', () {
      final nextJsSaleJson = <String, dynamic>{
        'id': 'sale_abc123',
        'customerId': 'cust_xyz789',
        'locationId': 'main_store',
        'date': '2025-10-18T19:30:00.000Z',
        'createdAt': Timestamp.fromDate(DateTime(2025, 10, 18, 19, 30)),
        'customer': 'Chinedu Okafor',
        'status': 'Paid',
        'items': [
          {
            'productId': 'prod_001',
            'name': 'Dangote Sugar 50kg',
            'category': 'Commodities',
            'quantity': 2.0,
            'unitPrice': 45000.0,
            'unitCost': 42000.0,
            'unit': 'bag',
          }
        ],
        'totalAmount': 90000.0,
        'subtotal': 90000.0,
        'tax': 0.0,
        'discount': 0.0,
        'paymentMethod': 'bank_transfer',
        'salesPerson': 'Staff A',
        'notes': 'Paid via transfer',
        'barcode': 'SALE-1729279800-ABC123',
      };

      final sale = SaleModel.fromJson(nextJsSaleJson);

      expect(sale.id, 'sale_abc123');
      expect(sale.date, DateTime.parse('2025-10-18T19:30:00.000Z'));
      expect(sale.totalAmount, 90000.0);
      expect(sale.total, 90000.0);
      expect(sale.customer, 'Chinedu Okafor');
      expect(sale.locationId, 'main_store');
      expect(sale.paymentMethod, 'bank_transfer');
      expect(sale.items.length, 1);
      expect(sale.items.first.totalPrice, 90000.0);
      expect(sale.barcode, 'SALE-1729279800-ABC123');

      // Verify serialization output produces camelCase compatible with NextJS
      final serialized = sale.toJson();
      expect(serialized['totalAmount'], 90000.0);
      expect(serialized['customerId'], 'cust_xyz789');
      expect(serialized['date'], '2025-10-18T19:30:00.000Z');
      expect(serialized.containsKey('timestamp'), isFalse);
      expect(serialized['locationId'], 'main_store');
      expect(serialized['paymentMethod'], 'bank_transfer');
    });

    test('Legacy Sale timestamp deserializes and is serialized as date', () {
      final sale = SaleModel.fromJson({
        'id': 'legacy_sale',
        'businessId': 'business_1',
        'userId': 'user_1',
        'timestamp': Timestamp.fromDate(DateTime(2025, 10, 18, 19, 30)),
        'subtotal': 10.0,
        'tax': 0.0,
        'discount': 0.0,
        'totalAmount': 10.0,
        'paymentMethod': 'cash',
        'locationId': 'main',
      });

      expect(sale.date, DateTime(2025, 10, 18, 19, 30));
      expect(sale.toJson().containsKey('timestamp'), isFalse);
      expect(sale.toJson()['date'], '2025-10-18T19:30:00.000');
    });

    test('NextJS Product document with unit prices deserializes cleanly', () {
      final nextJsProductJson = <String, dynamic>{
        'id': 'prod_cement',
        'name': 'Dangote Cement 50kg',
        'sku': 'CEM-50',
        'category': 'Building',
        'stockByLocation': {'main': 150.0, 'warehouse': 500.0},
        'cost': 8500.0,
        'price': 9200.0,
        'sellingUnit': 'bag',
        'purchaseUnit': 'pallet',
        'unitPrices': [
          {'unit': 'bag', 'price': 9200.0, 'isDefault': true},
          {'unit': 'truckload', 'price': 8900.0, 'isDefault': false},
        ],
        'isArchived': false,
        'updatedAt': Timestamp.fromDate(DateTime(2025, 10, 15)),
      };

      final product = ProductModel.fromJson(nextJsProductJson);

      expect(product.id, 'prod_cement');
      expect(product.name, 'Dangote Cement 50kg');
      expect(product.stockByLocation['main'], 150.0);
      expect(product.totalStock, 650.0);
      expect(product.price, 9200.0);
      expect(product.isArchived, false);
      expect(product.priceConfigs, isNotNull);
      expect(product.priceConfigs!.length, 2);
    });

    test('Legacy Product with flat stock number converts via JIT adapter', () {
      final legacyProductJson = <String, dynamic>{
        'id': 'legacy_prod_1',
        'name': 'Golden Penny Flour',
        'cost': 32000.0,
        'price': 35000.0,
        'stock': 25.0, // Legacy single number
      };

      final product = ProductModel.fromJson(legacyProductJson);

      expect(product.stockByLocation['main'], 25.0);
      expect(product.totalStock, 25.0);
    });

    test('NextJS User Membership subcollection document deserializes cleanly', () {
      final nextJsMembershipJson = <String, dynamic>{
        'id': 'biz_store_1',
        'name': 'Okafor Enterprises',
        'role': 'Owner',
      };

      final membership = MembershipModel.fromJson(nextJsMembershipJson);

      expect(membership.businessId, 'biz_store_1');
      expect(membership.businessName, 'Okafor Enterprises');
      expect(membership.roleId, 'Owner');
      expect(membership.status, 'active');
    });

    test('NextJS Expense document deserializes with Timestamp date', () {
      final nextJsExpenseJson = <String, dynamic>{
        'id': 'exp_999',
        'category': 'Utilities',
        'amount': 25000.0,
        'date': Timestamp.fromDate(DateTime(2025, 10, 20)),
        'description': 'Diesel for generator',
      };

      final expense = ExpenseModel.fromJson(nextJsExpenseJson);

      expect(expense.id, 'exp_999');
      expect(expense.category, 'Utilities');
      expect(expense.amount, 25000.0);
      expect(expense.description, 'Diesel for generator');
      expect(expense.date.year, 2025);
    });

    test('NextJS Transaction document with relatedEntityId maps to referenceId', () {
      final nextJsTransactionJson = <String, dynamic>{
        'id': 'txn_555',
        'date': Timestamp.fromDate(DateTime(2025, 10, 18)),
        'type': 'Sale',
        'amount': 90000.0,
        'description': 'Sale to Chinedu Okafor',
        'relatedEntityId': 'sale_abc123',
      };

      final txn = TransactionModel.fromJson(nextJsTransactionJson);

      expect(txn.id, 'txn_555');
      expect(txn.amount, 90000.0);
      expect(txn.referenceId, 'sale_abc123');
      expect(txn.category, FinancialCategory.revenue);
      // M2: ledger `date` is the web ordering field — must parse from Timestamp
      expect(txn.type, 'Sale');
      expect(txn.date, DateTime(2025, 10, 18));
    });

    test('NextJS rich module document schema deserializes and evaluates cleanly', () {
      final nextJsModulesDoc = <String, dynamic>{
        'analytics': {
          'enabled': true,
          'installedAt': Timestamp.fromDate(DateTime(2026, 11, 5, 21, 58, 48)),
          'installedBy': 'system',
          'lastUpdated': Timestamp.fromDate(DateTime(2026, 11, 5, 21, 58, 48)),
          'version': '1.0.0',
        },
        'pos': {
          'enabled': false,
          'installedAt': Timestamp.fromDate(DateTime(2026, 11, 5, 20, 0, 0)),
          'installedBy': 'user_123',
          'lastUpdated': Timestamp.fromDate(DateTime(2026, 11, 5, 22, 0, 0)),
          'version': '2.1.0',
          'previousVersion': '2.0.0',
          'isRollback': true,
          'metadata': {
            'autoUpdated': false,
            'requiresRestart': true,
          },
        },
      };

      // Test individual ModuleStateModel deserialization
      final analyticsState = ModuleStateModel.fromDynamic(nextJsModulesDoc['analytics']);
      expect(analyticsState.enabled, isTrue);
      expect(analyticsState.version, '1.0.0');
      expect(analyticsState.installedBy, 'system');
      expect(analyticsState.installedAt?.year, 2026);

      final posState = ModuleStateModel.fromDynamic(nextJsModulesDoc['pos']);
      expect(posState.enabled, isFalse);
      expect(posState.version, '2.1.0');
      expect(posState.previousVersion, '2.0.0');
      expect(posState.isRollback, isTrue);
      expect(posState.metadata?['requiresRestart'], isTrue);

      // Test isEnabled helper on both rich maps and legacy booleans
      expect(ModuleStateModel.isEnabled(nextJsModulesDoc['analytics']), isTrue);
      expect(ModuleStateModel.isEnabled(nextJsModulesDoc['pos']), isFalse);
      expect(ModuleStateModel.isEnabled(true), isTrue);
      expect(ModuleStateModel.isEnabled(false), isFalse);
      expect(ModuleStateModel.isEnabled('true'), isTrue);
      expect(ModuleStateModel.isEnabled(null), isFalse);

      // Test filtering enabled IDs
      final enabledIds = nextJsModulesDoc.entries
          .where((e) => ModuleStateModel.isEnabled(e.value))
          .map((e) => e.key)
          .toList();
      expect(enabledIds, ['analytics']);
    });

    test('BusinessModel with raw Timestamp in enabledModules/settings encodes safely to JSON', () {
      final businessWithTimestamps = BusinessModel(
        id: 'biz_123',
        name: 'Supermart',
        enabledModules: {
          'analytics': {
            'enabled': true,
            'installedAt': Timestamp.fromDate(DateTime(2026, 11, 5, 21, 58, 48)),
            'lastUpdated': Timestamp.fromDate(DateTime(2026, 11, 5, 21, 58, 48)),
          },
        },
        settings: {
          'lastSync': Timestamp.fromDate(DateTime(2026, 11, 5, 22, 0, 0)),
        },
        createdAt: DateTime(2026, 11, 5),
        updatedAt: DateTime(2026, 11, 5),
      );

      // Recursive sanitizer like AuthService._convertTimestamps
      dynamic convertTimestamps(dynamic value) {
        if (value is Timestamp) return value.toDate().toIso8601String();
        if (value is Map) {
          return value.map<String, dynamic>(
            (k, v) => MapEntry(k.toString(), convertTimestamps(v)),
          );
        }
        if (value is List) return value.map((e) => convertTimestamps(e)).toList();
        return value;
      }

      // Safe encoder
      final sanitized = convertTimestamps(businessWithTimestamps.toJson());
      final jsonString = jsonEncode(
        sanitized,
        toEncodable: (nonEncodable) {
          if (nonEncodable is Timestamp) return nonEncodable.toDate().toIso8601String();
          return nonEncodable.toString();
        },
      );

      expect(jsonString, isA<String>());
      expect(jsonString.contains('Supermart'), isTrue);
      expect(jsonString.contains('analytics'), isTrue);
      // Ensure decode succeeds
      final decoded = jsonDecode(jsonString);
      expect(decoded['id'], 'biz_123');
      expect(decoded['enabledModules']['analytics']['enabled'], isTrue);
    });
  });

  group('M1: Sale wire-format parity (docs/PORTING_GUIDE.md §3.1)', () {
    final now = DateTime(2026, 11, 16, 10, 30);

    SaleModel canonicalSale() => SaleModel(
          id: '0123456789abcdef0123456789abcdef',
          businessId: 'biz_1',
          userId: 'user_1',
          customerId: 'cust_1',
          customer: 'Chinedu Okafor',
          items: [
            const SaleItemModel(
              productId: 'p1',
              name: 'Item',
              quantity: 2,
              unit: 'pcs',
              unitPrice: 500,
              unitCost: 300,
              category: 'Goods',
            ),
          ],
          subtotal: 1000,
          tax: 100,
          taxRate: 10, // percentage, web contract
          discount: 50,
          discountType: 'fixed',
          totalAmount: 1000, // items sum, web contract (§5)
          paymentMethod: 'cash',
          status: 'Paid',
          date: now,
          createdAt: now,
          updatedAt: now,
          locationId: 'loc_1',
          workflowEnabled: true,
          workflowHistory: [
            SaleWorkflowStage(
              stage: 'Paid',
              performedBy: 'user_1',
              performedByName: 'Operator',
              performedAt: now,
              notes: 'Sale created',
            ),
          ],
          createdBy: 'user_1',
          createdByName: 'Operator',
          referenceNumber: 'INV-26111234',
          barcode: 'SALE-1763286600000-012345',
        );

    test('checkout payload sanitizes to the canonical Firestore shape', () {
      final doc = FirestoreService.sanitizeForFirestore(
        canonicalSale().toJson(),
        timestampFields: SaleModel.firestoreTimestampFields,
      );

      // `date` stays an ISO 8601 string (web contract, §2)
      expect(doc['date'], isA<String>());
      expect(DateTime.parse(doc['date'] as String), now);

      // `createdAt` / `updatedAt` become Firestore Timestamps
      expect(doc['createdAt'], Timestamp.fromDate(now));
      expect(doc['updatedAt'], Timestamp.fromDate(now));

      // Financial fields
      expect(doc['taxRate'], 10.0);
      expect(doc['discountType'], 'fixed');
      expect(doc['totalAmount'], 1000.0);

      // Flat web-contract workflow; legacy nested object never written
      expect(doc.containsKey('workflow'), isFalse);
      expect(doc['workflowEnabled'], true);
      final history = doc['workflowHistory'] as List<dynamic>;
      final stage = history.first as Map<dynamic, dynamic>;
      expect(stage['stage'], 'Paid');
      expect(stage['performedBy'], 'user_1');
      expect(stage['performedByName'], 'Operator');
      expect(stage['notes'], 'Sale created');
      // Nested `performedAt` converted to a Timestamp via the allowlist
      expect(stage['performedAt'], Timestamp.fromDate(now));

      // Audit + tracking fields
      expect(doc['createdBy'], 'user_1');
      expect(doc['createdByName'], 'Operator');
      expect(doc['referenceNumber'], 'INV-26111234');
      expect(doc['barcode'], 'SALE-1763286600000-012345');
      expect(doc['locationId'], 'loc_1');

      // No null values anywhere (merge:true would delete those fields)
      void assertNoNulls(final Map<dynamic, dynamic> map) {
        map.forEach((final k, final v) {
          expect(v, isNotNull, reason: 'null value for key "$k"');
          if (v is Map) assertNoNulls(v);
          if (v is List) {
            for (final e in v) {
              if (e is Map) assertNoNulls(e);
            }
          }
        });
      }

      assertNoNulls(doc);
    });

    test('legacy payment-method values normalize on read (§4)', () {
      for (final raw in ['bank transfer', 'Bank Transfer', 'transfer', 'bank_transfer']) {
        final sale = SaleModel.fromJson({
          'id': 's1',
          'date': '2025-10-18T19:30:00.000Z',
          'paymentMethod': raw,
          'totalAmount': 100.0,
          'subtotal': 100.0,
          'tax': 0.0,
          'discount': 0.0,
          'status': 'Paid',
        });
        expect(sale.paymentMethod, 'bank_transfer', reason: 'raw: $raw');
      }
    });

    test('missing status defaults by payment method (§4)', () {
      final credit = SaleModel.fromJson({
        'id': 's2',
        'date': '2025-10-18T19:30:00.000Z',
        'paymentMethod': 'on_credit',
        'totalAmount': 100.0,
        'subtotal': 100.0,
        'tax': 0.0,
        'discount': 0.0,
      });
      expect(credit.status, 'Pending');

      final paid = SaleModel.fromJson({
        'id': 's3',
        'date': '2025-10-18T19:30:00.000Z',
        'paymentMethod': 'cash',
        'totalAmount': 100.0,
        'subtotal': 100.0,
        'tax': 0.0,
        'discount': 0.0,
      });
      expect(paid.status, 'Paid');
    });

    test('legacy Flutter sale (nested workflow object) lifts into flat fields', () {
      final sale = SaleModel.fromJson({
        'id': 'legacy_1',
        'date': '2025-10-18T19:30:00.000Z',
        'paymentMethod': 'cash',
        'totalAmount': 100.0,
        'subtotal': 100.0,
        'tax': 0.0,
        'discount': 0.0,
        'workflow': {
          'enabled': true,
          'createdBy': 'u1',
          'createdByName': 'Op',
          'history': [
            {
              'status': 'Paid',
              'actorId': 'u1',
              'createdAt': '2025-10-18T19:30:00.000Z',
              'notes': 'Sale created',
            },
          ],
        },
      });

      expect(sale.workflowEnabled, isTrue);
      expect(sale.createdBy, 'u1');
      expect(sale.createdByName, 'Op');
      expect(sale.workflowHistory, isNotNull);
      expect(sale.workflowHistory!.first.stage, 'Paid');
      expect(sale.workflowHistory!.first.performedBy, 'u1');
      // And the legacy object is never written back out.
      expect(sale.toJson().containsKey('workflow'), isFalse);
    });

    test('web-authored sale (flat workflowHistory, transferDetails) parses', () {
      final sale = SaleModel.fromJson({
        'id': 'web_1',
        'date': '2025-10-18T19:30:00.000Z',
        'paymentMethod': 'bank_transfer',
        'totalAmount': 90000.0,
        'subtotal': 90000.0,
        'tax': 0.0,
        'discount': 0.0,
        'taxRate': 10,
        'discountType': 'percentage',
        'status': 'Paid',
        'updatedAt': Timestamp.fromDate(DateTime(2025, 10, 18, 20, 0)),
        'createdBy': 'u9',
        'createdByName': 'Web Op',
        'workflowEnabled': true,
        'workflowHistory': [
          {
            'stage': 'Paid',
            'performedBy': 'u9',
            'performedByName': 'Web Op',
            'performedAt': Timestamp.fromDate(DateTime(2025, 10, 18, 19, 30)),
            'notes': 'n',
          },
        ],
        'transferDetails': {
          'transferFee': 100,
          'bankName': 'GTB',
          'accountNumber': '1234567890',
          'routingNumber': '058',
          'status': 'pending',
        },
      });

      expect(sale.taxRate, 10.0);
      expect(sale.discountType, 'percentage');
      expect(sale.updatedAt, DateTime(2025, 10, 18, 20, 0));
      expect(sale.workflowHistory!.first.performedByName, 'Web Op');
      expect(sale.workflowHistory!.first.performedAt,
          DateTime(2025, 10, 18, 19, 30));
      expect(sale.transferDetails, isNotNull);
      expect(sale.transferDetails!.bankName, 'GTB');
      expect(sale.transferDetails!.transferFee, 100.0);
      expect(sale.transferDetails!.status, 'pending');
    });

    test('copyWith carries canonical fields forward (no silent resets)', () {
      final updated = canonicalSale().copyWith(status: 'PendingPayment');
      expect(updated.taxRate, 10.0);
      expect(updated.discountType, 'fixed');
      expect(updated.workflowEnabled, isTrue);
      expect(updated.workflowHistory!.first.stage, 'Paid');
      expect(updated.createdBy, 'user_1');
      expect(updated.referenceNumber, 'INV-26111234');
      expect(updated.barcode, 'SALE-1763286600000-012345');
      expect(updated.status, 'PendingPayment');
    });
  });

  group('M2: Ledger (TransactionModel) wire parity (docs/PORTING_GUIDE.md §3.4)', () {
    final now = DateTime(2026, 11, 16, 10, 30);

    test('normalizeType maps legacy/misspelled values to canonical (§4)', () {
      expect(TransactionModel.normalizeType('income'), 'Sale');
      expect(TransactionModel.normalizeType('sale'), 'Sale');
      expect(TransactionModel.normalizeType('Sale'), 'Sale');
      expect(TransactionModel.normalizeType('expense'), 'Expense');
      expect(TransactionModel.normalizeType('Expenses'), 'Expense');
      expect(TransactionModel.normalizeType('customer payment'), 'Customer Payment');
      expect(TransactionModel.normalizeType('Refund'), 'Refund');
      expect(TransactionModel.normalizeType('adjustment'), 'Adjustment');
      expect(TransactionModel.normalizeType('transfer'), 'Transfer');
      expect(TransactionModel.normalizeType(null), 'Sale');
      expect(TransactionModel.normalizeType('  '), 'Sale');
    });

    test('legacy Flutter ledger doc (type "income", no date) parses canonically', () {
      final txn = TransactionModel.fromJson({
        'id': 'txn_legacy',
        'type': 'income',
        'amount': 5000.0,
        'timestamp': '2025-09-01T09:00:00.000Z',
        'description': 'Sale #abc123',
        'relatedEntityId': 'sale_abc123',
      });

      expect(txn.type, 'Sale');
      expect(txn.category, FinancialCategory.revenue);
      // `date` fell back to createdAt (doc was invisible on web either way)
      expect(txn.date, DateTime.parse('2025-09-01T09:00:00.000Z'));
      expect(txn.createdAt, DateTime.parse('2025-09-01T09:00:00.000Z'));
    });

    test('expense ledger doc normalizes and infers opex', () {
      final txn = TransactionModel.fromJson({
        'id': 'txn_exp',
        'type': 'expenses',
        'amount': 12000.0,
        'date': Timestamp.fromDate(DateTime(2025, 10, 20)),
        'description': 'Rent',
      });

      expect(txn.type, 'Expense');
      expect(txn.category, FinancialCategory.opex);
      expect(txn.date, DateTime(2025, 10, 20));
    });

    test('Flutter-authored ledger sanitizes to the canonical Firestore shape', () {
      final txn = TransactionModel(
        id: 'txn_new',
        businessId: 'biz_1',
        type: 'Sale',
        amount: 1000.0,
        category: FinancialCategory.revenue,
        createdAt: now,
        date: now,
        description: 'Sale to Chinedu Okafor',
        referenceId: 'sale_1',
        paymentMethod: 'cash',
      );

      final doc = FirestoreService.sanitizeForFirestore(
        txn.toJson(),
        timestampFields: TransactionModel.firestoreTimestampFields,
      );

      // Ordering fields are Timestamps on the wire (web `orderBy('date')`)
      expect(doc['date'], Timestamp.fromDate(now));
      expect(doc['createdAt'], Timestamp.fromDate(now));
      expect(doc['type'], 'Sale');
      expect(doc['amount'], 1000.0);
      expect(doc['description'], 'Sale to Chinedu Okafor');
      expect(doc['relatedEntityId'], 'sale_1');

      // No nulls (merge:true would delete those fields)
      doc.forEach((final k, final v) => expect(v, isNotNull, reason: 'null for "$k"'));
    });
  });

  group('M3: InventoryAdjustment web shape (docs/PORTING_GUIDE.md §3.6)', () {
    test('adjustment doc: type constant, ISO timestamp, productName/notes', () {
      final adjustment = InventoryAdjustmentModel(
        id: 'adj_1',
        productId: 'p1',
        productName: 'Laundry Detergent',
        type: 'adjustment',
        kind: 'sale',
        changes: {
          'loc_1': {'old': 10.0, 'new': 8.0},
        },
        timestamp: DateTime(2026, 11, 16, 10, 30),
        userId: 'user_1',
        reason: 'POS Sale #abc123',
        notes: 'POS Sale #abc123',
      );

      // Empty allowlist = pure null-strip: `timestamp` must survive as an
      // ISO string (web parses it with `new Date`) — the legacy substring
      // heuristic would Timestamp-ify it and break web rendering.
      final doc = FirestoreService.sanitizeForFirestore(
        adjustment.toJson(),
        timestampFields: InventoryAdjustmentModel.firestoreTimestampFields,
      );

      expect(doc['type'], 'adjustment');
      expect(doc['kind'], 'sale');
      expect(doc['productName'], 'Laundry Detergent');
      expect(doc['notes'], 'POS Sale #abc123');
      expect(doc['timestamp'], '2026-11-16T10:30:00.000');
      expect(doc['userId'], 'user_1');
      final changes = doc['changes'] as Map<dynamic, dynamic>;
      final loc = changes['loc_1'] as Map<dynamic, dynamic>;
      expect(loc['old'], 10.0);
      expect(loc['new'], 8.0);

      doc.forEach((final k, final v) => expect(v, isNotNull, reason: 'null for "$k"'));
    });

    test('web adjustment doc parses (timestamp ISO string, no kind)', () {
      final adjustment = InventoryAdjustmentModel.fromJson({
        'id': 'adj_web',
        'productId': 'p2',
        'productName': 'Soap',
        'type': 'adjustment',
        'changes': {
          'main': {'old': 5.0, 'new': 3.0},
        },
        'timestamp': '2025-10-18T19:30:00.000Z',
        'userId': 'u9',
        'notes': 'Stock level adjustment',
      });

      expect(adjustment.type, 'adjustment');
      expect(adjustment.productName, 'Soap');
      expect(adjustment.timestamp, DateTime.parse('2025-10-18T19:30:00.000Z'));
      expect(adjustment.notes, 'Stock level adjustment');
      expect(adjustment.kind, isNull);
    });
  });

  group('M4: Product wire parity (docs/PORTING_GUIDE.md §3.5)', () {
    test('write: conversionFactor derived, stock stripped, expirationDate yyyy-MM-dd', () {
      final updated = DateTime(2026, 11, 16, 10, 30);
      final product = ProductModel.fromJson({
        'id': 'p_legacy',
        'name': 'Detergent',
        'cost': 300.0,
        'price': 500.0,
        'stock': 42.0, // legacy denormalized total — must never be written back
        'stockByLocation': {'main': 42.0},
        'expirationDate': '2026-01-31',
        'updatedAt': Timestamp.fromDate(updated),
        'unitChain': {
          'baseUnit': 'Piece',
          'units': ['Carton', 'Piece'],
          'conversions': [
            {'from': 'Carton', 'to': 'Piece', 'factor': 50},
          ],
        },
        'purchaseUnit': 'Carton',
        'sellingUnit': 'Piece',
      });

      // conversionFactor derived from the unit chain (Carton → Piece = 50)
      expect(product.conversionFactor, 50.0);

      final doc = FirestoreService.sanitizeForFirestore(
        product.toJson(),
        timestampFields: ProductModel.firestoreTimestampFields,
      );

      // Web restock computes qty × conversionFactor — must never be undefined
      expect(doc['conversionFactor'], 50.0);
      // Computed stock is never persisted
      expect(doc.containsKey('stock'), isFalse);
      // Required strings written as '' rather than null/absent
      expect(doc['sku'], '');
      expect(doc['category'], '');
      expect(doc['sellingUnit'], 'Piece');
      expect(doc['purchaseUnit'], 'Carton');
      // expirationDate stays a date-only string
      expect(doc['expirationDate'], '2026-01-31');
      // updatedAt is a Timestamp
      expect(doc['updatedAt'], Timestamp.fromDate(updated));
    });

    test('legacy full-ISO expirationDate parses and rounds to date-only', () {
      final product = ProductModel.fromJson({
        'id': 'p_iso',
        'name': 'Soap',
        'expirationDate': '2026-03-15T14:22:01.000Z',
      });
      expect(product.expirationDate!.year, 2026);
      expect(product.expirationDate!.month, 3);
      expect(product.expirationDate!.day, 15);
      // And re-writing normalizes to yyyy-MM-dd
      expect(product.toJson()['expirationDate'], isA<String>());
      expect(
        (product.toJson()['expirationDate'] as String).length,
        10,
      );
    });

    test('web product parses (conversionFactor, audit trail, soft delete)', () {
      final archivedAt = Timestamp.fromDate(DateTime(2026, 11, 1, 9, 0));
      final product = ProductModel.fromJson({
        'id': 'p_web',
        'name': 'Milk',
        'sku': 'MLK-001',
        'category': 'Dairy',
        'conversionFactor': 12,
        'purchaseUnit': 'Carton',
        'sellingUnit': 'Piece',
        'expirationDate': '2025-12-31',
        'unitSystemVersion': 'enhanced',
        'archivedAt': archivedAt,
        'archivedBy': 'u9',
        'archivedByName': 'Web Op',
        'archivedReason': 'Discontinued',
        'createdBy': 'u9',
        'createdByName': 'Web Op',
        'lastModifiedBy': 'u8',
        'lastModifiedByName': 'Manager',
        'unitChainTemplate': 'pieces',
        'bagUnit': {'piecesPerBag': 10, 'pricingType': 'fixed'},
      });

      expect(product.conversionFactor, 12.0);
      expect(product.expirationDate, DateTime(2025, 12, 31));
      expect(product.archivedAt, DateTime(2026, 11, 1, 9, 0));
      expect(product.archivedByName, 'Web Op');
      expect(product.createdBy, 'u9');
      expect(product.lastModifiedByName, 'Manager');
      expect(product.unitChainTemplate, 'pieces');
      expect(product.bagUnit, isNotNull);
      expect(product.sku, 'MLK-001');
      expect(product.category, 'Dairy');
    });
  });

  group('M7: Customer Payment wire parity (docs/PORTING_GUIDE.md §3.8)', () {
    final now = DateTime(2026, 11, 16, 10, 30);

    test('Customer Payment ledger sanitizes to the canonical shape', () {
      final ledger = TransactionModel(
        id: 'txn_pay',
        businessId: 'biz_1',
        type: 'Customer Payment',
        amount: 4000.0,
        category: FinancialCategory.revenue,
        createdAt: now,
        date: now,
        description: 'Payment from Chinedu Okafor \u2014 balance part 2',
        referenceId: 'cust_1',
        paymentMethod: 'cash',
        performedBy: 'user_1',
        performedByName: 'Operator',
      );

      final doc = FirestoreService.sanitizeForFirestore(
        ledger.toJson(),
        timestampFields: TransactionModel.firestoreTimestampFields,
      );

      expect(doc['type'], 'Customer Payment');
      expect(doc['date'], Timestamp.fromDate(now));
      expect(doc['createdAt'], Timestamp.fromDate(now));
      expect(doc['amount'], 4000.0);
      expect(doc['description'], 'Payment from Chinedu Okafor \u2014 balance part 2');
      expect(doc['relatedEntityId'], 'cust_1');
      expect(doc['performedBy'], 'user_1');

      doc.forEach((final k, final v) => expect(v, isNotNull, reason: 'null for "$k"'));
    });

    test('FIFO settlement: full settles status, partial keeps Pending', () {
      final sale = SaleModel.fromJson({
        'id': 's_credit',
        'date': '2025-10-18T19:30:00.000Z',
        'paymentMethod': 'on_credit',
        'totalAmount': 1000.0,
        'subtotal': 1000.0,
        'tax': 0.0,
        'discount': 0.0,
        'status': 'Pending',
        'amountPaid': 400.0,
      });
      expect(sale.status, 'Pending');
      expect(sale.amountPaid, 400.0);

      // Fully covered → 'Paid' with amountPaid = totalAmount (web shape)
      final settled = sale.copyWith(
        amountPaid: sale.totalAmount,
        status: 'Paid',
        updatedAt: now,
      );
      expect(settled.status, 'Paid');
      expect(settled.amountPaid, 1000.0);

      // Partially covered → status stays 'Pending', amountPaid grows
      final partial = sale.copyWith(amountPaid: 700.0, status: sale.status);
      expect(partial.status, 'Pending');
      expect(partial.amountPaid, 700.0);
      expect(partial.totalAmount - (partial.amountPaid ?? 0.0), 300.0);
    });
  });

  group('M8: SaleItem type/custom tolerance (docs/PORTING_GUIDE.md §3.3)', () {
    test('web service/fee/custom items parse and are excluded from stock math', () {
      final product = SaleItemModel.fromJson({
        'productId': 'prod_1',
        'name': 'Sugar 50kg',
        'quantity': 2,
        'unit': 'Piece',
        'unitPrice': 500.0,
        'category': 'Commodities',
        'itemType': 'product',
        'isCustom': false,
      });
      final service = SaleItemModel.fromJson({
        'productId': 'custom_delivery',
        'name': 'Delivery fee',
        'description': 'Door delivery within Lagos',
        'quantity': 1,
        'unit': 'service',
        'unitPrice': 1500.0,
        'itemType': 'fee',
        'isCustom': true,
      });

      expect(product.isInventory, isTrue);
      expect(service.isInventory, isFalse);
      expect(service.description, 'Door delivery within Lagos');
      expect(service.itemType, 'fee');
      expect(service.isCustom, isTrue);

      final inventoryIds = [product, service]
          .where((final i) => i.isInventory)
          .map((final i) => i.productId)
          .toList();
      expect(inventoryIds, ['prod_1']);
    });

    test('isInventory guard mirrors the web isInventoryProduct rules', () {
      SaleItemModel item({
        String productId = 'prod_1',
        String? itemType,
        bool? isCustom,
      }) =>
          SaleItemModel(
            productId: productId,
            name: 'x',
            quantity: 1,
            unit: 'Piece',
            unitPrice: 1,
            itemType: itemType,
            isCustom: isCustom,
          );

      expect(item().isInventory, isTrue);
      expect(item(itemType: 'product').isInventory, isTrue);
      expect(item(itemType: 'service').isInventory, isFalse);
      expect(item(itemType: 'fee').isInventory, isFalse);
      expect(item(itemType: 'custom').isInventory, isFalse);
      expect(item(isCustom: true).isInventory, isFalse);
      expect(item(productId: 'custom_charge').isInventory, isFalse);
      expect(item(productId: '').isInventory, isFalse);
    });

    test('new item fields survive the wire round-trip and sanitizer', () {
      final item = SaleItemModel(
        productId: 'custom_consulting',
        name: 'Consulting',
        description: 'Hourly consulting',
        quantity: 1,
        unit: 'hour',
        unitPrice: 10000,
        category: 'Services',
        itemType: 'service',
        isCustom: true,
      );

      final doc = FirestoreService.sanitizeForFirestore(<String, dynamic>{
        'items': [item.toJson()],
      });
      final wireItem = (doc['items'] as List).first as Map<String, dynamic>;

      expect(wireItem['description'], 'Hourly consulting');
      expect(wireItem['itemType'], 'service');
      expect(wireItem['isCustom'], true);
      // Absent optional fields are stripped, not written as null.
      expect(wireItem.containsKey('unitCost'), isFalse);
    });

    test('transferDetails.accountName round-trips to the wire shape', () {
      final sale = SaleModel.fromJson({
        'id': 's_bank',
        'date': '2025-10-18T19:30:00.000Z',
        'paymentMethod': 'bank_transfer',
        'status': 'Paid',
        'totalAmount': 100.0,
        'subtotal': 100.0,
        'tax': 0.0,
        'discount': 0.0,
        'transferDetails': {
          'bankName': 'Zenith Bank',
          'accountName': 'Bizmod Ltd',
          'accountNumber': '0123456789',
          'routingNumber': '057',
          'transferFee': 50.0,
          'status': 'pending',
        },
      });

      expect(sale.transferDetails?.accountName, 'Bizmod Ltd');
      final doc = FirestoreService.sanitizeForFirestore(
        sale.toJson(),
        timestampFields: SaleModel.firestoreTimestampFields,
      );
      final details = doc['transferDetails'] as Map<String, dynamic>;
      expect(details['accountName'], 'Bizmod Ltd');
    });
  });

  group('M9: Transfers + receipt design consistency (docs/PORTING_GUIDE.md §3.9)', () {
    final createdAt = DateTime(2026, 11, 16, 9, 15);
    final updatedAt = DateTime(2026, 11, 16, 9, 20);

    test('web transfer doc parses (Timestamps, accountName, status)', () {
      final transfer = TransferModel.fromJson({
        'id': 'tr_1',
        'businessId': 'biz_1',
        'saleId': 'sale_1',
        'customerId': 'cust_1',
        'customerName': 'Chinedu Okafor',
        'amount': 25000.0,
        'transferFee': 100.0,
        'bankName': 'Zenith Bank',
        'accountName': 'Chinedu Okafor',
        'accountNumber': '0123456789',
        'routingNumber': '057',
        'status': 'pending',
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      });

      expect(transfer.saleId, 'sale_1');
      expect(transfer.accountName, 'Chinedu Okafor');
      expect(transfer.status, 'pending');
      expect(transfer.createdAt, createdAt);
      expect(transfer.isTerminal, isFalse);
      expect(TransferModel.statuses, contains('cancelled'));
    });

    test('Flutter transfer sanitizes to the canonical Firestore shape', () {
      final transfer = TransferModel(
        id: 'tr_2',
        businessId: 'biz_1',
        saleId: 'sale_2',
        customerName: 'Walk-in Customer',
        amount: 5000.0,
        transferFee: 0.0,
        bankName: 'GTBank',
        status: 'completed',
        createdAt: createdAt,
        updatedAt: updatedAt,
        processedAt: updatedAt,
      );

      final doc = FirestoreService.sanitizeForFirestore(
        transfer.toJson(),
        timestampFields: TransferModel.firestoreTimestampFields,
      );

      expect(doc['createdAt'], Timestamp.fromDate(createdAt));
      expect(doc['updatedAt'], Timestamp.fromDate(updatedAt));
      expect(doc['processedAt'], Timestamp.fromDate(updatedAt));
      expect(doc['status'], 'completed');
      expect(doc['amount'], 5000.0);
      expect(transfer.isTerminal, isTrue);
      // Null optional fields are stripped.
      expect(doc.containsKey('accountNumber'), isFalse);
      expect(doc.containsKey('notes'), isFalse);
    });

    test('sync service maps the transfers collection to Timestamp fields', () {
      // Same contract consumed by SyncService._timestampFieldsForPath.
      expect(
        TransferModel.firestoreTimestampFields,
        {'createdAt', 'updatedAt', 'processedAt'},
      );
    });

    test('receipt design merges primary + saved bank accounts (deduped)', () {
      final design = ReceiptDesignModel.fromJson({
        'template': 'classic',
        'accentColor': '#123456',
        'bankDetails': {
          'bankName': 'Zenith Bank',
          'accountName': 'Bizmod Ltd',
          'accountNumber': '0123456789',
        },
        'savedBankAccounts': [
          {
            'bankName': 'Zenith Bank',
            'accountName': 'Bizmod Ltd',
            'accountNumber': '0123456789',
            'label': 'Zenith — ****6789',
          },
          {
            'bankName': 'GTBank',
            'accountName': 'Bizmod Ltd',
            'accountNumber': '9876543210',
          },
          {
            'bankName': '',
            'accountNumber': '',
          },
        ],
        'notesAndTerms': 'Payment due within 14 days.',
        'showPaymentDetails': true,
      });

      expect(design.template, 'classic');
      expect(design.accentColor, '#123456');
      expect(design.notesAndTerms, 'Payment due within 14 days.');
      final accounts = design.unifiedBankAccounts;
      expect(accounts.length, 2);
      expect(accounts.first.accountNumber, '0123456789');
      expect(accounts.last.bankName, 'GTBank');
    });
  });
}
