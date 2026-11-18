import '../../data/models/transfer_model.dart';

abstract class TransferRepository {
  Stream<List<TransferModel>> watchTransfers(final String businessId);

  Future<List<TransferModel>> getTransfers(final String businessId);

  List<TransferModel> getBySale(final List<TransferModel> all, final String saleId);

  Future<void> saveTransfer(final TransferModel transfer);

  Future<void> updateStatus(
    final String businessId,
    final String transferId,
    final String status, {
    final String? notes,
  });
}
