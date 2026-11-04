import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../config/firebase/firebase_config.dart';

typedef FromJson<T> = T Function(Map<String, dynamic> json);
typedef ToJson<T> = Map<String, dynamic> Function(T value);

class FirestoreService {
  FirestoreService._();

  static FirebaseFirestore get _db => FirebaseConfig.firestore;

  static CollectionReference<Map<String, dynamic>> collection(final String path) {
    return _db.collection(path);
  }

  static DocumentReference<Map<String, dynamic>> doc(final String path) {
    return _db.doc(path);
  }

  static DocumentReference<Map<String, dynamic>> docIn(
    final String collectionPath,
    final String id,
  ) {
    return _db.collection(collectionPath).doc(id);
  }

  static Map<String, dynamic> sanitizeForFirestore(final Map<String, dynamic> data) {
    final Map<String, dynamic> result = {};
    data.forEach((final key, final value) {
      if (value == null) return;
      if (value is String && _isTimestampField(key)) {
        final parsed = DateTime.tryParse(value);
        if (parsed != null) {
          result[key] = Timestamp.fromDate(parsed);
          return;
        }
      }
      if (value is DateTime) {
        result[key] = Timestamp.fromDate(value);
        return;
      }
      if (value is Map<String, dynamic>) {
        result[key] = sanitizeForFirestore(value);
        return;
      }
      result[key] = value;
    });
    return result;
  }

  static bool _isTimestampField(final String key) {
    final lower = key.toLowerCase();
    return lower.contains('date') ||
        lower.contains('time') ||
        lower.contains('createdat') ||
        lower.contains('updatedat') ||
        lower.contains('joinedat') ||
        lower.contains('timestamp');
  }

  static Future<T?> getById<T>({
    required final String collectionPath,
    required final String id,
    required final FromJson<T> fromJson,
  }) async {
    try {
      final snapshot = await _db.collection(collectionPath).doc(id).get();
      if (!snapshot.exists || snapshot.data() == null) return null;
      final data = Map<String, dynamic>.from(snapshot.data()!);
      if (!data.containsKey('id')) data['id'] = snapshot.id;
      return fromJson(data);
    } catch (e) {
      if (kDebugMode) {
        print('FirestoreService.getById error: $e');
      }
      rethrow;
    }
  }

  static Stream<T?> watchById<T>({
    required final String collectionPath,
    required final String id,
    required final FromJson<T> fromJson,
  }) {
    return _db.collection(collectionPath).doc(id).snapshots().map((final snap) {
      if (!snap.exists || snap.data() == null) return null;
      final data = Map<String, dynamic>.from(snap.data()!);
      if (!data.containsKey('id')) data['id'] = snap.id;
      return fromJson(data);
    });
  }

  static Future<void> setById<T>({
    required final String collectionPath,
    required final String id,
    required final T value,
    required final ToJson<T> toJson,
    final bool merge = false,
  }) async {
    final data = sanitizeForFirestore(toJson(value));
    await _db
        .collection(collectionPath)
        .doc(id)
        .set(data, SetOptions(merge: merge));
  }

  static Future<void> updateById({
    required final String collectionPath,
    required final String id,
    required final Map<String, dynamic> data,
  }) async {
    final sanitizedData = sanitizeForFirestore(data);
    await _db.collection(collectionPath).doc(id).update(sanitizedData);
  }

  static Future<void> deleteById({
    required final String collectionPath,
    required final String id,
  }) async {
    await _db.collection(collectionPath).doc(id).delete();
  }

  static Future<T> runTransaction<T>(
    final Future<T> Function(Transaction transaction) updateFunction,
  ) async {
    return await _db.runTransaction(updateFunction);
  }

  static Future<List<T>> query<T>({
    required final String collectionPath,
    required final FromJson<T> fromJson,
    final List<Query<Map<String, dynamic>> Function(Query<Map<String, dynamic>> q)>
        where =
        const [],
    final int? limit,
    final List<OrderBy> orderBy = const [],
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
        .map((final d) {
          final data = Map<String, dynamic>.from(d.data());
          if (!data.containsKey('id')) data['id'] = d.id;
          return data;
        })
        .where((final m) => m.isNotEmpty)
        .map(fromJson)
        .toList(growable: false);
  }
}

class OrderBy {
  final String field;
  final bool descending;
  const OrderBy(this.field, {this.descending = false});
}
