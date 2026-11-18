import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart' hide Query;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/database/isar_service.dart';
import '../../../../core/database/local_models.dart';
import '../../../../core/models/transaction_model.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/services/sync_service.dart';
import '../../../../shared/providers/app_settings_provider.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../inventory/data/models/inventory_adjustment_model.dart';
import '../../../inventory/data/models/product_model.dart';
import '../../../inventory/data/repositories/product_repository_impl.dart';
import '../../data/models/sale_model.dart';
import '../../data/repositories/customer_repository_impl.dart';
import '../../data/repositories/pos_repository_impl.dart';

part 'sales_providers.g.dart';

@riverpod
Stream<List<SaleModel>> salesHistory(final SalesHistoryRef ref) {
  final businessId = ref.watch(currentBusinessProvider)?.id;
  if (businessId == null) return Stream.value([]);
  // Live Isar watch; each listen also triggers the Firestore pull, so sales
  // created on the web (or other devices) surface in the history page.
  // A one-shot `getSales` read never pulled — web sales were invisible.
  return ref.watch(posRepositoryProvider).watchSales(businessId);
}

@riverpod
class SaleActions extends _$SaleActions {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  /// Approves a sale — mirrors the web's `confirmPayment` flow
  /// (use-sales.tsx): stamps approval audit fields, deducts stock exactly
  /// once, writes exactly ONE ledger entry with
  /// `workflowStage: 'payment_confirmed'`, and grows the customer balance
  /// for credit sales (docs/PORTING_GUIDE.md §3.1/§3.4).
  Future<void> approveSale(final SaleModel sale) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final posRepo = ref.read(posRepositoryProvider);
      final isar = ref.read(isarDatabaseProvider).value!;
      final syncService = ref.read(syncServiceProvider);
      final user = ref.read(authProvider).user;
      if (user == null) throw Exception('Auth context missing');
      final actorName = user.name ?? 'Unknown';
      final now = DateTime.now();

      // Web confirmPayment derives the final status from the payment method:
      // credit sales stay 'Pending' until settled (use-sales.tsx:642).
      final finalStatus = sale.paymentMethod == 'on_credit' ? 'Pending' : 'Paid';
      // A sale that already completed a paid checkout must not be processed
      // again (double stock deduction / duplicate ledger).
      final alreadyProcessed = sale.status == 'Paid' || sale.status == 'Pending';

      final approvedSale = sale.copyWith(
        status: finalStatus,
        updatedAt: now,
        approvedBy: user.id,
        approvedByName: actorName,
        approvedAt: now,
      );

      final ledger = TransactionModel(
        id: const Uuid().v4(),
        businessId: sale.businessId,
        type: 'Sale',
        amount: sale.totalAmount,
        category: FinancialCategory.revenue,
        createdAt: now,
        date: now,
        description: 'Sale to ${sale.customer ?? 'Walk-in Customer'}',
        referenceId: sale.id,
        paymentMethod: sale.paymentMethod,
        performedBy: user.id,
        performedByName: actorName,
        workflowStage: 'payment_confirmed',
      );

      final isOffline = ref.read(appSettingsNotifierProvider).offlineModeEnabled;

