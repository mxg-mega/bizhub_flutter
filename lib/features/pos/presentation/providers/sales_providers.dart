import 'package:isar/isar.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/database/isar_service.dart';
import '../../../../core/services/sync_service.dart';
import '../../../../core/models/transaction_model.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../inventory/data/repositories/product_repository_impl.dart';
import '../../data/models/sale_model.dart';
import '../../data/repositories/pos_repository_impl.dart';
import '../../../inventory/domain/repositories/product_repository.dart';

part 'sales_providers.g.dart';

@riverpod
Future<List<SaleModel>> salesHistory(final SalesHistoryRef ref) {
  final businessId = ref.watch(currentBusinessProvider)?.id;
  if (businessId == null) return Future.value([]);
  return ref.watch(posRepositoryProvider).getSales(businessId);
}

@riverpod
class SaleActions extends _$SaleActions {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<void> checkout(final SaleModel sale) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final posRepo = ref.read(posRepositoryProvider);
      final productRepo = ref.read(productRepositoryProvider);
      final isar = ref.read(isarDatabaseProvider).value!;
      final syncService = ref.read(syncServiceProvider);

      // 1. Save Sale
      await posRepo.saveSale(sale);

      // 2. Update Inventory
      for (final item in sale.items) {
        final product = await productRepo.getProduct(sale.businessId, item.productId);
        if (product != null) {
          final Map<String, double> updatedStock = Map.from(product.stockByLocation);
          updatedStock[sale.locationId] = (updatedStock[sale.locationId] ?? 0.0) - item.quantity;
          await productRepo.updateStock(sale.businessId, product.id, updatedStock);
        }
      }

      // 3. Create Financial Transaction
      final transaction = TransactionModel(
        id: const Uuid().v4(),
        businessId: sale.businessId,
        type: 'income',
        amount: sale.total,
        category: FinancialCategory.revenue,
        timestamp: sale.timestamp,
        description: 'Sale #${sale.id.substring(0, 6)}',
        referenceId: sale.id,
        paymentMethod: sale.paymentMethod,
      );

      await isar.writeTxn(() async => await isar.transactionModels.put(transaction));
      await syncService.addToQueue(
        action: 'create',
        collectionPath: 'businesses/${sale.businessId}/transactions',
        docId: transaction.id,
        payload: transaction.toJson(),
      );
    });
  }

  Future<void> approveSale(final SaleModel sale) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final updatedSale = sale.copyWith(
        status: 'Paid',
        workflow: sale.workflow
      );
      await checkout(updatedSale);
    });
  }
}
