import 'dart:convert';
import 'package:isar/isar.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/database/isar_service.dart';
import '../../../../core/database/local_models.dart';
import '../../../../core/models/transaction_model.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/services/sync_service.dart';
import '../../../../core/utils/payment_method.dart';
import '../../domain/repositories/customer_repository.dart';
import '../models/customer_model.dart';
import '../models/customer_payment_model.dart';
import '../models/sale_model.dart';

part 'customer_repository_impl.g.dart';

@riverpod
CustomerRepository customerRepository(final CustomerRepositoryRef ref) {
  final isar = ref.watch(isarDatabaseProvider).value;
  final syncService = ref.watch(syncServiceProvider);
  if (isar == null) throw Exception('Isar not initialized');
  return CustomerRepositoryImpl(isar, syncService);
}

class CustomerRepositoryImpl implements CustomerRepository {
  final Isar _isar;
  final SyncService _syncService;

  CustomerRepositoryImpl(this._isar, this._syncService);

  String _getCustomersPath(final String businessId) => 'businesses/$businessId/customers';

  @override
  Stream<List<CustomerModel>> watchCustomers(final String businessId) {
    _syncService.pull<CustomerModel>(
      businessId: businessId,
      collectionPath: _getCustomersPath(businessId),
      fromJsons: (final jsons) => jsons.map((final j) => CustomerModel.fromJson(j)).toList(),
    );

    return _isar.localCustomers
        .where()
        .filter()
        .businessIdEqualTo(businessId)
        .watch(fireImmediately: true)
        .map((final locals) => locals.map((final l) => CustomerModel.fromJson(jsonDecode(l.data))).toList());
  }

  @override
  Future<void> saveCustomer(final CustomerModel customer) async {
    final local = LocalCustomer(
      id: customer.id,
      businessId: customer.businessId,
      name: customer.name,
      phone: customer.phone,
      data: jsonEncode(customer.toJson()),
    );

    await _isar.writeTxn(() async => await _isar.localCustomers.put(local));

    await _syncService.addToQueue(
      action: 'update',
      collectionPath: _getCustomersPath(customer.businessId),
      docId: customer.id,
      payload: customer.toJson(),
    );
  }

  @override
  Future<List<CustomerModel>> getCustomers(final String businessId) async {
    final locals = await _isar.localCustomers
        .where()
        .filter()
        .businessIdEqualTo(businessId)
        .findAll();
    
    _syncService.pull<CustomerModel>(
      businessId: businessId,
      collectionPath: _getCustomersPath(businessId),
      fromJsons: (final jsons) => jsons.map((final j) => CustomerModel.fromJson(j)).toList(),
    );

    return locals.map((final l) => CustomerModel.fromJson(jsonDecode(l.data))).toList();
  }

  @override
  Future<CustomerModel?> getCustomer(final String id) async {
    final local = await _isar.localCustomers.where().idEqualTo(id).findFirst();
    if (local == null) return null;
    return CustomerModel.fromJson(jsonDecode(local.data));
  }

  @override
  Future<void> updateBalance(final String customerId, final double amountDelta) async {
    final customer = await getCustomer(customerId);
    if (customer == null) return;

    final updated = customer.copyWith(
      outstandingBalance: customer.outstandingBalance + amountDelta,
    );

    await saveCustomer(updated);
  }

  @override
  Future<void> recordPayment(final CustomerPaymentModel payment) async {
    await _isar.writeTxn(() async => await _isar.customerPaymentModels.put(payment));

    await _syncService.addToQueue(
      action: 'create',
      collectionPath: 'businesses/${payment.businessId}/customerPayments',
      docId: payment.id,
      payload: payment.toJson(),
    );

    await updateBalance(payment.customerId, -payment.amount);
  }

  @override
  Stream<List<CustomerPaymentModel>> watchCustomerPayments(final String customerId) {
    return _isar.customerPaymentModels
        .where()
        .filter()
        .customerIdEqualTo(customerId)
        .sortByTimestampDesc()
        .watch(fireImmediately: true);
  }

