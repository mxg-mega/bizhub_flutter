import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/business_model.dart';
import '../models/user_model.dart';
import '../models/auth_result.dart';
import '../models/membership_model.dart';
import '../models/permission_model.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/role_service.dart';

// Enhanced Auth State
class AuthState {
  final UserModel? user;
  final BusinessModel? activeBusiness;
  final MembershipModel? currentMembership;
  final RoleModel? currentRole;
  final bool isLoading;
  final bool isOnboarding; // Business Onboarding
  final bool isInitialOnboardingDone; // App Initial Onboarding
  final String? error;

  const AuthState({
    this.user,
    this.activeBusiness,
    this.currentMembership,
    this.currentRole,
    this.isLoading = false,
    this.isOnboarding = false,
    this.isInitialOnboardingDone = false,
    this.error,
  });

  AuthState copyWith({
    final UserModel? user,
    final BusinessModel? activeBusiness,
    final MembershipModel? currentMembership,
    final RoleModel? currentRole,
    final bool? isLoading,
    final bool? isOnboarding,
    final bool? isInitialOnboardingDone,
    final String? error,
  }) {
    return AuthState(
      user: user ?? this.user,
      activeBusiness: activeBusiness ?? this.activeBusiness,
      currentMembership: currentMembership ?? this.currentMembership,
      currentRole: currentRole ?? this.currentRole,
      isLoading: isLoading ?? this.isLoading,
      isOnboarding: isOnboarding ?? this.isOnboarding,
      isInitialOnboardingDone:
          isInitialOnboardingDone ?? this.isInitialOnboardingDone,
      error: error ?? this.error,
    );
  }
}

