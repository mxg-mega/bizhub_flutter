import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:isar/isar.dart' hide Query;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter/foundation.dart';
import '../database/isar_service.dart';
import '../database/local_models.dart';
import '../models/sync_queue_model.dart';
import '../models/transaction_model.dart';
import '../config/firebase/firebase_config.dart';
import 'firestore_service.dart';
import '../../features/inventory/data/models/product_model.dart';
import '../../features/inventory/data/models/inventory_adjustment_model.dart';
import '../../features/inventory/data/models/location_model.dart';
import '../../features/inventory/data/models/supplier_model.dart';
import '../../features/inventory/data/models/stock_in_model.dart';
import '../../features/pos/data/models/sale_model.dart';
import '../../features/pos/data/models/customer_model.dart';
import '../../features/pos/data/models/customer_payment_model.dart';
import '../../features/dashboard/data/models/expense_model.dart';
import '../../features/dashboard/data/models/invitation_model.dart';
import '../../features/receipts/data/models/receipt_template_model.dart';
import '../../features/payments/data/models/transfer_model.dart';
import '../../shared/providers/app_settings_provider.dart';

part 'sync_service.g.dart';

@Riverpod(keepAlive: true)
SyncService syncService(final SyncServiceRef ref) {
  final isar = ref.watch(isarDatabaseProvider).value;
  if (isar == null) throw Exception('Isar not initialized');
  final offlineMode = ref.watch(appSettingsNotifierProvider.select((final s) => s.offlineModeEnabled));
  final service = SyncService(isar, offlineMode);
  service.init();
  return service;
}

class SyncService {
  final Isar _isar;
  final bool _offlineMode;
  Timer? _syncTimer;
  bool _isSyncing = false;
  StreamSubscription? _connectivitySubscription;

  SyncService(this._isar, this._offlineMode);

  void init() {
    startSyncTimer();
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((final results) {
      if (!_offlineMode && results.any((final r) => r != ConnectivityResult.none)) {
        pushPendingChanges();
      }
    });
  }

  void dispose() {
    stopSyncTimer();
    _connectivitySubscription?.cancel();
  }

  void startSyncTimer() {
    _syncTimer?.cancel();
    if (!_offlineMode) {
      _syncTimer = Timer.periodic(const Duration(minutes: 1), (final _) => pushPendingChanges());
    }
  }

  void stopSyncTimer() => _syncTimer?.cancel();

  Future<void> pushPendingChanges() async {
    if (_isSyncing || _offlineMode) return;
    _isSyncing = true;

    try {
      final pending = await _isar.syncQueueModels.where().sortByTimestamp().findAll();
      for (final item in pending) {
        try {
          await _syncItem(item);
          await _isar.writeTxn(() async => await _isar.syncQueueModels.delete(item.id));
        } catch (e) {
          await _isar.writeTxn(() async {
            item.attempts++;
            item.lastError = e.toString();
            await _isar.syncQueueModels.put(item);
          });
          break; 
        }
      }
    } finally {
      _isSyncing = false;
    }
  }

  /// Wire-shape enforcement at push time (docs/PORTING_GUIDE.md §7.2): queued
  /// payloads are raw model JSON (ISO strings), so the matching model's
  /// `firestoreTimestampFields` allowlist converts them to Firestore Timestamps
  /// here — the wire shape is then identical for online and offline writes.
  /// `inventoryAdjustments` maps to an empty set (pure null-strip): its
  /// `timestamp` must stay an ISO string (§3.6). Unknown collections keep the
  /// legacy substring heuristic.
  static Set<String>? _timestampFieldsForPath(final String collectionPath) {
    final segments = collectionPath.split('/');
    final collection = segments.isNotEmpty ? segments.last : '';
    switch (collection) {
      case 'sales':
        return SaleModel.firestoreTimestampFields;
      case 'transactions':
        return TransactionModel.firestoreTimestampFields;
      case 'products':
        return ProductModel.firestoreTimestampFields;
      case 'inventoryAdjustments':
        return InventoryAdjustmentModel.firestoreTimestampFields;
      case 'transfers':
        return TransferModel.firestoreTimestampFields;
      default:
        return null;
    }
  }