  @override
  Future<InstallmentPaymentResult> recordInstallmentPayment(
    final String businessId,
    final String customerId,
    final double amount, {
    final String paymentMethod = 'cash',
    final String? note,
    final String? performedBy,
    final String? performedByName,
  }) async {
    if (amount <= 0) throw Exception('Payment amount must be greater than zero.');
    const epsilon = 0.005;

    // Discover outstanding invoices straight from Firestore (web parity —
    // never trust a possibly-stale in-memory list), FIFO oldest-first by
    // `date` (use-sales.tsx:736-745).
    final snap = await FirestoreService.collection('businesses/$businessId/sales')
        .where('customerId', isEqualTo: customerId)
        .get();
    final candidates = <SaleModel>[];
    for (final d in snap.docs) {
      final data = d.data();
      if (!data.containsKey('id')) data['id'] = d.id;
      final sale = SaleModel.fromJson(data);
      if (sale.status != 'Pending') continue;
      final due = sale.totalAmount - (sale.amountPaid ?? 0.0);
      if (due > epsilon) candidates.add(sale);
    }
    candidates.sort((final a, final b) => a.date.compareTo(b.date));
    if (candidates.isEmpty) {
      throw Exception('This customer has no outstanding invoices to pay.');
    }

    final now = DateTime.now();
    double remaining = amount;
    double totalApplied = 0.0;
    var fullyPaid = 0;
    var partiallyPaid = 0;
    final settledSales = <SaleModel>[];
    TransactionModel? ledger;

    await FirestoreService.runTransaction((final tx) async {
      final customerRef =
          FirestoreService.docIn('businesses/$businessId/customers', customerId);
      final customerSnap = await tx.get(customerRef);
      if (!customerSnap.exists) throw Exception('Customer not found.');

      remaining = amount;
      totalApplied = 0.0;
      fullyPaid = 0;
      partiallyPaid = 0;
      settledSales.clear();

      for (final candidate in candidates) {
        if (remaining <= epsilon) break;
        final saleRef =
            FirestoreService.docIn('businesses/$businessId/sales', candidate.id);
        final saleSnap = await tx.get(saleRef);
        if (!saleSnap.exists) continue;
        final sale = SaleModel.fromJson(saleSnap.data()!);
        if (sale.status != 'Pending') continue;
        final due = sale.totalAmount - (sale.amountPaid ?? 0.0);
        if (due <= epsilon) continue;

        final applied = due < remaining ? due : remaining;
        final newPaid = (sale.amountPaid ?? 0.0) + applied;
        final fullySettled = newPaid >= sale.totalAmount - epsilon;

        final updatedSale = sale.copyWith(
          amountPaid: fullySettled ? sale.totalAmount : newPaid,
          status: fullySettled ? 'Paid' : sale.status,
          updatedAt: now,
        );
        tx.update(
          saleRef,
          FirestoreService.sanitizeForFirestore(
            updatedSale.toJson(),
            timestampFields: SaleModel.firestoreTimestampFields,
          ),
        );

        remaining -= applied;
        totalApplied += applied;
        if (fullySettled) {
          fullyPaid++;
        } else {
          partiallyPaid++;
        }
        settledSales.add(updatedSale);
      }

      if (totalApplied <= epsilon) {
        throw Exception('This customer has no outstanding invoices to pay.');
      }

      final currentBalance =
          ((customerSnap.data()!['outstandingBalance'] ?? 0) as num).toDouble();
      final newBalance = currentBalance - totalApplied;
      tx.update(customerRef, {
        'outstandingBalance': newBalance < 0 ? 0.0 : newBalance,
      });

      final customerName =
          (customerSnap.data()!['name'] as String?) ?? 'Unknown Customer';
      final trimmedNote = note?.trim();
      ledger = TransactionModel(
        id: const Uuid().v4(),
        businessId: businessId,
        type: 'Customer Payment',
        amount: totalApplied,
        category: FinancialCategory.revenue,
        createdAt: now,
        date: now,
        description: (trimmedNote != null && trimmedNote.isNotEmpty)
            ? 'Payment from $customerName \u2014 $trimmedNote'
            : 'Payment from $customerName',
        referenceId: customerId,
        paymentMethod: normalizePaymentMethod(paymentMethod),
        performedBy: performedBy,
        performedByName: performedByName,
      );
      tx.set(
        FirestoreService.docIn('businesses/$businessId/transactions', ledger!.id),
        FirestoreService.sanitizeForFirestore(
          ledger!.toJson(),
          timestampFields: TransactionModel.firestoreTimestampFields,
        ),
      );
    });

    // Update the local Isar cache to mirror the committed transaction
    await _isar.writeTxn(() async {
      final localCustomer =
          await _isar.localCustomers.filter().idEqualTo(customerId).findFirst();
      if (localCustomer != null) {
        final data =
            Map<String, dynamic>.from(jsonDecode(localCustomer.data) as Map<String, dynamic>);
        final applied = totalApplied;
        final current = ((data['outstandingBalance'] ?? 0) as num).toDouble();
        final next = current - applied;
        data['outstandingBalance'] = next < 0 ? 0.0 : next;
        await _isar.localCustomers.put(
          LocalCustomer(
            id: localCustomer.id,
            businessId: localCustomer.businessId,
            name: localCustomer.name,
            phone: localCustomer.phone,
            data: jsonEncode(data),
          ),
        );
      }

      for (final s in settledSales) {
        await _isar.localSales.put(
          LocalSale(
            id: s.id,
            businessId: s.businessId,
            timestamp: s.date,
            total: s.total,
            data: jsonEncode(s.toJson()),
          ),
        );
      }

      final written = ledger;
      if (written != null) {
        await _isar.transactionModels.put(written);
      }
    });

    return InstallmentPaymentResult(
      totalApplied: totalApplied,
      fullyPaid: fullyPaid,
      partiallyPaid: partiallyPaid,
      leftover: remaining < 0 ? 0.0 : remaining,
    );
  }
}
