import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../data/models/product_model.dart';
import '../../data/models/location_model.dart';
import '../../data/repositories/product_repository_impl.dart';
import '../../data/repositories/location_repository_impl.dart';
import '../../domain/services/inventory_service.dart';

part 'inventory_providers.g.dart';

@riverpod
Stream<List<ProductModel>> productList(final ProductListRef ref) {
  final businessId = ref.watch(currentBusinessProvider)?.id;
  if (businessId == null) return Stream.value([]);
  
  final repository = ref.watch(productRepositoryProvider);
  return repository.watchProducts(businessId);
}

@riverpod
Future<List<String>> categories(final CategoriesRef ref) async {
  final products = await ref.watch(productListProvider.future);
  final categories = products
      .map((final p) => p.category ?? 'Uncategorized')
      .toSet()
      .toList();
  categories.sort();
  // Move 'Uncategorized' to end if exists
  if (categories.contains('Uncategorized')) {
    categories.remove('Uncategorized');
    categories.add('Uncategorized');
  }
  return ['All', ...categories];
}

@riverpod
Stream<List<LocationModel>> locations(final LocationsRef ref) {
  final businessId = ref.watch(currentBusinessProvider)?.id;
  if (businessId == null) return Stream.value([]);
  
  final repository = ref.watch(locationRepositoryProvider);
  return repository.watchLocations(businessId);
}

@riverpod
class InventoryActions extends _$InventoryActions {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  /// Performs relative adjustments across multiple locations.
  /// [adjustments] is Map<locationId, offset>
  Future<void> adjustInventory({
    required final String productId,
    required final Map<String, double> adjustments,
    final String? reason,
  }) async {
    final authState = ref.read(authProvider);
    final businessId = authState.activeBusiness?.id;
    final userId = authState.user?.id ?? 'unknown';
    
    if (businessId == null) {
      state = AsyncValue.error('No active business found', StackTrace.current);
      return;
    }

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final inventoryService = ref.read(inventoryServiceProvider);
      
      // We need to fetch current product to get current quantities for each location
      final productRepository = ref.read(productRepositoryProvider);
      final product = await productRepository.getProduct(businessId, productId);
      
      if (product == null) throw Exception('Product not found');

      // For each adjustment, calculate the new absolute quantity
      for (final entry in adjustments.entries) {
        final locationId = entry.key;
        final offset = entry.value;
        final currentQty = product.stockByLocation[locationId] ?? 0.0;
        final newQty = currentQty + offset;

        if (newQty < 0) {
          throw Exception('Stock cannot be negative for location: $locationId');
        }

        await inventoryService.adjustStock(
          businessId: businessId,
          productId: productId,
          locationId: locationId,
          newQuantity: newQty,
          userId: userId,
          reason: reason,
        );
      }
      
      ref.invalidate(productListProvider);
    });
  }

  Future<void> adjustStock({
    required final String productId,
    required final String locationId,
    required final double newQuantity,
    final String? reason,
  }) async {
    final authState = ref.read(authProvider);
    final businessId = authState.activeBusiness?.id;
    final userId = authState.user?.id ?? 'unknown';
    
    if (businessId == null) {
      state = AsyncValue.error('No active business found', StackTrace.current);
      return;
    }

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(inventoryServiceProvider).adjustStock(
        businessId: businessId,
        productId: productId,
        locationId: locationId,
        newQuantity: newQuantity,
        userId: userId,
        reason: reason,
      );
      ref.invalidate(productListProvider);
    });
  }

  Future<void> transferStock({
    required final String productId,
    required final String fromLocationId,
    required final String toLocationId,
    required final double quantity,
    final String? reason,
  }) async {
    final authState = ref.read(authProvider);
    final businessId = authState.activeBusiness?.id;
    final userId = authState.user?.id ?? 'unknown';

    if (businessId == null) {
      state = AsyncValue.error('No active business found', StackTrace.current);
      return;
    }

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(inventoryServiceProvider).transferStock(
        businessId: businessId,
        productId: productId,
        fromLocationId: fromLocationId,
        toLocationId: toLocationId,
        quantity: quantity,
        userId: userId,
        reason: reason,
      );
      ref.invalidate(productListProvider);
    });
  }

  Future<void> saveProduct(final ProductModel product) async {
    final authState = ref.read(authProvider);
    final businessId = ref.read(currentBusinessProvider)?.id;
    final user = authState.user;
    if (businessId == null) return;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      // Audit trail (web contract §3.5): stamp creator once, modifier always
      final actorName = user?.name ?? 'Unknown';
      final stamped = (product.createdBy == null)
          ? product.copyWith(
              createdBy: user?.id,
              createdByName: actorName,
              lastModifiedBy: user?.id,
              lastModifiedByName: actorName,
            )
          : product.copyWith(
              lastModifiedBy: user?.id,
              lastModifiedByName: actorName,
            );
      await ref.read(productRepositoryProvider).saveProduct(businessId, stamped);
      ref.invalidate(productListProvider);
    });
  }

  Future<void> archiveProduct(final String productId,
      {final String? reason}) async {
    final authState = ref.read(authProvider);
    final businessId = ref.read(currentBusinessProvider)?.id;
    final user = authState.user;
    if (businessId == null) return;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(productRepositoryProvider).archiveProduct(
            businessId,
            productId,
            archivedBy: user?.id,
            archivedByName: user?.name ?? 'Unknown',
            archivedReason: reason,
          );
      ref.invalidate(productListProvider);
    });
  }

  Future<void> deleteLocation(final String locationId) async {
    final businessId = ref.read(currentBusinessProvider)?.id;
    if (businessId == null) return;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      // Web parity (use-locations.tsx:98): block deleting a location that
      // still holds stock — transfer stock out first.
      final products = await ref.read(productRepositoryProvider).getProducts(businessId);
      for (final product in products) {
        final qty = product.stockByLocation[locationId] ?? 0.0;
        if (qty > 0) {
          throw Exception(
              'Cannot delete "${locationId}" because it still contains stock. Please transfer stock first.');
        }
      }
      await ref.read(locationRepositoryProvider).deleteLocation(businessId, locationId);
      ref.invalidate(productListProvider);
    });
  }

  Future<void> deleteProduct(final String productId) async {
    final businessId = ref.read(currentBusinessProvider)?.id;
    if (businessId == null) return;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(productRepositoryProvider).deleteProduct(businessId, productId);
      ref.invalidate(productListProvider);
    });
  }
}
