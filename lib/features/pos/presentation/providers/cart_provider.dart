import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/database/isar_service.dart';
import '../../../../core/database/local_models.dart';
import '../../../../core/models/transaction_model.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/services/sync_service.dart';
import '../../../../core/utils/payment_method.dart';
import '../../../../shared/providers/app_settings_provider.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../inventory/data/models/inventory_adjustment_model.dart';
import '../../../inventory/data/models/product_model.dart';
import '../../../payments/data/models/transfer_model.dart';
import '../../../payments/data/repositories/transfer_repository_impl.dart';
import '../../data/models/customer_model.dart';
import '../../data/models/sale_item_model.dart';
import '../../data/models/sale_model.dart';
import '../../data/repositories/customer_repository_impl.dart';
import '../../data/repositories/pos_repository_impl.dart';
import 'customer_providers.dart';

part 'cart_provider.g.dart';

class CartState {
  final List<SaleItemModel> items;
  final double discount;
  final double taxRate;
  final String? customerId;
  final String? customerName;

  const CartState({
    this.items = const [],
    this.discount = 0.0,
    this.taxRate = 0.0,
    this.customerId = CustomerModel.walkInId,
    this.customerName = CustomerModel.walkInName,
  });

  double get subtotal =>
      items.fold(0, (final sum, final item) => sum + item.totalPrice);
  double get taxAmount => subtotal * taxRate;
  double get total => subtotal + taxAmount - discount;
  bool get hasCustomer =>
      customerId != null &&
      customerId!.trim().isNotEmpty &&
      customerId != CustomerModel.walkInId;

  CartState copyWith({
    final List<SaleItemModel>? items,
    final double? discount,
    final double? taxRate,
    final String? customerId,
    final String? customerName,
    final bool clearCustomer = false,
  }) => CartState(
    items: items ?? this.items,
    discount: discount ?? this.discount,
    taxRate: taxRate ?? this.taxRate,
    customerId: clearCustomer
        ? CustomerModel.walkInId
        : (customerId ?? this.customerId),
    customerName: clearCustomer
        ? CustomerModel.walkInName
        : (customerName ?? this.customerName),
  );
}

@riverpod
class Cart extends _$Cart {
  @override
  CartState build() => const CartState();

  void setCustomer(final String? id, [final String? name]) =>
      state = state.copyWith(
        customerId: id,
        customerName: name,
        clearCustomer: id == null || id.trim().isEmpty,
      );

  void addItem(
    final ProductModel product,
    final String unit,
    final double quantity,
  ) {
    final unitPrice = product.calculatePriceForUnit(unit);
    final existingIndex = state.items.indexWhere(
      (final i) => i.productId == product.id && i.unit == unit,
    );

    if (existingIndex >= 0) {
      final existing = state.items[existingIndex];
      final updatedItem = SaleItemModel(
        productId: existing.productId,
        name: existing.name,
        quantity: existing.quantity + quantity,
        unit: existing.unit,
        unitPrice: unitPrice,
        totalPrice: (existing.quantity + quantity) * unitPrice,
      );
      final newItems = List<SaleItemModel>.from(state.items);
      newItems[existingIndex] = updatedItem;
      state = state.copyWith(items: newItems);
    } else {
      final newItem = SaleItemModel(
        productId: product.id,
        name: product.name,
        quantity: quantity,
        unit: unit,
        unitPrice: unitPrice,
        totalPrice: quantity * unitPrice,
      );
      state = state.copyWith(items: [...state.items, newItem]);
    }
  }

  void removeItem(final String productId, final String unit) {
    state = state.copyWith(
      items: state.items
          .where((final i) => !(i.productId == productId && i.unit == unit))
          .toList(),
    );
  }

  void updateQuantity(
    final String productId,
    final String unit,
    final double quantity,
  ) {
    if (quantity <= 0) {
      removeItem(productId, unit);
      return;
    }
    final newItems = state.items.map((final item) {
      if (item.productId != productId || item.unit != unit) return item;
      return SaleItemModel(
        productId: item.productId,
        name: item.name,
        quantity: quantity,
        unit: item.unit,
        unitPrice: item.unitPrice,
        unitCost: item.unitCost,
        category: item.category,
        totalPrice: quantity * item.unitPrice,
      );
    }).toList();
    state = state.copyWith(items: newItems);
  }

