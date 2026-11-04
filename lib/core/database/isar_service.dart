import 'dart:convert';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/inventory/data/models/product_model.dart';
import '../../features/inventory/data/models/location_model.dart';
import '../../features/inventory/data/models/supplier_model.dart';
import '../../features/inventory/data/models/stock_in_model.dart';
import '../../features/pos/data/models/sale_model.dart';
import '../../features/pos/data/models/customer_payment_model.dart';
import '../../features/dashboard/data/models/expense_model.dart';
import '../../features/dashboard/data/models/invitation_model.dart';
import '../../features/receipts/data/models/receipt_template_model.dart';
import '../models/transaction_model.dart';
import 'local_models.dart';
import '../models/sync_queue_model.dart';

part 'isar_service.g.dart';

@Riverpod(keepAlive: true)
Future<Isar> isarDatabase(final IsarDatabaseRef ref) async {
  final dir = await getApplicationDocumentsDirectory();
  return await Isar.open(
    [
      LocalProductSchema,
      LocalLocationSchema,
      LocalSaleSchema,
      LocalCustomerSchema,
      TransactionModelSchema,
      ExpenseModelSchema,
      SupplierModelSchema,
      StockInModelSchema,
      InvitationModelSchema,
      ReceiptTemplateModelSchema,
      CustomerPaymentModelSchema,
      SyncQueueModelSchema,
    ],
    directory: dir.path,
  );
}

class IsarService {
  final Isar _isar;

  IsarService(this._isar);

  Isar get db => _isar;

  // Inventory Helpers
  Future<void> saveProduct(final String businessId, final ProductModel product) async {
    final local = LocalProduct(
      id: product.id,
      name: product.name,
      sku: product.sku,
      businessId: businessId,
      isArchived: product.isArchived,
      data: jsonEncode(product.toJson()),
    );
    await _isar.writeTxn(() async => await _isar.localProducts.put(local));
  }

  Future<List<ProductModel>> getProducts(final String businessId) async {
    final locals = await _isar.localProducts
        .where()
        .filter()
        .businessIdEqualTo(businessId)
        .and()
        .isArchivedEqualTo(false)
        .findAll();
    
    return locals.map((final l) => ProductModel.fromJson(jsonDecode(l.data))).toList();
  }

  Future<void> saveLocation(final String businessId, final LocationModel location) async {
    final local = LocalLocation(
      id: location.id,
      name: location.name,
      businessId: businessId,
      data: jsonEncode(location.toJson()),
    );
    await _isar.writeTxn(() async => await _isar.localLocations.put(local));
  }

  Future<List<LocationModel>> getLocations(final String businessId) async {
    final locals = await _isar.localLocations
        .where()
        .filter()
        .businessIdEqualTo(businessId)
        .findAll();
    
    return locals.map((final l) => LocationModel.fromJson(jsonDecode(l.data))).toList();
  }

  // POS Helpers
  Future<void> saveSale(final SaleModel sale) async {
    final local = LocalSale(
      id: sale.id,
      businessId: sale.businessId,
      timestamp: sale.timestamp,
      total: sale.total,
      data: jsonEncode(sale.toJson()),
    );
    await _isar.writeTxn(() async => await _isar.localSales.put(local));
  }

  Future<List<SaleModel>> getSales(final String businessId) async {
    final locals = await _isar.localSales
        .where()
        .filter()
        .businessIdEqualTo(businessId)
        .sortByTimestampDesc()
        .findAll();
    return locals.map((final l) => SaleModel.fromJson(jsonDecode(l.data))).toList();
  }
}
