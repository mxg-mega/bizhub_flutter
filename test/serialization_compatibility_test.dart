import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:biz_module/features/pos/data/models/sale_model.dart';
import 'package:biz_module/features/inventory/data/models/product_model.dart';
import 'package:biz_module/shared/models/user_model.dart';
import 'package:biz_module/shared/models/membership_model.dart';
import 'package:biz_module/core/models/transaction_model.dart';
import 'package:biz_module/features/dashboard/data/models/expense_model.dart';

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
      expect(serialized['locationId'], 'main_store');
      expect(serialized['paymentMethod'], 'bank_transfer');
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
    });
  });
}
