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
import '../../features/inventory/data/models/product_model.dart';
import '../../features/inventory/data/models/location_model.dart';
import '../../features/inventory/data/models/supplier_model.dart';
import '../../features/inventory/data/models/stock_in_model.dart';
import '../../features/pos/data/models/sale_model.dart';
import '../../features/pos/data/models/customer_payment_model.dart';
import '../../features/dashboard/data/models/expense_model.dart';
import '../../features/dashboard/data/models/invitation_model.dart';
import '../../features/receipts/data/models/receipt_template_model.dart';
import '../../shared/providers/app_settings_provider.dart';

part 'sync_service.g.dart';

@Riverpod(keepAlive: true)
SyncService syncService(final SyncServiceRef ref) {
  final isar = ref.watch(isarDatabaseProvider).value;
  if (isar == null) throw Exception('Isar not initialized');
  final offlineMode = ref.watch(appSettingsNotifierProvider.select((s) => s.offlineModeEnabled));
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
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
      if (!_offlineMode && results.any((r) => r != ConnectivityResult.none)) {
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

  Future<void> _syncItem(final SyncQueueModel item) async {
    final docRef = FirebaseConfig.firestore.doc('${item.collectionPath}/${item.docId}');
    switch (item.action) {
      case 'create':
      case 'update':
        await docRef.set(item.payload, SetOptions(merge: true));
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
    Map<String, dynamic>? where,
  }) async {
    debugPrint('DEBUG: SyncService.pull initiated for $collectionPath');
    try {
      Query<Map<String, dynamic>> query = FirebaseConfig.firestore.collection(collectionPath);
      if (where != null) {
        where.forEach((key, value) => query = query.where(key, isEqualTo: value));
      }

      final snapshot = await query.get();
      debugPrint('DEBUG: Firestore snapshot for $collectionPath contains ${snapshot.docs.length} docs');
      
      final items = fromJsons(snapshot.docs.map((d) {
        final data = d.data();
        if (!data.containsKey('id')) data['id'] = d.id;
        return data;
      }).toList());

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
        }
      });
    } catch (e) {
      debugPrint('DEBUG: SyncService.pull error for $collectionPath: $e');
    }
  }
}
