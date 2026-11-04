import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'auth_provider.dart';
import '../../core/services/module_service.dart';

part 'modules_provider.g.dart';

@riverpod
class ModulesNotifier extends _$ModulesNotifier {
  final ModuleService _moduleService = ModuleService();
  StreamSubscription? _subscription;

  @override
  List<String> build() {
    final business = ref.watch(currentBusinessProvider);
    
    if (business == null || business.id == null) {
      return [];
    }

    // Subscribe to real-time updates
    _subscription?.cancel();
    _subscription = _moduleService.subscribeToEnabledModules(business.id!).listen((final ids) {
      state = ids;
    });

    ref.onDispose(() {
      _subscription?.cancel();
    });

    // Load initial state
    _loadInitialModules(business.id!);

    return [];
  }

  Future<void> _loadInitialModules(final String businessId) async {
    final ids = await _moduleService.getEnabledModuleIds(businessId);
    if (ids.isEmpty) {
      // Use defaults if nothing found
      state = ['inventory', 'pos', 'dashboard'];
    } else {
      state = ids;
    }
  }

  Future<void> toggleModule(final String moduleId) async {
    final business = ref.read(currentBusinessProvider);
    if (business == null || business.id == null) return;

    final isCurrentlyEnabled = state.contains(moduleId);
    final newState = !isCurrentlyEnabled;

    // Optimistic Update
    final currentModules = List<String>.from(state);
    if (newState) {
      if (!currentModules.contains(moduleId)) {
        currentModules.add(moduleId);
      }
    } else {
      currentModules.remove(moduleId);
    }
    state = currentModules;

    // Firestore Commit
    try {
      await _moduleService.setModuleEnabled(
        businessId: business.id!,
        moduleId: moduleId,
        isEnabled: newState,
      );
    } catch (e) {
      // Revert on failure if needed, or just let the stream sync it back
    }
  }

  bool isModuleEnabled(final String moduleId) => state.contains(moduleId);
}
