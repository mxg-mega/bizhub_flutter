import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/services/firestore_service.dart';
import '../models/user_model.dart';

class UserRepository {
  static const String collectionPath = 'users';

  static Future<UserModel?> getById(final String uid) async {
    return FirestoreService.getById<UserModel>(
      collectionPath: collectionPath,
      id: uid,
      fromJson: UserModel.fromJson,
    );
  }

  static Stream<UserModel?> watchById(final String uid) {
    return FirestoreService.watchById<UserModel>(
      collectionPath: collectionPath,
      id: uid,
      fromJson: UserModel.fromJson,
    );
  }

  static Future<void> upsert(final UserModel user) async {
    await FirestoreService.setById<UserModel>(
      collectionPath: collectionPath,
      id: user.id,
      value: user,
      toJson: (final u) => u.toJson(),
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

  static Future<List<UserModel>> queryByEmail(final String email) async {
    return FirestoreService.query<UserModel>(
      collectionPath: collectionPath,
      fromJson: UserModel.fromJson,
      where: [(final q) => q.where('email', isEqualTo: email)],
      limit: 1,
    );
  }
}