  Future<void> _syncItem(final SyncQueueModel item) async {
    final docRef = FirebaseConfig.firestore.doc('${item.collectionPath}/${item.docId}');
    switch (item.action) {
      case 'create':
      case 'update':
        final payload = FirestoreService.sanitizeForFirestore(
          item.payload,
          timestampFields: _timestampFieldsForPath(item.collectionPath),
        );
        await docRef.set(payload, SetOptions(merge: true));
        break;
      case 'delete':
        await docRef.delete();
        break;
    }
  }

  Future<void> addToQueue({
    required final String action,
    required final String collectionPath,
    required final String docId,
    required final Map<String, dynamic> payload,
  }) async {
    final item = SyncQueueModel(
      action: action,
      collectionPath: collectionPath,
      docId: docId,
      payloadJson: jsonEncode(payload),
      timestamp: DateTime.now(),
    );
    await _isar.writeTxn(() async => await _isar.syncQueueModels.put(item));
    pushPendingChanges();
  }

  Future<void> pull<T>({
    required final String businessId,
    required final String collectionPath,
    required final List<T> Function(List<Map<String, dynamic>> jsons) fromJsons,
    final Map<String, dynamic>? where,
  }) async {
    debugPrint('DEBUG: SyncService.pull initiated for $collectionPath');
    try {
      Query<Map<String, dynamic>> query = FirebaseConfig.firestore.collection(collectionPath);
      if (where != null) {
        where.forEach((final key, final value) => query = query.where(key, isEqualTo: value));
      }

      final snapshot = await query.get();
      debugPrint('DEBUG: Firestore snapshot for $collectionPath contains ${snapshot.docs.length} docs');

      // Per-doc isolation: ONE unparseable doc must not silently abort the
      // whole pull (it used to — leaving the local cache empty for the
      // entire collection). Skipped docs are logged by id.
      final items = <T>[];
      for (final docSnapshot in snapshot.docs) {
        final data = docSnapshot.data();
        if (!data.containsKey('id')) data['id'] = docSnapshot.id;
        // Inject businessId if missing (often missing in subcollection docs)
        if (!data.containsKey('businessId')) data['businessId'] = businessId;
        try {
          items.addAll(fromJsons([data]));
        } catch (e) {
          debugPrint(
            'SyncService.pull: skipping unparseable doc ${docSnapshot.id} in $collectionPath: $e',
          );
        }
      }

      await _isar.writeTxn(() async {
        if (T == ProductModel) {
          for (final item in items as List<ProductModel>) {
            final local = LocalProduct(
              id: item.id,
              name: item.name,
              sku: item.sku,
              businessId: businessId,
              isArchived: item.isArchived,
              data: jsonEncode(item.toJson()),
            );
            await _isar.localProducts.put(local);
          }
        } else if (T == LocationModel) {
          for (final item in items as List<LocationModel>) {
            final local = LocalLocation(
              id: item.id,
              name: item.name,
              businessId: businessId,
              data: jsonEncode(item.toJson()),
            );
            await _isar.localLocations.put(local);
          }
        } else if (T == CustomerModel) {
          for (final item in items as List<CustomerModel>) {
            final local = LocalCustomer(
              id: item.id,
              businessId: item.businessId,
              name: item.name,
              phone: item.phone,
              data: jsonEncode(item.toJson()),
            );
            await _isar.localCustomers.put(local);
          }
        } else if (T == TransactionModel) {
          await _isar.transactionModels.putAll(items as List<TransactionModel>);
        } else if (T == ExpenseModel) {
          await _isar.expenseModels.putAll(items as List<ExpenseModel>);
        } else if (T == SupplierModel) {
          await _isar.supplierModels.putAll(items as List<SupplierModel>);
        } else if (T == StockInModel) {
          await _isar.stockInModels.putAll(items as List<StockInModel>);
        } else if (T == CustomerPaymentModel) {
          await _isar.customerPaymentModels.putAll(items as List<CustomerPaymentModel>);
        } else if (T == SaleModel) {
          for (final item in items as List<SaleModel>) {
            final local = LocalSale(
              id: item.id,
              businessId: item.businessId,
              timestamp: item.date,
              total: item.total,
              data: jsonEncode(item.toJson()),
            );
            await _isar.localSales.put(local);
          }
        }
      });
    } catch (e) {
      debugPrint('DEBUG: SyncService.pull error for $collectionPath: $e');
    }
  }
}
