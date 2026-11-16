/*
 * firebase_options.dart
 *
 * Normally this file comes from flutterfire configure. This classwork runs
 * against the local emulator suite, so the values only need to match the demo
 * project id in .firebaserc. Firebase client config is not a secret.
 */
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Cloud Quest is an Android build for this classwork.');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'Cloud Quest is only wired up for Android in this classwork.',
        );
    }
  }

  // demo- project ids let the emulator suite run fully offline. The api key is
  // a placeholder with the right shape: the android sdk refuses to fetch a
  // token unless the key is non-empty, and the emulator never checks it.
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyB1c2D3e4F5g6H7i8J9k0L1m2N3o4P5q6R',
    appId: '1:000000000000:android:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'demo-cloud-quest',
    storageBucket: 'demo-cloud-quest.appspot.com',
  );
}
