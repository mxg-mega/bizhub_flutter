import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Simple script to verify Firebase setup
/// Run this to test if Firebase is properly configured
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    print('🔥 Testing Firebase setup...');

    // Initialize Firebase
    await Firebase.initializeApp();
    print('✅ Firebase initialized successfully');

    // Test Auth
    final auth = FirebaseAuth.instance;
    print('✅ Firebase Auth available');

    // Test Firestore
    final firestore = FirebaseFirestore.instance;
    print('✅ Firestore available');

    // Test a simple Firestore operation
    await firestore.collection('test').doc('setup').set({
      'message': 'Firebase setup is working!',
      'timestamp': FieldValue.serverTimestamp(),
    });
    print('✅ Firestore write test successful');

    // Clean up test document
    await firestore.collection('test').doc('setup').delete();
    print('✅ Firestore cleanup successful');

    print('\n🎉 Firebase setup is working perfectly!');
    print(
      'You can now proceed with implementing authentication and data operations.',
    );
  } catch (e) {
    print('❌ Firebase setup error: $e');
    print('\nTroubleshooting:');
    print('1. Check that google-services.json is in android/app/');
    print('2. Check that GoogleService-Info.plist is in ios/Runner/');
    print('3. Run flutter clean && flutter pub get');
    print('4. Verify Firebase project is created and services are enabled');
  }
}
