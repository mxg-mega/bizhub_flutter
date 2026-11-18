import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/services/firestore_service.dart';
import '../../data/models/inventory_adjustment_model.dart';
import '../../data/models/product_model.dart';

part 'inventory_service.g.dart';

@riverpod
InventoryService inventoryService(final InventoryServiceRef ref) {
  return InventoryService();
}

class InventoryService {
  final _uuid = const Uuid();

  String _getProductsPath(final String businessId) => 'businesses/$businessId/products';
  String _getAdjustmentsPath(final String businessId) => 'businesses/$businessId/inventoryAdjustments';

  /// Performs an atomic stock adjustment for a single location.
  Future<void> adjustStock({
    required final String businessId,
    required final String productId,
    required final String locationId,
    required final double newQuantity,
    required final String userId,
    final String? reason,
    final String kind = 'adjustment',
  }) async {
    await FirestoreService.runTransaction((final transaction) async {
      final productRef = FirestoreService.docIn(_getProductsPath(businessId), productId);
      final snapshot = await transaction.get(productRef);

      if (!snapshot.exists) {
        throw Exception('Product not found: $productId');
      }

      final product = ProductModel.fromJson(snapshot.data()!);
      final oldQuantity = product.stockByLocation[locationId] ?? 0.0;

      final Map<String, double> updatedStock = Map.from(product.stockByLocation);
      updatedStock[locationId] = newQuantity;

      // 1. Update Product Stock
      transaction.update(productRef, {'stockByLocation': updatedStock});

      // 2. Create Adjustment Log — web shape (§3.6)
      final adjustmentId = _uuid.v4();
      final adjustmentRef = FirestoreService.docIn(_getAdjustmentsPath(businessId), adjustmentId);

      final adjustment = InventoryAdjustmentModel(
        id: adjustmentId,
        productId: productId,
        productName: product.name,
        type: 'adjustment',
        kind: kind,
        changes: {
          locationId: {'old': oldQuantity, 'new': newQuantity},
        },
        timestamp: DateTime.now(),
        userId: userId,
        reason: reason,
        notes: reason,
      );

      transaction.set(
        adjustmentRef,
        FirestoreService.sanitizeForFirestore(
          adjustment.toJson(),
          timestampFields: InventoryAdjustmentModel.firestoreTimestampFields,
        ),
      );
    });
  }

  /// Performs a relative stock adjustment (e.g. -5 for a sale).
  Future<void> incrementStock({
    required final String businessId,
    required final String productId,
    required final String locationId,
    required final double delta,
    required final String userId,
    final String? reason,
    final String kind = 'adjustment',
  }) async {
    await FirestoreService.runTransaction((final transaction) async {
      final productRef = FirestoreService.docIn(_getProductsPath(businessId), productId);
      final snapshot = await transaction.get(productRef);

      if (!snapshot.exists) throw Exception('Product not found');

      final product = ProductModel.fromJson(snapshot.data()!);
      final oldQuantity = product.stockByLocation[locationId] ?? 0.0;
      final newQuantity = oldQuantity + delta;

      if (newQuantity < 0) throw Exception('Insufficient stock');

      final Map<String, double> updatedStock = Map.from(product.stockByLocation);
      updatedStock[locationId] = newQuantity;

      transaction.update(productRef, {'stockByLocation': updatedStock});

      final adjustmentId = _uuid.v4();
      final adjustmentRef = FirestoreService.docIn(_getAdjustmentsPath(businessId), adjustmentId);
      final adjustment = InventoryAdjustmentModel(
        id: adjustmentId,
        productId: productId,
        productName: product.name,
        type: 'adjustment',
        kind: kind,
        changes: {
          locationId: {'old': oldQuantity, 'new': newQuantity},
        },
        timestamp: DateTime.now(),
        userId: userId,
        reason: reason,
        notes: reason,
      );
      transaction.set(
        adjustmentRef,
        FirestoreService.sanitizeForFirestore(
          adjustment.toJson(),
          timestampFields: InventoryAdjustmentModel.firestoreTimestampFields,
        ),
      );
    });
  }

  /// Performs an atomic stock transfer between two locations.
  Future<void> transferStock({
    required final String businessId,
    required final String productId,
    required final String fromLocationId,
    required final String toLocationId,
    required final double quantity,
    required final String userId,
    final String? reason,
  }) async {
    if (quantity <= 0) throw Exception('Transfer quantity must be positive');

    await FirestoreService.runTransaction((final transaction) async {
      final productRef = FirestoreService.docIn(_getProductsPath(businessId), productId);
      final snapshot = await transaction.get(productRef);

      if (!snapshot.exists) {
        throw Exception('Product not found: $productId');
      }

      final product = ProductModel.fromJson(snapshot.data()!);
      final sourceStock = product.stockByLocation[fromLocationId] ?? 0.0;
      final targetStock = product.stockByLocation[toLocationId] ?? 0.0;

      if (sourceStock < quantity) {
        throw Exception('Insufficient stock in source location');
      }

      final Map<String, double> updatedStock = Map.from(product.stockByLocation);
      updatedStock[fromLocationId] = sourceStock - quantity;
      updatedStock[toLocationId] = targetStock + quantity;

      // 1. Update Product Stock
      transaction.update(productRef, {'stockByLocation': updatedStock});

      // 2. Create Adjustment Log — web shape (§3.6): type is always
      // 'adjustment' on the wire, timestamp stays an ISO string.
      final adjustmentId = _uuid.v4();
      final adjustmentRef = FirestoreService.docIn(_getAdjustmentsPath(businessId), adjustmentId);

      final adjustment = InventoryAdjustmentModel(
        id: adjustmentId,
        productId: productId,
        productName: product.name,
        type: 'adjustment',
        kind: 'transfer',
        changes: {
          fromLocationId: {'old': sourceStock, 'new': updatedStock[fromLocationId]!},
          toLocationId: {'old': targetStock, 'new': updatedStock[toLocationId]!},
        },
        timestamp: DateTime.now(),
        userId: userId,
        reason: reason ?? 'Transfer from $fromLocationId to $toLocationId',
        notes: reason ?? 'Transfer from $fromLocationId to $toLocationId',
      );

      transaction.set(
        adjustmentRef,
        FirestoreService.sanitizeForFirestore(
          adjustment.toJson(),
          timestampFields: InventoryAdjustmentModel.firestoreTimestampFields,
        ),
      );
    });
  }
}
