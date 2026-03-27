import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/models/receipt_template_model.dart';
import '../../data/repositories/receipt_template_repository_impl.dart';
import '../../../../shared/providers/auth_provider.dart';

part 'receipt_providers.g.dart';

@riverpod
Future<ReceiptTemplateModel> activeReceiptTemplate(final ActiveReceiptTemplateRef ref) {
  final businessId = ref.watch(currentBusinessProvider)?.id;
  if (businessId == null) throw Exception('No active business');
  return ref.watch(receiptTemplateRepositoryProvider).getTemplate(businessId);
}

@riverpod
class ReceiptTemplateActions extends _$ReceiptTemplateActions {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<void> saveTemplate(final ReceiptTemplateModel template) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(receiptTemplateRepositoryProvider).saveTemplate(template);
      ref.invalidate(activeReceiptTemplateProvider);
    });
  }
}
