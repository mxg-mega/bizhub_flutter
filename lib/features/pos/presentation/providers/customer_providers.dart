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
      // M7: web-shaped FIFO payment (docs/PORTING_GUIDE.md §3.8) — settles
      // 'Pending' invoices oldest-first, updates the outstanding balance and
      // writes the 'Customer Payment' ledger in one Firestore transaction.
      // The Flutter-only customerPayments collection is no longer written.
      final authState = ref.read(authProvider);
      final businessId = authState.activeBusiness?.id;
      if (businessId == null) throw Exception('No active business selected');
      await ref.read(customerRepositoryProvider).recordInstallmentPayment(
            businessId,
            payment.customerId,
            payment.amount,
            paymentMethod: payment.paymentMethod,
            note: payment.notes,
            performedBy: authState.user?.id,
            performedByName: authState.user?.name ?? 'Unknown',
          );
    });
  }
}