      if (!isOffline && !alreadyProcessed) {
        try {
          final Map<String, ProductModel> updatedProducts = {};

          await FirestoreService.runTransaction((final txn) async {
            // 1. Deduct stock for every item (atomic read-validate-write).
            // Web parity: only inventory lines touch product docs — custom
            // charges/services/fees are skipped (`isInventoryProduct`, M8).
            for (final item in sale.items.where((final i) => i.isInventory)) {
              final productRef = FirestoreService.docIn(
                  'businesses/${sale.businessId}/products', item.productId);
              final snap = await txn.get(productRef);

              if (!snap.exists || snap.data() == null) {
                throw Exception('Product "${item.name}" not found in inventory');
              }

              final prodData = Map<String, dynamic>.from(snap.data()!);
              prodData['id'] = snap.id;
              final product = ProductModel.fromJson(prodData);

              double requestedQty = item.quantity;
              if (product.unitChain != null) {
                final factor = product.unitChain!
                    .getFactor(item.unit, product.unitChain!.baseUnit ?? '');
                requestedQty = item.quantity * factor;
              }

              final currentStock = product.stockByLocation[sale.locationId] ?? 0.0;
              if (currentStock < requestedQty) {
                throw Exception(
                    'Insufficient stock for "${product.name}". Available at location (${sale.locationId}): $currentStock, requested: $requestedQty');
              }

              final newStock = currentStock - requestedQty;
              final updatedStock = Map<String, double>.from(product.stockByLocation);
              updatedStock[sale.locationId] = newStock;
              txn.update(productRef, {
                'stockByLocation': updatedStock,
                'updatedAt': Timestamp.fromDate(DateTime.now()),
              });

              final updatedProd = ProductModel(
                id: product.id,
                name: product.name,
                sku: product.sku,
                description: product.description,
                category: product.category,
                cost: product.cost,
                price: product.price,
                stockByLocation: updatedStock,
                unitSystemVersion: product.unitSystemVersion,
                unitChain: product.unitChain,
                priceConfigs: product.priceConfigs,
                isArchived: product.isArchived,
                sellingUnit: product.sellingUnit,
                purchaseUnit: product.purchaseUnit,
                updatedAt: DateTime.now(),
                expirationDate: product.expirationDate,
              );
              updatedProducts[product.id] = updatedProd;

              // 2. Adjustment log — web shape (§3.6)
              final adjustmentId = const Uuid().v4();
              final adjustmentRef = FirestoreService.docIn(
                  'businesses/${sale.businessId}/inventoryAdjustments', adjustmentId);
              final adjustment = InventoryAdjustmentModel(
                id: adjustmentId,
                productId: product.id,
                productName: product.name,
                type: 'adjustment',
                kind: 'sale',
                changes: {
                  sale.locationId: {'old': currentStock, 'new': newStock},
                },
                timestamp: now,
                userId: user.id,
                notes: 'Sale approved by $actorName',
              );
              txn.set(
                adjustmentRef,
                FirestoreService.sanitizeForFirestore(
                  adjustment.toJson(),
                  timestampFields: InventoryAdjustmentModel.firestoreTimestampFields,
                ),
              );
            }

            // 3. Sale approval patch — full sanitized doc, merge keeps
            // anything the model doesn't know about
            txn.set(
              FirestoreService.docIn('businesses/${sale.businessId}/sales', sale.id),
              FirestoreService.sanitizeForFirestore(
                approvedSale.toJson(),
                timestampFields: SaleModel.firestoreTimestampFields,
              ),
              SetOptions(merge: true),
            );

            // 4. Exactly one ledger entry
            txn.set(
              FirestoreService.docIn(
                  'businesses/${sale.businessId}/transactions', ledger.id),
              FirestoreService.sanitizeForFirestore(
                ledger.toJson(),
                timestampFields: TransactionModel.firestoreTimestampFields,
              ),
            );
          });

          // 5. Update local Isar cache
          await isar.writeTxn(() async {
            await posRepo.saveSale(approvedSale);
            await isar.transactionModels.put(ledger);
            for (final prod in updatedProducts.values) {
              await isar.localProducts.put(
                LocalProduct(
                  id: prod.id,
                  name: prod.name,
                  sku: prod.sku,
                  businessId: sale.businessId,
                  isArchived: prod.isArchived,
                  data: jsonEncode(prod.toJson()),
                ),
              );
            }
          });
        } catch (e) {
          rethrow;
        }
      } else {
        // OFFLINE / already-processed path: update local cache and queue.
        await posRepo.saveSale(approvedSale);

        if (!alreadyProcessed) {
          for (final item in sale.items.where((final i) => i.isInventory)) {
            final product = await ref
                .read(productRepositoryProvider)
                .getProduct(sale.businessId, item.productId);
            if (product == null) continue;
            double requestedQty = item.quantity;
            if (product.unitChain != null) {
              final factor = product.unitChain!
                  .getFactor(item.unit, product.unitChain!.baseUnit ?? '');
              requestedQty = item.quantity * factor;
            }
            final updatedStock = Map<String, double>.from(product.stockByLocation);
            updatedStock[sale.locationId] =
                (updatedStock[sale.locationId] ?? 0.0) - requestedQty;
            await ref.read(productRepositoryProvider).updateStock(
                sale.businessId, product.id, updatedStock);
          }

          await isar.writeTxn(() async => await isar.transactionModels.put(ledger));
          await syncService.addToQueue(
            action: 'create',
            collectionPath: 'businesses/${sale.businessId}/transactions',
            docId: ledger.id,
            payload: ledger.toJson(),
          );
          // M6 sanitizes queued payloads to Timestamps at push time.
          await syncService.addToQueue(
            action: 'update',
            collectionPath: 'businesses/${sale.businessId}/sales',
            docId: sale.id,
            payload: approvedSale.toJson(),
          );
        }
      }

      // 6. Credit sales grow the customer balance (web use-sales.tsx:678)
      if (finalStatus == 'Pending' && sale.customerId != null) {
        await ref
            .read(customerRepositoryProvider)
            .updateBalance(sale.customerId!, sale.totalAmount);
      }
    });
  }
}
