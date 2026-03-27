import 'dart:convert';
import 'package:isar/isar.dart';

part 'sync_queue_model.g.dart';

@collection
class SyncQueueModel {
  Id id = Isar.autoIncrement;

  /// 'create' | 'update' | 'delete'
  final String action;

  /// The Firestore collection name
  final String collectionPath;

  /// The document ID in Firestore
  final String docId;

  /// The JSON payload to sync
  final String payloadJson;

  final DateTime timestamp;

  /// Number of sync attempts
  int attempts = 0;

  String? lastError;

  SyncQueueModel({
    required this.action,
    required this.collectionPath,
    required this.docId,
    required this.payloadJson,
    required this.timestamp,
  });

  @ignore
  Map<String, dynamic> get payload => jsonDecode(payloadJson);
}
