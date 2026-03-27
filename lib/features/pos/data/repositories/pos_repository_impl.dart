import 'dart:convert';
import 'package:isar/isar.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/database/isar_service.dart';
import '../../../../core/database/local_models.dart';
import '../../../../core/services/sync_service.dart';
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

  @override
  Stream<List<SaleModel>> watchSales(final String businessId) {
    // Note: In a full implementation, we would also pull sales from Firestore
    // For now, we assume sales are primarily created locally and synced UP.
    return _isar.localSales
        .where()
        .filter()
        .businessIdEqualTo(businessId)
        .sortByTimestampDesc()
        .watch(fireImmediately: true)
        .map((locals) => locals.map((l) => SaleModel.fromJson(jsonDecode(l.data))).toList());
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
      await _isar.localSales.put(local);
    });

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
    
    return locals.map((l) => SaleModel.fromJson(jsonDecode(l.data))).toList();
  }
}
