import '../../data/models/customer_model.dart';
import '../../data/models/customer_payment_model.dart';

abstract class CustomerRepository {
  Stream<List<CustomerModel>> watchCustomers(final String businessId);
  Future<void> saveCustomer(final CustomerModel customer);
  Future<List<CustomerModel>> getCustomers(final String businessId);
  Future<CustomerModel?> getCustomer(final String id);
  Future<void> updateBalance(final String customerId, final double amountDelta);
  Future<void> recordPayment(final CustomerPaymentModel payment);
  Stream<List<CustomerPaymentModel>> watchCustomerPayments(final String customerId);
}

