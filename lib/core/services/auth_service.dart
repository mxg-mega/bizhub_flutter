import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../../shared/models/business_model.dart';
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
    required final String email,
    required final String password,
  }) async {
    try {
      // TODO: remove all debug prints
      final UserCredential userCredential = await _auth
          .signInWithEmailAndPassword(email: email, password: password);
      debugPrint('userCredential: $userCredential');
      debugPrint('userCredential.user: ${userCredential.user}');
      debugPrint('userCredential.user!.uid: ${userCredential.user!.uid}');
      debugPrint('userCredential.user!.email: ${userCredential.user!.email}');

      if (userCredential.user != null) {
        final userModel = await getUserFromFirestore(userCredential.user!.uid);
        debugPrint('userModel: ${userModel?.toJson()}');
        final businessModel = await getBusinessFromFirestore(
          userModel?.businessIds!.first.keys.first ?? '',
        );
        debugPrint('Business info Model : ${businessModel?.toJson()}');
        if (userModel != null && businessModel != null) {
          await saveUserToLocalStorage(userModel);
          debugPrint('saveUserToLocalStorage: $userModel');
          try {
            debugPrint(
              '====================Trying to save to local storage===============',
            );
            await saveBusinessToLocalStorage(businessModel);
            debugPrint('saveBusinessToLoacalStorage: $businessModel');
          } catch (e) {
            debugPrint(e.toString());
          }

          return AuthResult.success(
            user: userModel,
            activeBusiness: businessModel,
            message: 'Sign in successful',
          );
        } else {
          debugPrint('User data not found. Please contact support.');
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
          uid: userCredential.user!.uid,
          email: email,
          name: name,
          photoUrl: userCredential.user!.photoURL,
          role: 'owner', // Default role for new users
          businessIds: [], // Will be set when they create a business
          enabledModules: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // TODO: refactor firebase user saving to include membership creation, and setting default values
        //        saving them to proper paths based on live schema
        await saveUserToFirestore(userModel);
        await saveUserToLocalStorage(userModel);

        // TODO: implement business data creation and saving to proper paths based on the Llive MVP schema
        // TODO: also implement seeding of data and path (sub-collection) initializations

        return AuthResult.success(
          // TODO: implement business Model
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
            uid: userCredential.user!.uid,
            email: userCredential.user!.email ?? '',
            name: userCredential.user!.displayName ?? 'User',
            photoUrl: userCredential.user!.photoURL,
            role: 'owner',
            businessIds: [],
            enabledModules: [],
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          await saveUserToFirestore(userModel);
        }

        await saveUserToLocalStorage(userModel);
        return AuthResult.success(
          // TODO: implement businessModel
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
      await prefs.remove(AppConfig.businessDataKey);

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
      // TODO: implement an actual update logic according to the Live MVP
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
          // TODO: implement business model
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
  static Future<UserModel?> getUserFromFirestore(final String uid) async {
    debugPrint('getUserFromFirestore: $uid');
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      debugPrint('doc: ${doc.data()!}');
      debugPrint('doc.data()![\'displayName\']: ${doc.data()!['displayName']}');
      if (doc.exists) {
        final userModel = UserModel.fromJson(doc.data()!);
        final businessIDsRef = await _firestore
            .collection('users')
            .doc(uid)
            .collection('memberships')
            .get();
        final List<Map<String, dynamic>> businessIDs = [];

        for (QueryDocumentSnapshot snapshot in businessIDsRef.docs) {
          debugPrint('Member id: ${snapshot.id}');
          businessIDs.add({
            snapshot.id: snapshot.data()! as Map<String, dynamic>,
          });
        }
        debugPrint('getUserFromFirestore: ${userModel.toJson()}');
        return userModel.copyWith(
          name: doc.data()!['displayName'] as String?,
          businessIds: businessIDs,
        );
      }
      return null;
    } catch (e) {
      debugPrint('getUserFromFirestore error: $e');
      return null;
    }
  }

  // Save user to Firestore
  static Future<void> saveUserToFirestore(UserModel user) async {
    await _firestore.collection('users').doc(user.uid).set(user.toJson());
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

  // Helper to convert Firestore Timestamps to JSON-encodable strings
  static dynamic _convertTimestamps(dynamic value) {
    if (value is Timestamp) {
      return value.toDate().toIso8601String();
    }
    if (value is Map) {
      return value.map((key, val) => MapEntry(key, _convertTimestamps(val)));
    }
    if (value is List) {
      return value.map((e) => _convertTimestamps(e)).toList();
    }
    return value;
  }

  // Get business from Firestore
  static Future<BusinessModel?> getBusinessFromFirestore(
    final String businessId,
  ) async {
    try {
      final doc = await _firestore
          .collection('businesses')
          .doc(businessId)
          .get();
      debugPrint('getBusinessFromFirestore: $businessId');
      debugPrint('getBusinessFromFirestore doc: ${doc.data()!}');

      final infoDoc = await _firestore
          .collection('businesses')
          .doc(businessId)
          .collection('settings')
          .doc('info')
          .get();
      debugPrint('getBusinessFromFirestore infoDoc: ${infoDoc.data()!}');

      final modulesDoc = await _firestore
          .collection('businesses')
          .doc(businessId)
          .collection('modules')
          .doc('enabled')
          .get();
      debugPrint('getBusinessFromFirestore modulesDoc: ${modulesDoc.data()!}');
      Map<String, dynamic>? modules = modulesDoc.data();
      if (modules != null) {
        modules = modules.map(
          (key, value) => MapEntry(key, _convertTimestamps(value)),
        );
      }

      final infoData = infoDoc.data()!;
      final name = infoData['name'];
      final category = infoData['category'];
      final address = infoData['address'];
      final phone = infoData['phone'];
      final email = infoData['email'];
      final website = infoData['website'];
      if (doc.exists) {
        debugPrint('doc.data()![\'name\']: ${doc.data()!['name']}');
        final data = doc.data()!;
        final convertedData = data.map(
          (final key, final value) => MapEntry(key, _convertTimestamps(value)),
        );
        final businessModel = BusinessModel.fromJson(convertedData);
        debugPrint('getBusinesModel : ${businessModel.toJson()}');

        final convertedBusinessModel = businessModel.copyWith(
          id: businessId,
          name: name,
          ownerId: data['ownerId'],
          category: category,
          address: address,
          phone: phone,
          email: email,
          website: website,
          enabledModules: modules,
        );
        return convertedBusinessModel;
      }
      return null;
    } catch (e) {
      debugPrint('getBusinessFromFirestore error: $e');
      return null;
    }
  }

  // Save business to Firestore
  static Future<void> saveBusinessToFirestore(BusinessModel business) async {
    // TODO: Further break down of saving will be done later and also improved later
    await _firestore
        .collection('businesses')
        .doc(business.id)
        .set(business.toJson());
  }

  // Save business to local storage
  static Future<void> saveBusinessToLocalStorage(BusinessModel business) async {
    // TODO: Further break down of saving will be done later and also improved later
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      AppConfig.businessDataKey,
      jsonEncode(business.toJson()),
    );
  }

  static Future<void> switchActiveBusiness(final String businessId) async {
    try {
      final business = await getBusinessFromFirestore(businessId);
      await saveBusinessToLocalStorage(business!);
    } catch (e) {
      debugPrint('Switch Error:  ${e.toString()}');
      throw Exception('Could not Switch Businesses');
    }
  }

  // Get business from local storage
  static Future<BusinessModel?> getBusinessFromLocalStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final businessData = prefs.getString(AppConfig.businessDataKey);
      if (businessData != null) {
        return BusinessModel.fromJson(jsonDecode(businessData));
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