// Auth Notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final RoleService _roleService = RoleService();

  AuthNotifier() : super(const AuthState()) {
    _initialize();
  }

  Future<void> _initialize() async {
    final isInitialDone = await AuthService.isOnboardingCompleted();
    state = state.copyWith(isInitialOnboardingDone: isInitialDone);
    await _checkAuthStatus();
    _listenToAuthChanges();
  }

  Future<void> _checkAuthStatus() async {
    state = state.copyWith(isLoading: true);

    try {
      final firebaseUser = AuthService.currentUser;
      if (firebaseUser != null) {
        final userModel = await AuthService.getUserFromLocalStorage();

        if (userModel != null) {
          final businessModel = await AuthService.getBusinessFromLocalStorage();
          debugPrint(
            '[debug] User and business loaded from local storage: ${userModel.id}, ${businessModel?.toString()}',
          );
          if (businessModel == null) {
            debugPrint(
              '[debug] No business found in local storage for user: ${userModel.id}',
            );
          }
          if (!userModel.onboardingCompleted || userModel.businessIds.isEmpty) {
            state = state.copyWith(
              user: userModel,
              activeBusiness:
                  businessModel, // Still set it if we have it locally
              isLoading: false,
              isOnboarding: true,
            );
            debugPrint(
              '[debug] User onboarding not completed or no businesses: ${userModel.id}',
            );
            if (businessModel != null &&
                userModel.businessIds.contains(businessModel.id)) {
              await _fetchMembershipAndRole(userModel.id, businessModel.id!);
            }
            return;
          }

          if (businessModel != null) {
            state = state.copyWith(
              user: userModel,
              activeBusiness: businessModel,
              isLoading: false,
              isOnboarding: false,
            );
            await _fetchMembershipAndRole(userModel.id, businessModel.id!);
          } else {
            // Business not in local storage but onboarding is done, try to fetch first business
            final firstBusinessId = userModel.businessIds.first;
            final businessFromFirestore =
                await AuthService.getBusinessFromFirestore(firstBusinessId);
            if (businessFromFirestore != null) {
              await AuthService.saveBusinessToLocalStorage(
                businessFromFirestore,
              );
              state = state.copyWith(
                user: userModel,
                activeBusiness: businessFromFirestore,
                isLoading: false,
                isOnboarding: false,
              );
              await _fetchMembershipAndRole(userModel.id, firstBusinessId);
            }
          }
        } else {
          // No user in local storage, fetch from firestore
          final userFromFirestore = await AuthService.getUserFromFirestore(
            firebaseUser.uid,
          );
          if (userFromFirestore != null) {
            await AuthService.saveUserToLocalStorage(userFromFirestore);

            if (!userFromFirestore.onboardingCompleted ||
                userFromFirestore.businessIds.isEmpty) {
              state = state.copyWith(
                user: userFromFirestore,
                isLoading: false,
                isOnboarding: true,
              );
            } else {
              final businessId = userFromFirestore.businessIds.first;
              final businessFromFirestore =
                  await AuthService.getBusinessFromFirestore(businessId);
              if (businessFromFirestore != null) {
                await AuthService.saveBusinessToLocalStorage(
                  businessFromFirestore,
                );
                state = state.copyWith(
                  user: userFromFirestore,
                  activeBusiness: businessFromFirestore,
                  isLoading: false,
                  isOnboarding: false,
                );
                await _fetchMembershipAndRole(userFromFirestore.id, businessId);
              }
            }
          }
        }
      }
      state = state.copyWith(isLoading: false);
    } catch (e) {
      debugPrint('Error checking auth status: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> _fetchMembershipAndRole(
    final String userId,
    final String businessId,
  ) async {
    try {
      final membership = await _roleService.getMembership(
        businessId: businessId,
        userId: userId,
      );
      if (membership != null) {
        final role = await _roleService.getRole(
          businessId: businessId,
          roleId: membership.roleId,
        );
        state = state.copyWith(
          currentMembership: membership,
          currentRole: role,
        );
      }
    } catch (e) {
      // Log error but don't break auth state
      print('[AuthNotifier]: Error fetching membership and role: $e');
    }
  }

  void _listenToAuthChanges() {
    AuthService.authStateChanges.listen((final User? user) async {
      if (user != null) {
        await _checkAuthStatus();
      } else {
        state = const AuthState();
      }
    });
  }

  Future<void> signIn(final String email, final String password) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await AuthService.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    if (result.success && result.user != null) {
      if (!result.user!.onboardingCompleted ||
          result.user!.businessIds.isEmpty) {
        state = state.copyWith(
          user: result.user,
          isLoading: false,
          isOnboarding: true,
        );
      } else if (result.activeBusiness != null) {
        state = state.copyWith(
          user: result.user,
          activeBusiness: result.activeBusiness,
          isLoading: false,
          isOnboarding: false,
        );
        await _fetchMembershipAndRole(
          result.user!.id,
          result.activeBusiness!.id!,
        );
      }
    } else {
      state = state.copyWith(isLoading: false, error: result.message);
    }
  }

  Future<void> signUp(
    final String name,
    final String email,
    final String password,
  ) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await AuthService.signUpWithEmailAndPassword(
      name: name,
      email: email,
      password: password,
    );

    if (result.success && result.user != null) {
      state = state.copyWith(
        user: result.user,
        isLoading: false,
        isOnboarding: true, // New users always need onboarding
      );
    } else {
      state = state.copyWith(isLoading: false, error: result.message);
    }
  }

  Future<void> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await AuthService.signInWithGoogle();

    if (result.success && result.user != null) {
      if (!result.user!.onboardingCompleted ||
          result.user!.businessIds.isEmpty) {
        state = state.copyWith(
          user: result.user,
          isLoading: false,
          isOnboarding: true,
        );
      } else if (result.activeBusiness != null) {
        state = state.copyWith(
          user: result.user,
          activeBusiness: result.activeBusiness,
          isLoading: false,
          isOnboarding: false,
        );
        await _fetchMembershipAndRole(
          result.user!.id,
          result.activeBusiness!.id!,
        );
      } else {
        // User has businesses but none is active (e.g., first login after onboarding)
        state = state.copyWith(
          user: result.user,
          isLoading: false,
          isOnboarding: false,
        );
        if (result.user!.businessIds.isNotEmpty) {
          // Auto-select the first business
          await switchBusiness(result.user!.businessIds.first);
        }
      }
    } else {
      state = state.copyWith(isLoading: false, error: result.message);
    }
  }

  Future<void> resetPassword(final String email) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await AuthService.sendPasswordResetEmail(email);

    if (result.success) {
      state = state.copyWith(isLoading: false);
    } else {
      state = state.copyWith(isLoading: false, error: result.message);
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await AuthService.signOut();
    if (result.success) {
      state = const AuthState();
    } else {
      state = state.copyWith(isLoading: false, error: result.message);
    }
  }

  Future<void> completeOnboarding() async {
    // This is called when the BusinessService.createBusinessWithOnboarding finishes
    // We just need to refresh our state
    await _checkAuthStatus();
  }

  Future<void> setInitialOnboardingDone() async {
    await AuthService.setOnboardingCompleted();
    state = state.copyWith(isInitialOnboardingDone: true);
  }

  Future<void> switchBusiness(final String businessId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final business = await AuthService.getBusinessFromFirestore(businessId);
      if (business != null) {
        await AuthService.saveBusinessToLocalStorage(business);
        state = state.copyWith(activeBusiness: business, isOnboarding: false);
        if (state.user != null) {
          await _fetchMembershipAndRole(state.user!.id, businessId);
        }
        state = state.copyWith(isLoading: false);
      } else {
        state = state.copyWith(isLoading: false, error: 'Business not found');
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> updateActiveBusiness(final BusinessModel updatedBusiness) async {
    await AuthService.saveBusinessToLocalStorage(updatedBusiness);
    state = state.copyWith(activeBusiness: updatedBusiness);
  }
}

// Providers
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((
  final ref,
) {
  return AuthNotifier();
});

final currentRoleProvider = Provider<RoleModel?>((final ref) {
  final authState = ref.watch(authProvider);
  return authState.currentRole;
});

final currentMembershipProvider = Provider<MembershipModel?>((final ref) {
  final authState = ref.watch(authProvider);
  return authState.currentMembership;
});

final currentBusinessProvider = Provider<BusinessModel?>((final ref) {
  final authState = ref.watch(authProvider);
  return authState.activeBusiness;
});

final currentUserProvider = Provider<UserModel?>((final ref) {
  final authState = ref.watch(authProvider);
  return authState.user;
});
