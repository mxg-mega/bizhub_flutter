import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../shared/providers/auth_provider.dart';
import '../../data/models/transfer_model.dart';
import '../../data/repositories/transfer_repository_impl.dart';

part 'transfer_providers.g.dart';

@riverpod
Stream<List<TransferModel>> transferList(final TransferListRef ref) {
  final businessId = ref.watch(currentBusinessProvider)?.id;
  if (businessId == null) return Stream.value([]);
  // Live Isar watch; each listen also triggers the Firestore pull so
  // transfers created on the web (or other devices) surface here.
  return ref.watch(transferRepositoryProvider).watchTransfers(businessId);
}

@riverpod
class TransferActions extends _$TransferActions {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<void> updateStatus(
    final String transferId,
    final String status, {
    final String? notes,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final businessId = ref.read(currentBusinessProvider)?.id;
      if (businessId == null) throw Exception('No active business');
      await ref
          .read(transferRepositoryProvider)
          .updateStatus(businessId, transferId, status, notes: notes);
    });
  }
}
