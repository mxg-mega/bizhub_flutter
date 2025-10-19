import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_model.dart';
import '../models/auth_result.dart';
import '../../core/services/auth_service.dart';

// Simple Auth State
class AuthState {
  final UserModel? user;
  final bool isLoading;
  final String? error;

  const AuthState({this.user, this.isLoading = false, this.error});

  AuthState copyWith({UserModel? user, bool? isLoading, String? error}) {
    return AuthState(
      user: user ?? this.user,
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
        if (userModel != null) {
          state = state.copyWith(user: userModel, isLoading: false);
        } else {
          // Try to get from Firestore
          final userFromFirestore = await AuthService.getUserFromFirestore(
            firebaseUser.uid,
          );
          if (userFromFirestore != null) {
            await AuthService.saveUserToLocalStorage(userFromFirestore);
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
        if (userModel != null) {
          state = state.copyWith(user: userModel);
        }
      } else {
        state = state.copyWith(user: null);
      }
    });
  }

  Future<void> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await AuthService.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    if (result.success && result.user != null) {
      state = state.copyWith(user: result.user, isLoading: false);
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
}

// Providers
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authProvider);
  return authState.user != null;
});

final currentUserProvider = Provider<UserModel?>((ref) {
  final authState = ref.watch(authProvider);
  return authState.user;
});
