import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/models/supplier_model.dart';
import '../../data/repositories/supplier_repository_impl.dart';
import '../../../../shared/providers/auth_provider.dart';

part 'supplier_providers.g.dart';

@riverpod
Stream<List<SupplierModel>> supplierList(final SupplierListRef ref) {
  final businessId = ref.watch(currentBusinessProvider)?.id;
  if (businessId == null) return Stream.value([]);
  return ref.watch(supplierRepositoryProvider).watchSuppliers(businessId);
}

@riverpod
class SupplierActions extends _$SupplierActions {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<void> saveSupplier(final SupplierModel supplier) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(supplierRepositoryProvider).saveSupplier(supplier);
    });
  }

  Future<void> deleteSupplier(final String id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(supplierRepositoryProvider).deleteSupplier(id);
    });
  }
}
