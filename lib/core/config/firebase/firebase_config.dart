import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:biz_module/firebase_options.dart';

class FirebaseConfig {
  static FirebaseAuth? _auth;
  static FirebaseFirestore? _firestore;
  static FirebaseStorage? _storage;
  static FirebaseMessaging? _messaging;

  static FirebaseAuth get auth => _auth!;
  static FirebaseFirestore get firestore => _firestore!;
  static FirebaseStorage get storage => _storage!;
  static FirebaseMessaging get messaging => _messaging!;

  static Future<void> initialize() async {
    try {
      // For development, we'll use default initialization
      // The google-services.json and GoogleService-Info.plist files will be used automatically
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // If you need to manually specify options (for web or specific cases), uncomment below:
      // await Firebase.initializeApp(
      //   options: const FirebaseOptions(
      //     apiKey: "YOUR_API_KEY_HERE",
      //     appId: "YOUR_APP_ID_HERE",
      //     messagingSenderId: "YOUR_MESSAGING_SENDER_ID_HERE",
      //     projectId: "YOUR_PROJECT_ID_HERE",
      //     storageBucket: "YOUR_STORAGE_BUCKET_HERE",
      //   ),
      // );

      _auth = FirebaseAuth.instance;
      _firestore = FirebaseFirestore.instance;
      _storage = FirebaseStorage.instance;
      _messaging = FirebaseMessaging.instance;

      // Configure Firestore settings
      _firestore!.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );

      // Request notification permissions
      await _requestNotificationPermissions();

      if (kDebugMode) {
        print('Firebase initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing Firebase: $e');
      }
      rethrow;
    }
  }

  static Future<void> _requestNotificationPermissions() async {
    try {
      final NotificationSettings settings = await _messaging!.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (kDebugMode) {
        print('User granted permission: ${settings.authorizationStatus}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error requesting notification permissions: $e');
      }
    }
  }

  static Future<String?> getFCMToken() async {
    try {
      return await _messaging!.getToken();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting FCM token: $e');
      }
      return null;
    }
  }

  static void configureMessagingHandlers() {
    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('Got a message whilst in the foreground!');
        print('Message data: ${message.data}');

        if (message.notification != null) {
          print(
            'Message also contained a notification: ${message.notification}',
          );
        }
      }
    });

    // Handle when app is opened from notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('A new onMessageOpenedApp event was published!');
      }
      // Handle navigation based on message data
    });
  }
}

// This needs to be a top-level function
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  if (kDebugMode) {
    print('Handling a background message: ${message.messageId}');
  }
}
