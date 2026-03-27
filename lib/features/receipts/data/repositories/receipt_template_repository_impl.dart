import 'package:isar/isar.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/database/isar_service.dart';
import '../../../../core/services/sync_service.dart';
import '../../domain/repositories/receipt_template_repository.dart';
import '../models/receipt_template_model.dart';

part 'receipt_template_repository_impl.g.dart';

@riverpod
ReceiptTemplateRepository receiptTemplateRepository(final ReceiptTemplateRepositoryRef ref) {
  final isar = ref.watch(isarDatabaseProvider).value;
  final syncService = ref.watch(syncServiceProvider);
  if (isar == null) throw Exception('Isar not initialized');
  return ReceiptTemplateRepositoryImpl(isar, syncService);
}

class ReceiptTemplateRepositoryImpl implements ReceiptTemplateRepository {
  final Isar _isar;
  final SyncService _syncService;

  ReceiptTemplateRepositoryImpl(this._isar, this._syncService);

  @override
  Future<ReceiptTemplateModel> getTemplate(final String businessId) async {
    final local = await _isar.receiptTemplateModels
        .where()
        .filter()
        .businessIdEqualTo(businessId)
        .findFirst();

    if (local != null) return local;

    final defaultTemplate = ReceiptTemplateModel.defaultTemplate(businessId);
    await saveTemplate(defaultTemplate);
    return defaultTemplate;
  }

  @override
  Future<void> saveTemplate(final ReceiptTemplateModel template) async {
    await _isar.writeTxn(() async {
      await _isar.receiptTemplateModels.put(template);
    });

    await _syncService.addToQueue(
      action: 'update',
      collectionPath: 'businesses/${template.businessId}/settings',
      docId: 'receipt_template',
      payload: template.toJson(),
    );
  }
}
