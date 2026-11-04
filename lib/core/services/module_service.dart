import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ModuleService {
  static const String _localKey = 'enabled_modules';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Fetch enabled module IDs from Firestore for a specific business
  Future<List<String>> getEnabledModuleIds(final String businessId) async {
    try {
      final doc = await _firestore
          .collection('businesses')
          .doc(businessId)
          .collection('settings')
          .doc('modules')
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        // Data is a map of module IDs to boolean states
        return data.entries
            .where((final e) => e.value == true)
            .map((final e) => e.key)
            .toList();
      }
    } catch (e) {
      // Fallback to local storage if Firestore fails
      return _getLocalEnabledModuleIds();
    }
    return [];
  }

  // Update enabled state in Firestore
  Future<void> setModuleEnabled({
    required final String businessId,
    required final String moduleId,
    required final bool isEnabled,
  }) async {
    await _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('settings')
        .doc('modules')
        .set({moduleId: isEnabled}, SetOptions(merge: true));

    // Update local cache
    await _updateLocalCache(moduleId, isEnabled);
  }

  // Real-time listener
  Stream<List<String>> subscribeToEnabledModules(final String businessId) {
    return _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('settings')
        .doc('modules')
        .snapshots()
        .map((final snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        final enabledIds = data.entries
            .where((final e) => e.value == true)
            .map((final e) => e.key)
            .toList();
        
        // Update local storage in background
        _syncLocalCache(enabledIds);
        
        return enabledIds;
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