  void setDiscount(final double value) {
    final next = value.isFinite
        ? value.clamp(0.0, state.subtotal).toDouble()
        : 0.0;
    state = state.copyWith(discount: next);
  }

  void setTaxRate(final double rate) {
    final next = rate.isFinite ? rate.clamp(0.0, 1.0).toDouble() : 0.0;
    state = state.copyWith(taxRate: next);
  }

  void updateItemPrice(
    final String productId,
    final String unit,
    final double unitPrice,
  ) {
    if (!unitPrice.isFinite || unitPrice < 0) return;
    final newItems = state.items.map((final item) {
      if (item.productId != productId || item.unit != unit) return item;
      return SaleItemModel(
        productId: item.productId,
        name: item.name,
        quantity: item.quantity,
        unit: item.unit,
        unitPrice: unitPrice,
        unitCost: item.unitCost,
        category: item.category,
        totalPrice: item.quantity * unitPrice,
      );
    }).toList();
    state = state.copyWith(items: newItems);
  }

  void clear() => state = const CartState();

  Future<SaleModel> checkout(
    final String paymentMethod,
    final String locationId, {
    final bool isDraft = false,
    final Map<String, dynamic>? transferDetails,
  }) async {
    final authState = ref.read(authProvider);
    final business = authState.activeBusiness;
    final user = authState.user;

    if (business == null || user == null) {
      throw Exception('Auth context missing');
    }
    if (state.items.isEmpty) throw Exception('Cart is empty');

    final businessId = business.id!;
    debugPrint(
      '[POS Checkout] Starting checkout for business: $businessId, location: $locationId, items: ${state.items.length}, method: $paymentMethod, isDraft: $isDraft',
    );

    final workflowEnabled = business.settings?['requireApproval'] ?? false;
    String status = isDraft
        ? 'Draft'
        : (workflowEnabled ? 'PendingPayment' : 'Paid');
    if (paymentMethod == 'on_credit') status = 'Pending';

    final saleId = const Uuid().v4();
    var customerId = state.customerId?.trim();
    var customerName = state.customerName?.trim();
    if (customerId == null ||
        customerId.isEmpty ||
        customerId == CustomerModel.walkInId) {
      customerId = CustomerModel.walkInId;
      customerName = CustomerModel.walkInName;
    } else {
      final customers = await ref.read(customerListProvider.future);
      for (final customer in customers) {
        if (customer.id == customerId && customer.name.trim().isNotEmpty) {
          customerName = customer.name.trim();
          break;
        }
      }
      if (customerName == null || customerName.isEmpty) {
        customerId = CustomerModel.walkInId;
        customerName = CustomerModel.walkInName;
      }
    }
    if (paymentMethod == 'on_credit' && customerId == CustomerModel.walkInId) {
      throw Exception('Select a customer for credit sale');
    }

    final now = DateTime.now();
    final actorName = user.name ?? 'Unknown';
    final sale = SaleModel(
      id: saleId,
      businessId:
          businessId, // this may be irrelevant if we are using a multi-tenant Firestore structure, but it's good to have for local storage
      userId: user.id,
      customerId: customerId,
      customer: customerName,
      items: state.items,
      subtotal: state.subtotal,
      tax: state.taxAmount,
      // Web contract: `taxRate` is stored as a percentage (10 = 10%),
      // while the cart keeps it as a fraction — docs/PORTING_GUIDE.md §3.1.
      taxRate: state.taxRate * 100,
      discount: state.discount,
      discountType: 'fixed',
      // Web contract: `totalAmount` is the items sum (quantity × unitPrice),
      // matching the web's addSale computation — docs/PORTING_GUIDE.md §5.
      // Tax/discount live in their own fields.
      totalAmount: state.subtotal,
      paymentMethod: normalizePaymentMethod(paymentMethod),
      date: now,
      createdAt: now,
      updatedAt: now,
      locationId: locationId,
      status: status,
      workflowEnabled: workflowEnabled,
      workflowHistory: [
        SaleWorkflowStage(
          stage: status,
          performedBy: user.id,
          performedByName: actorName,
          performedAt: now,
          notes: 'Sale created',
        ),
      ],
      createdBy: user.id,
      createdByName: actorName,
      // Web contract formats — docs/PORTING_GUIDE.md §3.1.
      referenceNumber: _generateReferenceNumber(now),
      barcode:
          'SALE-${now.millisecondsSinceEpoch}-${saleId.substring(0, 6).toUpperCase()}',
      transferDetails:
          paymentMethod == 'bank_transfer' && transferDetails != null
          ? TransferDetailsModel.fromJson(transferDetails)
          : null,
    );

    final isOffline = ref.read(appSettingsNotifierProvider).offlineModeEnabled;
    final isar = ref.read(isarDatabaseProvider).value!;
    final syncService = ref.read(syncServiceProvider);

    // If it's a Draft, save and exit without stock deduction or financial transaction
    if (status == 'Draft') {
      debugPrint(
        '[POS Checkout] Sale is draft. Saving without stock deduction.',
      );
      await ref.read(posRepositoryProvider).saveSale(sale);
      clear();
      return sale;
    }

    final transactionId = const Uuid().v4();
    final financialTransaction = TransactionModel(
      id: transactionId,
      businessId: businessId,
      type: 'Sale',
      // Ledger amount matches the stored sale `totalAmount` (items sum),
      // same as the web ledger — docs/PORTING_GUIDE.md §3.4/§5.
      amount: sale.totalAmount,
      category: FinancialCategory.revenue,
      createdAt: now,
      // `date` is the web ledger's ordering field — REQUIRED on the wire (§2).
      date: now,
      description: 'Sale to ${sale.customer ?? 'Walk-in Customer'}',
      referenceId: sale.id,
      paymentMethod: paymentMethod,
      performedBy: user.id,
      performedByName: actorName,
    );

    if (!isOffline) {
      try {
        debugPrint('[POS Checkout] Executing atomic Firestore transaction...');
        final Map<String, ProductModel> updatedProducts = {};

        await FirestoreService.runTransaction((final txn) async {
          // 1. READ & VALIDATE ALL PRODUCTS AT THE SPECIFIC LOCATION
          // Non-inventory lines (services/fees/custom charges) never touch
          // product docs — web parity via `isInventoryProduct` (M8).
          for (final item in state.items.where((final i) => i.isInventory)) {
            final productRef = FirestoreService.docIn(
              'businesses/$businessId/products',
              item.productId,
            );
            final snap = await txn.get(productRef);

            if (!snap.exists || snap.data() == null) {
              debugPrint(
                '[POS Checkout] Product not found in Firestore: ${item.productId}',
              );
              throw Exception('Product "${item.name}" not found in inventory');
            }

            final prodData = Map<String, dynamic>.from(snap.data()!);
            prodData['id'] = snap.id;
            final product = ProductModel.fromJson(prodData);

            double requestedQty = item.quantity;
            if (product.unitChain != null) {
              final factor = product.unitChain!.getFactor(
                item.unit,
                product.unitChain!.baseUnit ?? '',
              );
              requestedQty = item.quantity * factor;
            }

            final currentStock = product.stockByLocation[locationId] ?? 0.0;
            debugPrint(
              '[POS Checkout] Validating ${product.name} (id: ${product.id}): currentStock at location "$locationId" = $currentStock, requested = $requestedQty (${item.quantity} ${item.unit})',
            );

            if (currentStock < requestedQty) {
              final errorMsg =
                  'Insufficient stock for "${product.name}". Available at location ($locationId): $currentStock, requested: $requestedQty';
              debugPrint('[POS Checkout] VALIDATION FAILED: $errorMsg');
              throw Exception(errorMsg);
            }

            final newStock = currentStock - requestedQty;
            final updatedStockByLoc = Map<String, double>.from(
              product.stockByLocation,
            );
            updatedStockByLoc[locationId] = newStock;

            final updatedProd = ProductModel(
              id: product.id,
              name: product.name,
              sku: product.sku,
              description: product.description,
              category: product.category,
              cost: product.cost,
              price: product.price,
              stockByLocation: updatedStockByLoc,
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

            // 2. STAGE PRODUCT STOCK DEDUCTION
            txn.update(productRef, {'stockByLocation': updatedStockByLoc});

            // 3. STAGE INVENTORY ADJUSTMENT LOG — web shape (§3.6):
            // type is always 'adjustment', timestamp stays an ISO string.
            final adjustmentId = const Uuid().v4();
            final adjustmentRef = FirestoreService.docIn(
              'businesses/$businessId/inventoryAdjustments',
              adjustmentId,
            );
            final adjustment = InventoryAdjustmentModel(
              id: adjustmentId,
              productId: product.id,
              productName: product.name,
              type: 'adjustment',
              kind: 'sale',
              changes: {
                locationId: {'old': currentStock, 'new': newStock},
              },
              timestamp: DateTime.now(),
              userId: user.id,
              reason: 'POS Sale #${sale.id.substring(0, 8)}',
              notes: 'POS Sale #${sale.id.substring(0, 8)}',
            );
            txn.set(
              adjustmentRef,
              FirestoreService.sanitizeForFirestore(
                adjustment.toJson(),
                timestampFields:
                    InventoryAdjustmentModel.firestoreTimestampFields,
              ),
            );
          }

          // 4. STAGE SALE DOCUMENT
          final saleRef = FirestoreService.docIn(
            'businesses/$businessId/sales',
            sale.id,
          );
          txn.set(
            saleRef,
            FirestoreService.sanitizeForFirestore(
              sale.toJson(),
              timestampFields: SaleModel.firestoreTimestampFields,
            ),
          );

          // 5. STAGE FINANCIAL TRANSACTION DOCUMENT
          final txnRef = FirestoreService.docIn(
            'businesses/$businessId/transactions',
            financialTransaction.id,
          );
          final txnPayload = FirestoreService.sanitizeForFirestore(
            financialTransaction.toJson(),
            timestampFields: TransactionModel.firestoreTimestampFields,
          );
          txnPayload['relatedEntityId'] = sale.id;
          txn.set(txnRef, txnPayload);

          debugPrint(
            '[POS Checkout] Firestore transaction staged successfully.',
          );
        });

        debugPrint(
          '[POS Checkout] Firestore transaction committed! Updating local Isar cache...',
        );

        // 6. UPDATE LOCAL ISAR CACHE
        await isar.writeTxn(() async {          // Put sale locally
          await isar.localSales.put(
            LocalSale(
              id: sale.id,
              businessId: sale.businessId,
              timestamp: sale.date,
              total: sale.total,
              data: jsonEncode(sale.toJson()),
            ),
          );

          // Put updated products locally
          for (final prod in updatedProducts.values) {
            await isar.localProducts.put(
              LocalProduct(
                id: prod.id,
                name: prod.name,
                sku: prod.sku,
                businessId: businessId,
                isArchived: prod.isArchived,
                data: jsonEncode(prod.toJson()),
              ),
            );
          }

          // Put transaction locally
          await isar.transactionModels.put(financialTransaction);
        });

        await _recordTransferIfNeeded(sale, now);

        if (paymentMethod == 'on_credit' && state.hasCustomer) {
          // Web parity: the credit balance grows by the stored `totalAmount`
          // (use-sales.tsx:218) — docs/PORTING_GUIDE.md §5.
          await ref
              .read(customerRepositoryProvider)
              .updateBalance(state.customerId!, sale.totalAmount);
        }

        clear();
        debugPrint(
          '[POS Checkout] Checkout completed successfully. Sale #${sale.id} finalized.',
        );
        return sale;
      } catch (e) {
        debugPrint(
          '[POS Checkout] Transaction aborted or failed with error: $e',
        );
        rethrow;
      }
    } else {
      // OFFLINE MODE: Validate local stock FIRST before writing any sale or queueing
      debugPrint('[POS Checkout] Processing checkout in OFFLINE mode...');
      final Map<String, ProductModel> updatedLocalProducts = {};

      for (final item in state.items.where((final i) => i.isInventory)) {
        final localProd = await isar.localProducts
            .filter()
            .idEqualTo(item.productId)
            .findFirst();
        if (localProd == null) {
          throw Exception('Product "${item.name}" not found in local cache');
        }

        final prodMap = jsonDecode(localProd.data) as Map<String, dynamic>;
        final product = ProductModel.fromJson(prodMap);

        double requestedQty = item.quantity;
        if (product.unitChain != null) {
          final factor = product.unitChain!.getFactor(
            item.unit,
            product.unitChain!.baseUnit ?? '',
          );
          requestedQty = item.quantity * factor;
        }

        final currentStock = product.stockByLocation[locationId] ?? 0.0;
        debugPrint(
          '[POS Checkout] [Offline] Validating ${product.name}: local stock at $locationId = $currentStock, requested = $requestedQty',
        );

        if (currentStock < requestedQty) {
          final errorMsg =
              'Insufficient stock for "${product.name}". Available locally at ($locationId): $currentStock, requested: $requestedQty';
          debugPrint('[POS Checkout] [Offline] ABORTING: $errorMsg');
          throw Exception(errorMsg);
        }

        final updatedStockByLoc = Map<String, double>.from(
          product.stockByLocation,
        );
        updatedStockByLoc[locationId] = currentStock - requestedQty;

        final updatedProd = ProductModel(
          id: product.id,
          name: product.name,
          sku: product.sku,
          description: product.description,
          category: product.category,
          cost: product.cost,
          price: product.price,
          stockByLocation: updatedStockByLoc,
          unitSystemVersion: product.unitSystemVersion,
          unitChain: product.unitChain,
          priceConfigs: product.priceConfigs,
          isArchived: product.isArchived,
          sellingUnit: product.sellingUnit,
          purchaseUnit: product.purchaseUnit,
          updatedAt: DateTime.now(),
          expirationDate: product.expirationDate,
        );

        updatedLocalProducts[product.id] = updatedProd;
      }

      // If all products have sufficient stock, write everything to Isar and queue to sync
      await isar.writeTxn(() async {
        await isar.localSales.put(
          LocalSale(
            id: sale.id,
            businessId: sale.businessId,
            timestamp: sale.date,
            total: sale.total,
            data: jsonEncode(sale.toJson()),
          ),
        );

        for (final prod in updatedLocalProducts.values) {
          await isar.localProducts.put(
            LocalProduct(
              id: prod.id,
              name: prod.name,
              sku: prod.sku,
              businessId: businessId,
              isArchived: prod.isArchived,
              data: jsonEncode(prod.toJson()),
            ),
          );
        }

        await isar.transactionModels.put(financialTransaction);
      });

      // Queue for remote push
      await syncService.addToQueue(
        action: 'create',
        collectionPath: 'businesses/$businessId/sales',
        docId: sale.id,
        payload: sale.toJson(),
      );

      await syncService.addToQueue(
        action: 'create',
        collectionPath: 'businesses/$businessId/transactions',
        docId: financialTransaction.id,
        payload: financialTransaction.toJson(),
      );

      for (final prod in updatedLocalProducts.values) {
        await syncService.addToQueue(
          action: 'update',
          collectionPath: 'businesses/$businessId/products',
          docId: prod.id,
          payload: {'stockByLocation': prod.stockByLocation},
        );
      }

      await _recordTransferIfNeeded(sale, now);

      if (paymentMethod == 'on_credit' && state.hasCustomer) {
        // Web parity: the credit balance grows by the stored `totalAmount`
        // (use-sales.tsx:218) — docs/PORTING_GUIDE.md §5.
        await ref
            .read(customerRepositoryProvider)
            .updateBalance(state.customerId!, sale.totalAmount);
      }

      clear();
      debugPrint('[POS Checkout] [Offline] Checkout completed and queued.');
      return sale;
    }
  }

  /// Writes the bank-transfer record (`businesses/{b}/transfers`) the web
  /// creates after a successful checkout (`use-sales.tsx:294`). Non-fatal:
  /// a transfer bookkeeping failure must not fail the sale.
  Future<void> _recordTransferIfNeeded(
    final SaleModel sale,
    final DateTime now,
  ) async {
    final details = sale.transferDetails;
    if (details == null) return;
    try {
      final transfer = TransferModel(
        id: const Uuid().v4(),
        businessId: sale.businessId,
        saleId: sale.id,
        customerId: sale.customerId,
        customerName: sale.customer,
        amount: sale.totalAmount,
        transferFee: details.transferFee,
        bankName: details.bankName,
        accountName: details.accountName,
        accountNumber: details.accountNumber,
        routingNumber: details.routingNumber,
        status: details.status,
        createdAt: now,
        updatedAt: now,
      );
      await ref.read(transferRepositoryProvider).saveTransfer(transfer);
    } catch (e) {
      debugPrint('[POS Checkout] Failed to record transfer: $e');
    }
  }
}

/// Generates a sale reference number in the web contract format:
/// `INV-{yy}{mm}{rand4}` (web POS `generateReferenceNumber`,
/// `src/app/(app)/sales/pos/page.tsx:315-321`) — docs/PORTING_GUIDE.md §3.1.
String _generateReferenceNumber(final DateTime now) {
  final yy = (now.year % 100).toString().padLeft(2, '0');
  final mm = now.month.toString().padLeft(2, '0');
  final random = 1000 + Random().nextInt(9000);
  return 'INV-$yy$mm$random';
}
