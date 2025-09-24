# 🔥 Firebase Setup Instructions

## Quick Setup Checklist

### ✅ Step 1: Firebase Console Setup
- [ ] Create Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
- [ ] Enable Authentication (Email/Password)
- [ ] Create Firestore Database (test mode)
- [ ] Enable Storage (optional)

### ✅ Step 2: Download Configuration Files
- [ ] Download `google-services.json` for Android
- [ ] Download `GoogleService-Info.plist` for iOS
- [ ] Place files in correct locations (see below)

### ✅ Step 3: File Placement
```
biz_module/
├── android/app/google-services.json          ← Place Android config here
├── ios/Runner/GoogleService-Info.plist      ← Place iOS config here
└── lib/core/config/firebase/firebase_config.dart  ← Already configured
```

### ✅ Step 4: Test Firebase Connection
- [ ] Run `flutter pub get`
- [ ] Run `flutter run` to test the app
- [ ] Check console for "Firebase initialized successfully"

## Detailed Instructions

### 1. Firebase Project Creation

1. **Go to Firebase Console**
   - Visit: https://console.firebase.google.com/
   - Click "Create a project"

2. **Project Settings**
   - Project name: `biz-module` (or your choice)
   - Enable Google Analytics: ✅ (recommended)
   - Click "Create project"

3. **Wait for Creation**
   - Firebase will create your project
   - Click "Continue" when ready

### 2. Add Android App

1. **Add Android App**
   - Click "Add app" → Android icon
   - Package name: `com.example.biz_module`
   - App nickname: `Biz Module Android`
   - SHA-1: Leave empty for now
   - Click "Register app"

2. **Download Config File**
   - Download `google-services.json`
   - Place in: `android/app/google-services.json`

3. **Update Android Build Files**
   - The file is already configured in `android/app/build.gradle.kts`

### 3. Add iOS App

1. **Add iOS App**
   - Click "Add app" → iOS icon
   - Bundle ID: `com.example.bizModule`
   - App nickname: `Biz Module iOS`
   - Click "Register app"

2. **Download Config File**
   - Download `GoogleService-Info.plist`
   - Place in: `ios/Runner/GoogleService-Info.plist`

3. **Update iOS Project**
   - The file will be automatically added to Xcode project

### 4. Enable Firebase Services

#### Authentication
1. Go to "Authentication" → "Get started"
2. Go to "Sign-in method" tab
3. Enable "Email/Password"
4. Optionally enable "Google" sign-in

#### Firestore Database
1. Go to "Firestore Database" → "Create database"
2. Choose "Start in test mode"
3. Select location (choose closest to your users)
4. Click "Done"

#### Storage (Optional)
1. Go to "Storage" → "Get started"
2. Choose "Start in test mode"
3. Select same location as Firestore
4. Click "Done"

### 5. Test Your Setup

1. **Install Dependencies**
   ```bash
   flutter pub get
   ```

2. **Run the App**
   ```bash
   flutter run
   ```

3. **Check Console Output**
   - Look for: "Firebase initialized successfully"
   - If you see errors, check the configuration files

### 6. Security Rules (Important!)

After testing, update your Firestore security rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only access their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Business data - only accessible by business members
    match /businesses/{businessId} {
      allow read, write: if request.auth != null && 
        request.auth.uid in resource.data.members;
    }
  }
}
```

## Troubleshooting

### Common Issues

1. **"Firebase not initialized" error**
   - Check that config files are in correct locations
   - Verify file names are exactly correct
   - Run `flutter clean && flutter pub get`

2. **Android build errors**
   - Check `android/app/build.gradle.kts` has Google Services plugin
   - Verify `google-services.json` is in correct location

3. **iOS build errors**
   - Check `GoogleService-Info.plist` is in Xcode project
   - Verify bundle ID matches Firebase configuration

4. **Authentication not working**
   - Check Authentication is enabled in Firebase Console
   - Verify sign-in methods are enabled

### Getting Help

- Check Firebase documentation: https://firebase.google.com/docs
- FlutterFire documentation: https://firebase.flutter.dev/
- Stack Overflow: Search for "Flutter Firebase" + your error

## Next Steps

Once Firebase is set up:
1. ✅ Test authentication flow
2. ✅ Set up Firestore data structure
3. ✅ Implement real authentication
4. ✅ Connect to your Next.js backend
5. ✅ Add business logic from your PRD

---

**Need help?** Check the console output and Firebase documentation. The setup should work smoothly with the provided configuration!
