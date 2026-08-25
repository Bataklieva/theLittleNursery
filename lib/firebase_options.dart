// GENERATED PLACEHOLDER — replace by running `flutterfire configure` in the
// project root once you've created a Firebase project. That command
// overwrites this file with your project's real API keys and app IDs.
//
// See README.md → "Firebase setup" for the exact steps.

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for this platform. '
          'Run `flutterfire configure` to generate them.',
        );
    }
  }

  static const web = FirebaseOptions(
    apiKey: 'REPLACE_ME',
    appId: 'REPLACE_ME',
    messagingSenderId: 'REPLACE_ME',
    projectId: 'the-little-nursery',
    storageBucket: 'the-little-nursery.appspot.com',
  );

  static const android = FirebaseOptions(
    apiKey: 'REPLACE_ME',
    appId: 'REPLACE_ME',
    messagingSenderId: 'REPLACE_ME',
    projectId: 'the-little-nursery',
    storageBucket: 'the-little-nursery.appspot.com',
  );

  static const ios = FirebaseOptions(
    apiKey: 'REPLACE_ME',
    appId: 'REPLACE_ME',
    messagingSenderId: 'REPLACE_ME',
    projectId: 'the-little-nursery',
    storageBucket: 'the-little-nursery.appspot.com',
    iosBundleId: 'bg.thelittlenursery.app',
  );
}
