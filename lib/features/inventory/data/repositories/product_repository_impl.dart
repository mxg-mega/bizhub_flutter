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
        return jsons.map((j) {
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
        .map((locals) {
          debugPrint(
            'DEBUG: Isar emitted ${locals.length} local products for business: $businessId',
          );
          return locals
              .map((l) => ProductModel.fromJson(jsonDecode(l.data)))
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
          jsons.map((j) => ProductModel.fromJson(j)).toList(),
      where: {'isArchived': false},
    );

    return locals
        .map((l) => ProductModel.fromJson(jsonDecode(l.data)))
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

  @override
  Future<void> updateStock(
    final String businessId,
    final String productId,
    final Map<String, double> stockByLocation,
  ) async {
    final product = await getProduct(businessId, productId);
    if (product != null) {
      final updatedProduct = ProductModel(
        id: product.id,
        name: product.name,
        sku: product.sku,
        description: product.description,
        cost: product.cost,
        stockByLocation: stockByLocation,
        unitSystemVersion: product.unitSystemVersion,
        unitChain: product.unitChain,
        priceConfigs: product.priceConfigs,
        isArchived: product.isArchived,
      );
      await saveProduct(businessId, updatedProduct);
    }
  }

  @override
  Future<void> archiveProduct(final String businessId, final String id) async {
    final product = await getProduct(businessId, id);
    if (product != null) {
      final updatedProduct = ProductModel(
        id: product.id,
        name: product.name,
        sku: product.sku,
        description: product.description,
        cost: product.cost,
        stockByLocation: product.stockByLocation,
        unitSystemVersion: product.unitSystemVersion,
        unitChain: product.unitChain,
        priceConfigs: product.priceConfigs,
        isArchived: true,
      );
      await saveProduct(businessId, updatedProduct);
    }
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
