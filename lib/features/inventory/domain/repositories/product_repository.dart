import '../../data/models/product_model.dart';

abstract class ProductRepository {
  Stream<List<ProductModel>> watchProducts(final String businessId);
  Future<List<ProductModel>> getProducts(final String businessId);
  Future<ProductModel?> getProduct(final String businessId, final String id);
  Future<void> saveProduct(final String businessId, final ProductModel product);
  Future<void> updateStock(
    final String businessId,
    final String productId,
    final Map<String, double> stockByLocation,
  );
  Future<void> archiveProduct(
    final String businessId,
    final String id, {
    final String? archivedBy,
    final String? archivedByName,
    final String? archivedReason,
  });
  Future<void> deleteProduct(final String businessId, final String id);
}
