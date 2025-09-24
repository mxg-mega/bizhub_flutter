import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../../shared/models/user_model.dart';
import '../../shared/models/auth_result.dart';
import '../config/firebase/firebase_config.dart';
import '../config/app_config.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseConfig.auth;
  static final FirebaseFirestore _firestore = FirebaseConfig.firestore;
  static final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Get current user
  static User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password
  static Future<AuthResult> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential userCredential = await _auth
          .signInWithEmailAndPassword(email: email, password: password);

      if (userCredential.user != null) {
        final userModel = await getUserFromFirestore(userCredential.user!.uid);
        if (userModel != null) {
          await saveUserToLocalStorage(userModel);
          return AuthResult.success(
            user: userModel,
            message: 'Sign in successful',
          );
        } else {
          return AuthResult.failure(
            message: 'User data not found. Please contact support.',
            errorCode: 'USER_DATA_NOT_FOUND',
          );
        }
      } else {
        return AuthResult.failure(
          message: 'Sign in failed. Please try again.',
          errorCode: 'SIGN_IN_FAILED',
        );
      }
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(
        message: _getAuthErrorMessage(e.code),
        errorCode: e.code,
      );
    } catch (e) {
      return AuthResult.failure(
        message: 'An unexpected error occurred. Please try again.',
        errorCode: 'UNKNOWN_ERROR',
      );
    }
  }

  // Sign up with email and password
  static Future<AuthResult> signUpWithEmailAndPassword({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      if (userCredential.user != null) {
        // Update display name
        await userCredential.user!.updateDisplayName(name);

        // Create user document in Firestore
        final userModel = UserModel(
          id: userCredential.user!.uid,
          email: email,
          name: name,
          photoUrl: userCredential.user!.photoURL,
          role: 'owner', // Default role for new users
          businessId: '', // Will be set when they create a business
          enabledModules: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await saveUserToFirestore(userModel);
        await saveUserToLocalStorage(userModel);

        return AuthResult.success(
          user: userModel,
          message: 'Account created successfully',
        );
      } else {
        return AuthResult.failure(
          message: 'Sign up failed. Please try again.',
          errorCode: 'SIGN_UP_FAILED',
        );
      }
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(
        message: _getAuthErrorMessage(e.code),
        errorCode: e.code,
      );
    } catch (e) {
      return AuthResult.failure(
        message: 'An unexpected error occurred. Please try again.',
        errorCode: 'UNKNOWN_ERROR',
      );
    }
  }

  // Sign in with Google
  static Future<AuthResult> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        return AuthResult.failure(
          message: 'Google sign in was cancelled',
          errorCode: 'GOOGLE_SIGN_IN_CANCELLED',
        );
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );

      if (userCredential.user != null) {
        // Check if user exists in Firestore
        UserModel? userModel = await getUserFromFirestore(
          userCredential.user!.uid,
        );

        if (userModel == null) {
          // Create new user if they don't exist
          userModel = UserModel(
            id: userCredential.user!.uid,
            email: userCredential.user!.email ?? '',
            name: userCredential.user!.displayName ?? 'User',
            photoUrl: userCredential.user!.photoURL,
            role: 'owner',
            businessId: '',
            enabledModules: [],
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          await saveUserToFirestore(userModel);
        }

        await saveUserToLocalStorage(userModel);
        return AuthResult.success(
          user: userModel,
          message: 'Google sign in successful',
        );
      } else {
        return AuthResult.failure(
          message: 'Google sign in failed. Please try again.',
          errorCode: 'GOOGLE_SIGN_IN_FAILED',
        );
      }
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(
        message: _getAuthErrorMessage(e.code),
        errorCode: e.code,
      );
    } catch (e) {
      return AuthResult.failure(
        message: 'An unexpected error occurred. Please try again.',
        errorCode: 'UNKNOWN_ERROR',
      );
    }
  }

  // Sign out
  static Future<AuthResult> signOut() async {
    try {
      await Future.wait([_auth.signOut(), _googleSignIn.signOut()]);

      // Clear local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConfig.userDataKey);

      return AuthResult(success: true, message: 'Signed out successfully');
    } catch (e) {
      return AuthResult.failure(
        message: 'Sign out failed. Please try again.',
        errorCode: 'SIGN_OUT_FAILED',
      );
    }
  }

  // Reset password
  static Future<AuthResult> resetPassword({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return AuthResult(success: true, message: 'Password reset email sent');
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(
        message: _getAuthErrorMessage(e.code),
        errorCode: e.code,
      );
    } catch (e) {
      return AuthResult.failure(
        message: 'Failed to send password reset email. Please try again.',
        errorCode: 'UNKNOWN_ERROR',
      );
    }
  }

  // Update user profile
  static Future<AuthResult> updateUserProfile({
    required String name,
    String? photoUrl,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return AuthResult.failure(
          message: 'No user signed in',
          errorCode: 'NO_USER',
        );
      }

      // Update Firebase Auth profile
      await user.updateDisplayName(name);
      if (photoUrl != null) {
        await user.updatePhotoURL(photoUrl);
      }

      // Update Firestore
      final userModel = await getUserFromFirestore(user.uid);
      if (userModel != null) {
        final updatedUser = userModel.copyWith(
          name: name,
          photoUrl: photoUrl ?? userModel.photoUrl,
          updatedAt: DateTime.now(),
        );
        await saveUserToFirestore(updatedUser);
        await saveUserToLocalStorage(updatedUser);
        return AuthResult.success(
          user: updatedUser,
          message: 'Profile updated successfully',
        );
      }

      return AuthResult.failure(
        message: 'Failed to update profile. Please try again.',
        errorCode: 'UPDATE_FAILED',
      );
    } catch (e) {
      return AuthResult.failure(
        message: 'Failed to update profile. Please try again.',
        errorCode: 'UNKNOWN_ERROR',
      );
    }
  }

  // Get user from Firestore
  static Future<UserModel?> getUserFromFirestore(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Save user to Firestore
  static Future<void> saveUserToFirestore(UserModel user) async {
    await _firestore.collection('users').doc(user.id).set(user.toJson());
  }

  // Save user to local storage
  static Future<void> saveUserToLocalStorage(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConfig.userDataKey, jsonEncode(user.toJson()));
  }

  // Get user from local storage
  static Future<UserModel?> getUserFromLocalStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString(AppConfig.userDataKey);
      if (userData != null) {
        return UserModel.fromJson(jsonDecode(userData));
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Get authentication error message
  static String _getAuthErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'weak-password':
        return 'Password is too weak. Please choose a stronger password.';
      case 'invalid-email':
        return 'Invalid email address. Please check and try again.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled. Please contact support.';
      case 'invalid-credential':
        return 'Invalid credentials. Please check your email and password.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with the same email but different sign-in credentials.';
      case 'credential-already-in-use':
        return 'This credential is already associated with a different user account.';
      default:
        return 'An error occurred. Please try again.';
    }
  }
}
