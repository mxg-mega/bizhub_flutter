import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/business_model.dart';
import '../models/user_model.dart';
import '../models/auth_result.dart';
import '../../core/services/auth_service.dart';

// Simple Auth State
class AuthState {
  final UserModel? user;
  final BusinessModel? activeBusiness;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.user,
    this.activeBusiness,
    this.isLoading = false,
    this.error,
  });

  AuthState copyWith({
    UserModel? user,
    bool? isLoading,
    String? error,
    BusinessModel? activeBusiness,
  }) {
    return AuthState(
      user: user ?? this.user,
      activeBusiness: activeBusiness ?? this.activeBusiness,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

// Auth Notifier
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState()) {
    _checkAuthStatus();
    _listenToAuthChanges();
  }

  Future<void> _checkAuthStatus() async {
    state = state.copyWith(isLoading: true);

    try {
      // Check if user is signed in to Firebase
      final firebaseUser = AuthService.currentUser;
      if (firebaseUser != null) {
        // Get user data from Firestore
        final userModel = await AuthService.getUserFromLocalStorage();
        final businessModel = await AuthService.getBusinessFromLocalStorage();
        if (userModel != null && businessModel != null) {
          state = state.copyWith(
            user: userModel,
            activeBusiness: businessModel,
            isLoading: false,
          );
        } else {
          // Try to get from Firestore
          final userFromFirestore = await AuthService.getUserFromFirestore(
            firebaseUser.uid,
          );

          if (userFromFirestore != null) {
            await AuthService.saveUserToLocalStorage(userFromFirestore);
            final businessFromFirestore =
                await AuthService.getBusinessFromFirestore(
                  userFromFirestore.businessIds?.first.keys.first ?? '',
                );
            if (businessFromFirestore != null) {
              state = state.copyWith(activeBusiness: businessFromFirestore);
            }
            state = state.copyWith(user: userFromFirestore, isLoading: false);
          } else {
            state = state.copyWith(isLoading: false);
          }
        }
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void _listenToAuthChanges() {
    AuthService.authStateChanges.listen((User? user) async {
      if (user != null) {
        final userModel = await AuthService.getUserFromLocalStorage();
        final businessModel = await AuthService.getBusinessFromLocalStorage();
        if (userModel != null && businessModel != null) {
          state = state.copyWith(
            user: userModel,
            activeBusiness: businessModel,
          );
        }
      } else {
        state = state.copyWith(user: null, activeBusiness: null);
      }
    });
  }

  Future<void> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await AuthService.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    if (result.success &&
        result.user != null &&
        result.activeBusiness != null) {
      // TODO: integrate tracking of active business model
      state = state.copyWith(
        user: result.user,
        activeBusiness: result.activeBusiness,
        isLoading: false,
      );
    } else {
      state = state.copyWith(isLoading: false, error: result.message);
    }
  }

  Future<void> signUp(String name, String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await AuthService.signUpWithEmailAndPassword(
      name: name,
      email: email,
      password: password,
    );

    if (result.success && result.user != null) {
      state = state.copyWith(user: result.user, isLoading: false);
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

  Future<void> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await AuthService.signInWithGoogle();

    if (result.success && result.user != null) {
      state = state.copyWith(user: result.user, isLoading: false);
    } else {
      state = state.copyWith(isLoading: false, error: result.message);
    }
  }

  Future<void> resetPassword(String email) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await AuthService.resetPassword(email: email);

    if (result.success) {
      state = state.copyWith(isLoading: false);
    } else {
      state = state.copyWith(isLoading: false, error: result.message);
    }
  }

  Future<void> updateUser(UserModel user) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await AuthService.updateUserProfile(
      // TODO: Add role and businessId and fix the name issue
      name: user.name ?? '',
      photoUrl: user.photoUrl,
    );

    if (result.success && result.user != null) {
      state = state.copyWith(user: result.user, isLoading: false);
    } else {
      state = state.copyWith(isLoading: false, error: result.message);
    }
  }

  Future<void> switchBusiness(final String businessId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final business = await AuthService.getBusinessFromFirestore(businessId);
      if (business != null) {
        await AuthService.saveBusinessToLocalStorage(business);
        state = state.copyWith(activeBusiness: business, isLoading: false);
      } else {
        state = state.copyWith(isLoading: false, error: 'Business not found');
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> updateBusinessSettings(Map<String, dynamic> newSettings) async {
    final business = state.activeBusiness;
    if (business == null) return;

    final updatedBusiness = business.copyWith(
      settings: {...?business.settings, ...newSettings},
    );

    try {
      await AuthService.saveBusinessToFirestore(updatedBusiness);
      await AuthService.saveBusinessToLocalStorage(updatedBusiness);
      state = state.copyWith(activeBusiness: updatedBusiness);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

// Providers
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authProvider);
  return authState.user != null;
});

final currentBusinessProvider = Provider<BusinessModel?>((ref) {
  final authState = ref.watch(authProvider);
  return authState.activeBusiness;
});

final currentUserProvider = Provider<UserModel?>((ref) {
  final authState = ref.watch(authProvider);
  return authState.user;
});
