import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../data/models/customer_model.dart';
import '../../data/models/customer_payment_model.dart';
import '../../data/repositories/customer_repository_impl.dart';

part 'customer_providers.g.dart';

@riverpod
Stream<List<CustomerModel>> customerList(final CustomerListRef ref) {
  final businessId = ref.watch(currentBusinessProvider)?.id;
  if (businessId == null) return Stream.value([]);
  return ref.watch(customerRepositoryProvider).watchCustomers(businessId);
}

@riverpod
Stream<List<CustomerPaymentModel>> customerPayments(final CustomerPaymentsRef ref, final String customerId) {
  return ref.watch(customerRepositoryProvider).watchCustomerPayments(customerId);
}

@riverpod
class CustomerActions extends _$CustomerActions {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<void> saveCustomer(final CustomerModel customer) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(customerRepositoryProvider).saveCustomer(customer);
    });
  }

  Future<void> recordPayment(final CustomerPaymentModel payment) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(customerRepositoryProvider).recordPayment(payment);
    });
  }
}
