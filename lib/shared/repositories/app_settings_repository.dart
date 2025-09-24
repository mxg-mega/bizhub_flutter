import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/services/firestore_service.dart';
import '../models/app_settings.dart';

class AppSettingsRepository {
  static const String collectionPath = 'app_settings';

  static Future<AppSettings?> getForUser(String userId) async {
    return FirestoreService.getById<AppSettings>(
      collectionPath: collectionPath,
      id: userId,
      fromJson: AppSettings.fromJson,
    );
  }

  static Stream<AppSettings?> watchForUser(String userId) {
    return FirestoreService.watchById<AppSettings>(
      collectionPath: collectionPath,
      id: userId,
      fromJson: AppSettings.fromJson,
    );
  }

  static Future<void> upsert(String userId, AppSettings settings) async {
    await FirestoreService.setById<AppSettings>(
      collectionPath: collectionPath,
      id: userId,
      value: settings,
      toJson: (s) => s.toJson(),
      merge: true,
    );
  }

  static Future<void> update(String userId, Map<String, dynamic> data) async {
    data['lastUpdated'] = FieldValue.serverTimestamp();
    await FirestoreService.updateById(
      collectionPath: collectionPath,
      id: userId,
      data: data,
    );
  }
}
