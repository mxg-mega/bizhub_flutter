import 'package:isar/isar.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/database/isar_service.dart';
import '../../../../core/services/sync_service.dart';
import '../../domain/repositories/supplier_repository.dart';
import '../models/supplier_model.dart';

part 'supplier_repository_impl.g.dart';

@riverpod
SupplierRepository supplierRepository(final SupplierRepositoryRef ref) {
  final isar = ref.watch(isarDatabaseProvider).value;
  final syncService = ref.watch(syncServiceProvider);
  if (isar == null) throw Exception('Isar not initialized');
  return SupplierRepositoryImpl(isar, syncService);
}

class SupplierRepositoryImpl implements SupplierRepository {
  final Isar _isar;
  final SyncService _syncService;

  SupplierRepositoryImpl(this._isar, this._syncService);

  String _getSuppliersPath(final String businessId) => 'businesses/$businessId/suppliers';

  @override
  Stream<List<SupplierModel>> watchSuppliers(final String businessId) {
    _syncService.pull<SupplierModel>(
      businessId: businessId,
      collectionPath: _getSuppliersPath(businessId),
      fromJsons: (final jsons) => jsons.map((j) => SupplierModel.fromJson(j)).toList(),
    );

    return _isar.supplierModels
        .where()
        .filter()
        .businessIdEqualTo(businessId)
        .watch(fireImmediately: true);
  }

  @override
  Future<List<SupplierModel>> getSuppliers(final String businessId) async {
    return await _isar.supplierModels.where().filter().businessIdEqualTo(businessId).findAll();
  }

  @override
  Future<SupplierModel?> getSupplier(final String id) async {
    return await _isar.supplierModels.filter().idEqualTo(id).findFirst();
  }

  @override
  Future<void> saveSupplier(final SupplierModel supplier) async {
    await _isar.writeTxn(() async => await _isar.supplierModels.put(supplier));

    await _syncService.addToQueue(
      action: 'update',
      collectionPath: _getSuppliersPath(supplier.businessId),
      docId: supplier.id,
      payload: supplier.toJson(),
    );
  }

  @override
  Future<void> updateBalance(final String id, final double delta) async {
    final supplier = await getSupplier(id);
    if (supplier == null) return;

    final updated = supplier.copyWith(balance: supplier.balance + delta);
    await saveSupplier(updated);
  }

  @override
  Future<void> deleteSupplier(final String id) async {
    final supplier = await getSupplier(id);
    if (supplier == null) return;

    await _isar.writeTxn(() async => await _isar.supplierModels.delete(supplier.isarId));

    await _syncService.addToQueue(
      action: 'delete',
      collectionPath: _getSuppliersPath(supplier.businessId),
      docId: id,
      payload: {},
    );
  }
}
