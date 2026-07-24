import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

/// Firebase configuration stub.
///
/// To enable Firebase Crashlytics:
/// 1. Create a Firebase project at https://console.firebase.google.com
/// 2. Add your Android app with package name com.secondbrain.second_brain
/// 3. Run `flutterfire configure` to generate this file with real values
/// 4. The app will gracefully degrade without Firebase — Crashlytics simply won't report.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform => android;

  /// Stub configuration — app runs without Firebase.
  /// Replace with real values from `flutterfire configure`.
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: '',
    appId: '',
    messagingSenderId: '',
    projectId: '',
    storageBucket: '',
  );
}
