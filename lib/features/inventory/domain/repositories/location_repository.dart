import '../../data/models/location_model.dart';

abstract class LocationRepository {
  Stream<List<LocationModel>> watchLocations(final String businessId);
  Future<List<LocationModel>> getLocations(final String businessId);
  Future<LocationModel?> getLocation(final String businessId, final String id);
  Future<void> saveLocation(final String businessId, final LocationModel location);
  Future<void> deleteLocation(final String businessId, final String id);
}
