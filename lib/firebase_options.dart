import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Same Firebase project as the web app (vedo-01).
/// Web config values are taken directly from index.html's firebaseConfig.
///
/// TODO: Android needs its OWN registration in the Firebase console
/// (different appId, needs google-services.json). Run `flutterfire configure`
/// in the Codespace terminal later, select project "vedo-01", check
/// "android" — it will auto-update this file's android block and drop
/// android/app/google-services.json in place. Until then, Android builds
/// will throw UnsupportedError below (web testing works fine right now).
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        throw UnsupportedError(
          'Android Firebase config not set up yet. Run `flutterfire configure` '
          'in the Codespace terminal and select the vedo-01 project + Android platform.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyA81vHD1OouE3sPLzmgDUS_OH1waade5aY',
    appId: '1:1881105365:web:9a016b072ff0b3c59ed35c',
    messagingSenderId: '1881105365',
    projectId: 'vedo-01',
    authDomain: 'vedo-01.firebaseapp.com',
    storageBucket: 'vedo-01.firebasestorage.app',
  );
}
