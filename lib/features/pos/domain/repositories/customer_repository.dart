import '../../data/models/customer_model.dart';
import '../../data/models/customer_payment_model.dart';

/// Result of a web-shaped installment payment
/// (web `recordInstallmentPayment`, use-sales.tsx:752-849).
class InstallmentPaymentResult {
  final double totalApplied;
  final int fullyPaid;
  final int partiallyPaid;
  final double leftover;

  const InstallmentPaymentResult({
    required this.totalApplied,
    required this.fullyPaid,
    required this.partiallyPaid,
    required this.leftover,
  });
}

abstract class CustomerRepository {
  Stream<List<CustomerModel>> watchCustomers(final String businessId);
  Future<void> saveCustomer(final CustomerModel customer);
  Future<List<CustomerModel>> getCustomers(final String businessId);
  Future<CustomerModel?> getCustomer(final String id);
  Future<void> updateBalance(final String customerId, final double amountDelta);
  Future<void> recordPayment(final CustomerPaymentModel payment);
  Stream<List<CustomerPaymentModel>> watchCustomerPayments(final String customerId);

  /// Web-shaped FIFO payment application (docs/PORTING_GUIDE.md §3.8,
  /// use-sales.tsx:752-849): applies [amount] across the customer's
  /// `'Pending'` sales oldest-first, settles fully-covered invoices to
  /// `'Paid'`, reduces the outstanding balance, and writes exactly one
  /// `'Customer Payment'` ledger entry — all in one Firestore transaction.
  Future<InstallmentPaymentResult> recordInstallmentPayment(
    final String businessId,
    final String customerId,
    final double amount, {
    final String paymentMethod,
    final String? note,
    final String? performedBy,
    final String? performedByName,
  });
}
