import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';

// Module State
class ModuleState {
  final List<String> enabledModules;
  final bool isLoading;
  final String? error;

  const ModuleState({
    this.enabledModules = const [],
    this.isLoading = false,
    this.error,
  });

  ModuleState copyWith({
    List<String>? enabledModules,
    bool? isLoading,
    String? error,
  }) {
    return ModuleState(
      enabledModules: enabledModules ?? this.enabledModules,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

// Modules Notifier
class ModulesNotifier extends StateNotifier<ModuleState> {
  ModulesNotifier() : super(const ModuleState()) {
    _loadModules();
  }

  Future<void> _loadModules() async {
    state = state.copyWith(isLoading: true);
    
    try {
      // TODO: Load modules from Firebase/local storage
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Mock enabled modules
      final enabledModules = ['inventory', 'sales'];
      state = state.copyWith(
        enabledModules: enabledModules,
        isLoading: false,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        error: error.toString(),
      );
    }
  }

  Future<void> toggleModule(String moduleName) async {
    try {
      final currentModules = List<String>.from(state.enabledModules);
      
      if (currentModules.contains(moduleName)) {
        currentModules.remove(moduleName);
      } else {
        currentModules.add(moduleName);
      }
      
      // TODO: Update modules in Firebase
      await Future.delayed(const Duration(milliseconds: 300));
      
      state = state.copyWith(enabledModules: currentModules);
    } catch (error) {
      state = state.copyWith(error: error.toString());
    }
  }

  Future<void> enableModule(String moduleName) async {
    if (!state.enabledModules.contains(moduleName)) {
      await toggleModule(moduleName);
    }
  }

  Future<void> disableModule(String moduleName) async {
    if (state.enabledModules.contains(moduleName)) {
      await toggleModule(moduleName);
    }
  }

  bool isModuleEnabled(String moduleName) {
    return state.enabledModules.contains(moduleName);
  }

  List<String> getAvailableModules() {
    return AppConfig.availableModules;
  }

  List<String> getEnabledModules() {
    return state.enabledModules;
  }

  List<String> getDisabledModules() {
    return AppConfig.availableModules
        .where((module) => !state.enabledModules.contains(module))
        .toList();
  }
}

// Providers
final modulesProvider = StateNotifierProvider<ModulesNotifier, ModuleState>((ref) {
  return ModulesNotifier();
});

final enabledModulesProvider = Provider<List<String>>((ref) {
  final modulesState = ref.watch(modulesProvider);
  return modulesState.enabledModules;
});

final isModuleEnabledProvider = Provider.family<bool, String>((ref, moduleName) {
  final modulesState = ref.watch(modulesProvider);
  return modulesState.enabledModules.contains(moduleName);
}); 