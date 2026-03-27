import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/database/isar_service.dart';
import '../../../../core/services/sync_service.dart';
import '../../../../core/models/transaction_model.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../models/stock_in_model.dart';
import 'product_repository_impl.dart';
import 'supplier_repository_impl.dart';

part 'stock_in_repository_impl.g.dart';

@riverpod
class StockInActions extends _$StockInActions {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<void> performStockIn(final StockInModel stockIn) async {
    final auth = ref.read(authProvider);
    final businessId = auth.activeBusiness?.id;
    if (businessId == null) return;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final isar = ref.read(isarDatabaseProvider).value!;
      final syncService = ref.read(syncServiceProvider);
      final productRepo = ref.read(productRepositoryProvider);
      final supplierRepo = ref.read(supplierRepositoryProvider);

      // 1. Save StockIn record locally
      await isar.writeTxn(() async => await isar.stockInModels.put(stockIn));
      await syncService.addToQueue(
        action: 'create',
        collectionPath: 'businesses/$businessId/stockIn',
        docId: stockIn.id,
        payload: stockIn.toJson(),
      );

      // 2. Update Product Inventory
      for (final item in stockIn.items) {
        final product = await productRepo.getProduct(businessId, item.productId);
        if (product == null) continue;

        // Convert quantity to base unit
        double delta = item.quantity;
        if (product.unitChain != null) {
          final factor = product.unitChain!.getFactor(item.unit, product.unitChain!.baseUnit ?? '');
          delta = item.quantity * factor;
        }

        final Map<String, double> updatedStock = Map.from(product.stockByLocation);
        updatedStock[stockIn.locationId] = (updatedStock[stockIn.locationId] ?? 0.0) + delta;
        
        await productRepo.updateStock(businessId, item.productId, updatedStock);
      }

      // 3. Update Supplier Balance if NOT paid (On Credit purchase)
      if (!stockIn.isPaid) {
        await supplierRepo.updateBalance(stockIn.supplierId, stockIn.totalCost);
      }

      // 4. Log Financial Transaction (COGS)
      final tx = TransactionModel(
        id: const Uuid().v4(),
        businessId: businessId,
        type: 'expense',
        amount: stockIn.totalCost,
        category: FinancialCategory.cogs,
        timestamp: stockIn.timestamp,
        description: 'Restock from ${stockIn.supplierName}',
        referenceId: stockIn.id,
      );
      
      await isar.writeTxn(() async => await isar.transactionModels.put(tx));
      await syncService.addToQueue(
        action: 'create',
        collectionPath: 'businesses/$businessId/transactions',
        docId: tx.id,
        payload: tx.toJson(),
      );
    });
  }
}
