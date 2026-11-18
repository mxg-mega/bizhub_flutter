import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/database/isar_service.dart';
import '../../../../core/database/local_models.dart';
import '../../../../core/services/sync_service.dart';
import '../../domain/repositories/product_repository.dart';
import '../models/product_model.dart';

part 'product_repository_impl.g.dart';

@riverpod
ProductRepository productRepository(final ProductRepositoryRef ref) {
  final isar = ref.watch(isarDatabaseProvider).value;
  final syncService = ref.watch(syncServiceProvider);
  if (isar == null) throw Exception('Isar not initialized');
  return ProductRepositoryImpl(isar, syncService);
}

class ProductRepositoryImpl implements ProductRepository {
  final Isar _isar;
  final SyncService _syncService;

  ProductRepositoryImpl(this._isar, this._syncService);

  String _getProductsPath(final String businessId) =>
      'businesses/$businessId/products';

  @override
  Stream<List<ProductModel>> watchProducts(final String businessId) {
    debugPrint('DEBUG: watchProducts called for business: $businessId');

    // 1. Trigger background pull
    _syncService.pull<ProductModel>(
      businessId: businessId,
      collectionPath: _getProductsPath(businessId),
      fromJsons: (final jsons) {
        debugPrint(
          'DEBUG: Received ${jsons.length} products from Firestore for business: $businessId',
        );
        return jsons.map((final j) {
          debugPrint('DEBUG: Product JSON: $j');
          return ProductModel.fromJson(j);
        }).toList();
      },
      // where: {'isArchived': false},
    );

    // 2. Return stream from Isar
    return _isar.localProducts
        .where()
        .filter()
        .businessIdEqualTo(businessId)
        .and()
        .isArchivedEqualTo(false)
        .watch(fireImmediately: true)
        .map((final locals) {
          debugPrint(
            'DEBUG: Isar emitted ${locals.length} local products for business: $businessId',
          );
          return locals
              .map((final l) => ProductModel.fromJson(jsonDecode(l.data)))
              .toList();
        });
  }

  @override
  Future<List<ProductModel>> getProducts(final String businessId) async {
    final locals = await _isar.localProducts
        .where()
        .filter()
        .businessIdEqualTo(businessId)
        .and()
        .isArchivedEqualTo(false)
        .findAll();

    _syncService.pull<ProductModel>(
      businessId: businessId,
      collectionPath: _getProductsPath(businessId),
      fromJsons: (final jsons) =>
          jsons.map((final j) => ProductModel.fromJson(j)).toList(),
      where: {'isArchived': false},
    );

    return locals
        .map((final l) => ProductModel.fromJson(jsonDecode(l.data)))
        .toList();
  }

  @override
  Future<ProductModel?> getProduct(
    final String businessId,
    final String id,
  ) async {
    final local = await _isar.localProducts.where().idEqualTo(id).findFirst();
    if (local == null) return null;
    return ProductModel.fromJson(jsonDecode(local.data));
  }

  @override
  Future<void> saveProduct(
    final String businessId,
    final ProductModel product,
  ) async {
    final local = LocalProduct(
      id: product.id,
      name: product.name,
      sku: product.sku,
      businessId: businessId,
      isArchived: product.isArchived,
      data: jsonEncode(product.toJson()),
    );

    await _isar.writeTxn(() async => await _isar.localProducts.put(local));

    await _syncService.addToQueue(
      action: 'update',
      collectionPath: _getProductsPath(businessId),
      docId: product.id,
      payload: product.toJson(),
    );
  }

  /// Field-targeted patch: updates the local Isar JSON in place and queues
  /// ONLY the patched fields. The sync worker writes with merge:true, so
  /// unrelated product fields (price, category, units, expiration...) are
  /// never touched. The previous whole-object rewrite zeroed `price` and
  /// clobbered `category` on every stock change (docs/PORTING_GUIDE.md §3.5).
  Future<void> _patchProduct(
    final String businessId,
    final String id,
    final Map<String, dynamic> patch,
  ) async {
    // Null values would DELETE those fields on a merge:true write — drop them
    patch.removeWhere((final _, final v) => v == null);

    final local = await _isar.localProducts.where().idEqualTo(id).findFirst();
    if (local != null) {
      final data =
          Map<String, dynamic>.from(jsonDecode(local.data) as Map<String, dynamic>);
      data.addAll(patch);
      await _isar.writeTxn(() async {
        await _isar.localProducts.put(
          LocalProduct(
            id: local.id,
            name: local.name,
            sku: local.sku,
            businessId: local.businessId,
            isArchived: (data['isArchived'] as bool?) ?? local.isArchived,
            data: jsonEncode(data),
          ),
        );
      });
    }

    await _syncService.addToQueue(
      action: 'update',
      collectionPath: _getProductsPath(businessId),
      docId: id,
      payload: patch,
    );
  }

  @override
  Future<void> updateStock(
    final String businessId,
    final String productId,
    final Map<String, double> stockByLocation,
  ) async {
    await _patchProduct(businessId, productId, <String, dynamic>{
      'stockByLocation': stockByLocation,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<void> archiveProduct(
    final String businessId,
    final String id, {
    final String? archivedBy,
    final String? archivedByName,
    final String? archivedReason,
  }) async {
    await _patchProduct(businessId, id, <String, dynamic>{
      'isArchived': true,
      'archivedAt': DateTime.now().toIso8601String(),
      'archivedBy': archivedBy,
      'archivedByName': archivedByName,
      'archivedReason': archivedReason,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<void> deleteProduct(final String businessId, final String id) async {
    final local = await _isar.localProducts.where().idEqualTo(id).findFirst();
    if (local != null) {
      await _isar.writeTxn(
        () async => await _isar.localProducts.delete(local.isarId),
      );
    }

    await _syncService.addToQueue(
      action: 'delete',
      collectionPath: _getProductsPath(businessId),
      docId: id,
      payload: {},
    );
  }
}
