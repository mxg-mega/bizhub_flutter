import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/services/firestore_service.dart';
import '../models/business_model.dart';

class BusinessRepository {
  static const String collectionPath = 'businesses';

  static Future<BusinessModel?> getById(final String id) async {
    return FirestoreService.getById<BusinessModel>(
      collectionPath: collectionPath,
      id: id,
      fromJson: BusinessModel.fromJson,
    );
  }

  static Stream<BusinessModel?> watchById(final String id) {
    return FirestoreService.watchById<BusinessModel>(
      collectionPath: collectionPath,
      id: id,
      fromJson: BusinessModel.fromJson,
    );
  }

  static Future<void> upsert(final BusinessModel business) async {
    await FirestoreService.setById<BusinessModel>(
      collectionPath: collectionPath,
      id: business.id!,
      value: business,
      toJson: (final b) => b.toJson(),
      merge: true,
    );
  }

  static Future<void> update(final String id, final Map<String, dynamic> data) async {
    data['updatedAt'] = FieldValue.serverTimestamp();
    await FirestoreService.updateById(
      collectionPath: collectionPath,
      id: id,
      data: data,
    );
  }

  static Future<void> delete(final String id) async {
    await FirestoreService.deleteById(collectionPath: collectionPath, id: id);
  }

  static Future<List<BusinessModel>> forOwner(final String ownerUserId) async {
    return FirestoreService.query<BusinessModel>(
      collectionPath: collectionPath,
      fromJson: BusinessModel.fromJson,
      where: [(final q) => q.where('ownerId', isEqualTo: ownerUserId)],
      orderBy: const [OrderBy('createdAt', descending: true)],
    );
  }
}
