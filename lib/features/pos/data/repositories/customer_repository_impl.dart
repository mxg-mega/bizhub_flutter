import 'dart:convert';
import 'package:isar/isar.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/database/isar_service.dart';
import '../../../../core/database/local_models.dart';
import '../../../../core/services/sync_service.dart';
import '../../domain/repositories/customer_repository.dart';
import '../models/customer_model.dart';
import '../models/customer_payment_model.dart';

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
      fromJsons: (final jsons) => jsons.map((j) => CustomerModel.fromJson(j)).toList(),
    );

    return _isar.localCustomers
        .where()
        .filter()
        .businessIdEqualTo(businessId)
        .watch(fireImmediately: true)
        .map((locals) => locals.map((l) => CustomerModel.fromJson(jsonDecode(l.data))).toList());
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
      fromJsons: (final jsons) => jsons.map((j) => CustomerModel.fromJson(j)).toList(),
    );

    return locals.map((l) => CustomerModel.fromJson(jsonDecode(l.data))).toList();
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
}
