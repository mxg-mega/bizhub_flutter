import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/services/firestore_service.dart';
import '../models/user_model.dart';

class UserRepository {
  static const String collectionPath = 'users';

  static Future<UserModel?> getById(String uid) async {
    return FirestoreService.getById<UserModel>(
      collectionPath: collectionPath,
      id: uid,
      fromJson: UserModel.fromJson,
    );
  }

  static Stream<UserModel?> watchById(String uid) {
    return FirestoreService.watchById<UserModel>(
      collectionPath: collectionPath,
      id: uid,
      fromJson: UserModel.fromJson,
    );
  }

  static Future<void> upsert(UserModel user) async {
    await FirestoreService.setById<UserModel>(
      collectionPath: collectionPath,
      id: user.uid,
      value: user,
      toJson: (u) => u.toJson(),
      merge: true,
    );
  }

  static Future<void> update(String id, Map<String, dynamic> data) async {
    data['updatedAt'] = FieldValue.serverTimestamp();
    await FirestoreService.updateById(
      collectionPath: collectionPath,
      id: id,
      data: data,
    );
  }

  static Future<void> delete(String id) async {
    await FirestoreService.deleteById(collectionPath: collectionPath, id: id);
  }

  static Future<List<UserModel>> queryByEmail(String email) async {
    return FirestoreService.query<UserModel>(
      collectionPath: collectionPath,
      fromJson: UserModel.fromJson,
      where: [(q) => q.where('email', isEqualTo: email)],
      limit: 1,
    );
  }
}
