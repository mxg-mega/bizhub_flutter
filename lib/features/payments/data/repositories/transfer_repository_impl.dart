import 'package:isar/isar.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/database/isar_service.dart';
import '../../../../core/services/sync_service.dart';
import '../../domain/repositories/transfer_repository.dart';
import '../models/transfer_model.dart';

part 'transfer_repository_impl.g.dart';

@riverpod
TransferRepository transferRepository(final TransferRepositoryRef ref) {
  final isar = ref.watch(isarDatabaseProvider).value;
  final syncService = ref.watch(syncServiceProvider);
  if (isar == null) throw Exception('Isar not initialized');
  return TransferRepositoryImpl(isar, syncService);
}

class TransferRepositoryImpl implements TransferRepository {
  final Isar _isar;
  final SyncService _syncService;

  TransferRepositoryImpl(this._isar, this._syncService);

  String _getTransfersPath(final String businessId) =>
      'businesses/$businessId/transfers';

  @override
  Stream<List<TransferModel>> watchTransfers(final String businessId) {
    // Background pull so web-created transfers sync down (same pattern as
    // `watchSales` — the only pull trigger for this collection).
    _syncService.pull<TransferModel>(
      businessId: businessId,
      collectionPath: _getTransfersPath(businessId),
      fromJsons: (final jsons) =>
          jsons.map((final j) => TransferModel.fromJson(j)).toList(),
    );

    return _isar.transferModels
        .where()
        .filter()
        .businessIdEqualTo(businessId)
        .sortByCreatedAtDesc()
        .watch(fireImmediately: true);
  }

  @override
  Future<List<TransferModel>> getTransfers(final String businessId) async {
    _syncService.pull<TransferModel>(
      businessId: businessId,
      collectionPath: _getTransfersPath(businessId),
      fromJsons: (final jsons) =>
          jsons.map((final j) => TransferModel.fromJson(j)).toList(),
    );

    return _isar.transferModels
        .where()
        .filter()
        .businessIdEqualTo(businessId)
        .sortByCreatedAtDesc()
        .findAll();
  }

  @override
  List<TransferModel> getBySale(
    final List<TransferModel> all,
    final String saleId,
  ) =>
      all.where((final t) => t.saleId == saleId).toList();

  @override
  Future<void> saveTransfer(final TransferModel transfer) async {
    await _isar.writeTxn(() async => await _isar.transferModels.put(transfer));

    await _syncService.addToQueue(
      action: 'create',
      collectionPath: _getTransfersPath(transfer.businessId),
      docId: transfer.id,
      payload: transfer.toJson(),
    );
  }

  @override
  Future<void> updateStatus(
    final String businessId,
    final String transferId,
    final String status, {
    final String? notes,
  }) async {
    final now = DateTime.now();
    final isTerminal = status == 'completed' || status == 'failed';

    // 1. Local patch (list/mirror stays responsive offline).
    final local = await _isar.transferModels
        .filter()
        .idEqualTo(transferId)
        .findFirst();
    if (local != null) {
      final updated = TransferModel(
        id: local.id,
        businessId: local.businessId,
        saleId: local.saleId,
        customerId: local.customerId,
        customerName: local.customerName,
        amount: local.amount,
        transferFee: local.transferFee,
        bankName: local.bankName,
        accountName: local.accountName,
        accountNumber: local.accountNumber,
        routingNumber: local.routingNumber,
        status: status,
        transferId: local.transferId,
        notes: notes ?? local.notes,
        createdAt: local.createdAt,
        updatedAt: now,
        processedAt: isTerminal ? now : local.processedAt,
      );
      await _isar.writeTxn(() async => await _isar.transferModels.put(updated));
    }

    // 2. Remote patch — web parity (`updateTransferStatus`): `updatedAt`
    // always, `processedAt` on terminal statuses, `notes` only when given.
    final payload = <String, dynamic>{
      'status': status,
      'updatedAt': now,
      if (isTerminal) 'processedAt': now,
      if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
    };

    await _syncService.addToQueue(
      action: 'update',
      collectionPath: _getTransfersPath(businessId),
      docId: transferId,
      payload: payload,
    );
  }
}
