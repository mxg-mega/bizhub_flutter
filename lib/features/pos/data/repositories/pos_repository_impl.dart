import 'dart:convert';
import 'package:isar/isar.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/database/isar_service.dart';
import '../../../../core/database/local_models.dart';
import '../../../../core/services/sync_service.dart';
import '../../../inventory/data/models/product_model.dart';
import '../../domain/repositories/pos_repository.dart';
import '../models/sale_model.dart';

part 'pos_repository_impl.g.dart';

@riverpod
PosRepository posRepository(final PosRepositoryRef ref) {
  final isar = ref.watch(isarDatabaseProvider).value;
  final syncService = ref.watch(syncServiceProvider);
  if (isar == null) throw Exception('Isar not initialized');
  return PosRepositoryImpl(isar, syncService);
}

class PosRepositoryImpl implements PosRepository {
  final Isar _isar;
  final SyncService _syncService;

  PosRepositoryImpl(this._isar, this._syncService);

  String _getSalesPath(final String businessId) => 'businesses/$businessId/sales';
  String _getProductsPath(final String businessId) => 'businesses/$businessId/products';

  @override
  Stream<List<SaleModel>> watchSales(final String businessId) {
    // Background pull for sales from Firestore so multi-device & web sales sync down
    _syncService.pull<SaleModel>(
      businessId: businessId,
      collectionPath: _getSalesPath(businessId),
      fromJsons: (final jsons) =>
          jsons.map((final j) => SaleModel.fromJson(j)).toList(),
    );

    return _isar.localSales
        .where()
        .filter()
        .businessIdEqualTo(businessId)
        .sortByTimestampDesc()
        .watch(fireImmediately: true)
        .map((final locals) => locals
            .map((final l) => SaleModel.fromJson(jsonDecode(l.data)))
            .toList());
  }

  @override
  Future<void> saveSale(final SaleModel sale) async {
    final local = LocalSale(
      id: sale.id,
      businessId: sale.businessId,
      timestamp: sale.timestamp,
      total: sale.total,
      data: jsonEncode(sale.toJson()),
    );

    await _isar.writeTxn(() async {
      // 1. Save local sale record
      await _isar.localSales.put(local);

      // 2. Offline POS: Deduct product stock immediately in local Isar cache
      for (final item in sale.items) {
        final localProd = await _isar.localProducts
            .where()
            .idEqualTo(item.productId)
            .findFirst();

        if (localProd != null) {
          try {
            final prodMap = jsonDecode(localProd.data) as Map<String, dynamic>;
            final prod = ProductModel.fromJson(prodMap);
            final updatedStockByLoc = Map<String, double>.from(prod.stockByLocation);
            final currentStock = updatedStockByLoc[sale.locationId] ?? 0.0;
            updatedStockByLoc[sale.locationId] = (currentStock - item.quantity);

            final updatedProd = ProductModel(
              id: prod.id,
              name: prod.name,
              sku: prod.sku,
              description: prod.description,
              category: prod.category,
              cost: prod.cost,
              price: prod.price,
              stockByLocation: updatedStockByLoc,
              unitSystemVersion: prod.unitSystemVersion,
              unitChain: prod.unitChain,
              priceConfigs: prod.priceConfigs,
              isArchived: prod.isArchived,
              sellingUnit: prod.sellingUnit,
              purchaseUnit: prod.purchaseUnit,
              updatedAt: DateTime.now(),
              expirationDate: prod.expirationDate,
            );

            final updatedLocalProd = LocalProduct(
              id: updatedProd.id,
              name: updatedProd.name,
              sku: updatedProd.sku,
              businessId: sale.businessId,
              isArchived: updatedProd.isArchived,
              data: jsonEncode(updatedProd.toJson()),
            );

            await _isar.localProducts.put(updatedLocalProd);
          } catch (_) {
            // Keep going if one product parse fails
          }
        }
      }
    });

    // 3. Queue sale creation in sync queue for remote Firestore push
    await _syncService.addToQueue(
      action: 'create',
      collectionPath: _getSalesPath(sale.businessId),
      docId: sale.id,
      payload: sale.toJson(),
    );
  }

  @override
  Future<List<SaleModel>> getSales(final String businessId) async {
    final locals = await _isar.localSales
        .where()
        .filter()
        .businessIdEqualTo(businessId)
        .sortByTimestampDesc()
        .findAll();

    return locals
        .map((final l) => SaleModel.fromJson(jsonDecode(l.data)))
        .toList();
  }
}
