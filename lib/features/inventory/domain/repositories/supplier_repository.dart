import '../../data/models/supplier_model.dart';

abstract class SupplierRepository {
  Stream<List<SupplierModel>> watchSuppliers(final String businessId);
  Future<List<SupplierModel>> getSuppliers(final String businessId);
  Future<SupplierModel?> getSupplier(final String id);
  Future<void> saveSupplier(final SupplierModel supplier);
  Future<void> updateBalance(final String id, final double delta);
  Future<void> deleteSupplier(final String id);
}
