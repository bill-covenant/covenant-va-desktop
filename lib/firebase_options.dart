import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Firebase configuration for Covenant VA Desktop.
/// Generated from the Firebase console web app config.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
        return web; // Desktop uses web config
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAYpDz8xIg-p3CeTEahP2S6I9rqpLnt2hc',
    authDomain: 'covenant-va-platform.firebaseapp.com',
    projectId: 'covenant-va-platform',
    storageBucket: 'covenant-va-platform.firebasestorage.app',
    messagingSenderId: '906532241820',
    appId: '1:906532241820:web:9c30ed46528dcded5f0859',
  );
}
