import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../config/firebase/firebase_config.dart';

typedef FromJson<T> = T Function(Map<String, dynamic> json);
typedef ToJson<T> = Map<String, dynamic> Function(T value);

class FirestoreService {
  FirestoreService._();

  static FirebaseFirestore get _db => FirebaseConfig.firestore;

  static CollectionReference<Map<String, dynamic>> collection(String path) {
    return _db.collection(path);
  }

  static DocumentReference<Map<String, dynamic>> doc(String path) {
    return _db.doc(path);
  }

  static DocumentReference<Map<String, dynamic>> docIn(
    String collectionPath,
    String id,
  ) {
    return _db.collection(collectionPath).doc(id);
  }

  static Future<T?> getById<T>({
    required String collectionPath,
    required String id,
    required FromJson<T> fromJson,
  }) async {
    try {
      final snapshot = await _db.collection(collectionPath).doc(id).get();
      if (!snapshot.exists || snapshot.data() == null) return null;
      return fromJson(snapshot.data()!);
    } catch (e) {
      if (kDebugMode) {
        print('FirestoreService.getById error: $e');
      }
      rethrow;
    }
  }

  static Stream<T?> watchById<T>({
    required String collectionPath,
    required String id,
    required FromJson<T> fromJson,
  }) {
    return _db.collection(collectionPath).doc(id).snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      return fromJson(snap.data()!);
    });
  }

  static Future<void> setById<T>({
    required String collectionPath,
    required String id,
    required T value,
    required ToJson<T> toJson,
    bool merge = false,
  }) async {
    await _db
        .collection(collectionPath)
        .doc(id)
        .set(toJson(value), SetOptions(merge: merge));
  }

  static Future<void> updateById({
    required String collectionPath,
    required String id,
    required Map<String, dynamic> data,
  }) async {
    await _db.collection(collectionPath).doc(id).update(data);
  }

  static Future<void> deleteById({
    required String collectionPath,
    required String id,
  }) async {
    await _db.collection(collectionPath).doc(id).delete();
  }

  static Future<T> runTransaction<T>(
    Future<T> Function(Transaction transaction) updateFunction,
  ) async {
    return await _db.runTransaction(updateFunction);
  }

  static Future<List<T>> query<T>({
    required String collectionPath,
    required FromJson<T> fromJson,
    List<Query<Map<String, dynamic>> Function(Query<Map<String, dynamic>> q)>
        where =
        const [],
    int? limit,
    List<OrderBy> orderBy = const [],
  }) async {
    Query<Map<String, dynamic>> q = _db.collection(collectionPath);
    for (final w in where) {
      q = w(q);
    }
    for (final ob in orderBy) {
      q = q.orderBy(ob.field, descending: ob.descending);
    }
    if (limit != null) q = q.limit(limit);
    final snapshot = await q.get();
    return snapshot.docs
        .map((d) => d.data())
        .where((m) => m.isNotEmpty)
        .map(fromJson)
        .toList(growable: false);
  }
}

class OrderBy {
  final String field;
  final bool descending;
  const OrderBy(this.field, {this.descending = false});
}
