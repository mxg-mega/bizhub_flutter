import 'dart:convert';
import 'package:isar/isar.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/database/isar_service.dart';
import '../../../../core/database/local_models.dart';
import '../../../../core/services/sync_service.dart';
import '../../domain/repositories/location_repository.dart';
import '../models/location_model.dart';

part 'location_repository_impl.g.dart';

@riverpod
LocationRepository locationRepository(final LocationRepositoryRef ref) {
  final isar = ref.watch(isarDatabaseProvider).value;
  final syncService = ref.watch(syncServiceProvider);
  if (isar == null) throw Exception('Isar not initialized');
  return LocationRepositoryImpl(isar, syncService);
}

class LocationRepositoryImpl implements LocationRepository {
  final Isar _isar;
  final SyncService _syncService;

  LocationRepositoryImpl(this._isar, this._syncService);

  String _getLocationsPath(final String businessId) => 'businesses/$businessId/locations';

  @override
  Stream<List<LocationModel>> watchLocations(final String businessId) {
    _syncService.pull<LocationModel>(
      businessId: businessId,
      collectionPath: _getLocationsPath(businessId),
      fromJsons: (final jsons) => jsons.map((j) => LocationModel.fromJson(j)).toList(),
    );

    return _isar.localLocations
        .where()
        .filter()
        .businessIdEqualTo(businessId)
        .watch(fireImmediately: true)
        .map((locals) => locals.map((l) => LocationModel.fromJson(jsonDecode(l.data))).toList());
  }

  @override
  Future<List<LocationModel>> getLocations(final String businessId) async {
    final locals = await _isar.localLocations
        .where()
        .filter()
        .businessIdEqualTo(businessId)
        .findAll();
    
    _syncService.pull<LocationModel>(
      businessId: businessId,
      collectionPath: _getLocationsPath(businessId),
      fromJsons: (final jsons) => jsons.map((j) => LocationModel.fromJson(j)).toList(),
    );

    return locals.map((l) => LocationModel.fromJson(jsonDecode(l.data))).toList();
  }

  @override
  Future<LocationModel?> getLocation(final String businessId, final String id) async {
    final local = await _isar.localLocations.where().idEqualTo(id).findFirst();
    if (local == null) return null;
    return LocationModel.fromJson(jsonDecode(local.data));
  }

  @override
  Future<void> saveLocation(final String businessId, final LocationModel location) async {
    final local = LocalLocation(
      id: location.id,
      name: location.name,
      businessId: businessId,
      data: jsonEncode(location.toJson()),
    );

    await _isar.writeTxn(() async => await _isar.localLocations.put(local));

    await _syncService.addToQueue(
      action: 'update',
      collectionPath: _getLocationsPath(businessId),
      docId: location.id,
      payload: location.toJson(),
    );
  }

  @override
  Future<void> deleteLocation(final String businessId, final String id) async {
    final local = await _isar.localLocations.where().idEqualTo(id).findFirst();
    if (local != null) {
      await _isar.writeTxn(() async => await _isar.localLocations.delete(local.isarId));
    }

    await _syncService.addToQueue(
      action: 'delete',
      collectionPath: _getLocationsPath(businessId),
      docId: id,
      payload: {},
    );
  }
}
