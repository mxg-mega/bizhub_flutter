import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../shared/models/module_state_model.dart';

class ModuleService {
  static const String _localKey = 'enabled_modules';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // NextJS primary path: businesses/{businessId}/modules/enabled
  DocumentReference _getModulesDocRef(final String businessId) {
    return _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('modules')
        .doc('enabled');
  }

  // Legacy fallback path: businesses/{businessId}/settings/modules
  DocumentReference _getLegacyModulesDocRef(final String businessId) {
    return _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('settings')
        .doc('modules');
  }

  // Fetch enabled module IDs from Firestore for a specific business
  Future<List<String>> getEnabledModuleIds(final String businessId) async {
    try {
      // 1. Try NextJS path first
      var doc = await _getModulesDocRef(businessId).get();

      // 2. Fallback to legacy path if document doesn't exist
      if (!doc.exists) {
        final legacyDoc = await _getLegacyModulesDocRef(businessId).get();
        if (legacyDoc.exists) {
          doc = legacyDoc;
        }
      }

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data != null) {
          return data.entries
              .where((final e) => ModuleStateModel.isEnabled(e.value))
              .map((final e) => e.key)
              .toList();
        }
      }
    } catch (e) {
      // Fallback to local storage if Firestore fails
      return _getLocalEnabledModuleIds();
    }
    return [];
  }

  // Fetch complete module states map
  Future<Map<String, ModuleStateModel>> getModuleStates(final String businessId) async {
    try {
      var doc = await _getModulesDocRef(businessId).get();
      if (!doc.exists) {
        final legacyDoc = await _getLegacyModulesDocRef(businessId).get();
        if (legacyDoc.exists) {
          doc = legacyDoc;
        }
      }

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data != null) {
          final Map<String, ModuleStateModel> result = {};
          data.forEach((final key, final value) {
            result[key] = ModuleStateModel.fromDynamic(value);
          });
          return result;
        }
      }
    } catch (_) {}
    return {};
  }

  // Update enabled state in Firestore
  Future<void> setModuleEnabled({
    required final String businessId,
    required final String moduleId,
    required final bool isEnabled,
    final String? userId,
    final String? version,
  }) async {
    final payload = {
      moduleId: {
        'enabled': isEnabled,
        'lastUpdated': FieldValue.serverTimestamp(),
        'installedAt': FieldValue.serverTimestamp(),
        'installedBy': userId ?? 'system',
        'version': version ?? '1.0.0',
      }
    };

    // Update NextJS path with merge
    await _getModulesDocRef(businessId).set(payload, SetOptions(merge: true));

    // If enabled, also add to global moduleInstallations collection (matching NextJS behavior)
    if (isEnabled) {
      try {
        await _firestore.collection('moduleInstallations').add({
          'moduleId': moduleId,
          'businessId': businessId,
          'installedAt': FieldValue.serverTimestamp(),
          'installedBy': userId ?? 'system',
          'version': version ?? '1.0.0',
          'status': 'active',
        });
      } catch (_) {
        // Non-fatal background audit logging
      }
    }

    // Update local cache
    await _updateLocalCache(moduleId, isEnabled);
  }

  // Real-time listener
  Stream<List<String>> subscribeToEnabledModules(final String businessId) {
    return _getModulesDocRef(businessId).snapshots().map((final snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>?;
        if (data != null) {
          final enabledIds = data.entries
              .where((final e) => ModuleStateModel.isEnabled(e.value))
              .map((final e) => e.key)
              .toList();

          // Update local storage in background
          _syncLocalCache(enabledIds);

          return enabledIds;
        }
      }
      return [];
    });
  }

  // Private helpers for local storage fallback
  Future<List<String>> _getLocalEnabledModuleIds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_localKey) ?? [];
  }

  Future<void> _updateLocalCache(final String id, final bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getStringList(_localKey) ?? [];
    if (enabled && !current.contains(id)) {
      current.add(id);
    } else if (!enabled && current.contains(id)) {
      current.remove(id);
    }
    await prefs.setStringList(_localKey, current);
  }

  Future<void> _syncLocalCache(final List<String> enabledIds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_localKey, enabledIds);
  }
}
