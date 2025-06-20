// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBJ38e5MYrM28fspAYoIlGD1tUvkFz0nKE',
    appId: '1:494353954202:web:c843df7d2703146f53f623',
    messagingSenderId: '494353954202',
    projectId: 'hanon-notification-82381',
    authDomain: 'hanon-notification-82381.firebaseapp.com',
    storageBucket: 'hanon-notification-82381.firebasestorage.app',
    measurementId: 'G-4EH2XH3CDR',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBtVafl4DIovp-tzlMwcGRPkqmyk1NXF4I',
    appId: '1:494353954202:android:0bfa4232935dfde753f623',
    messagingSenderId: '494353954202',
    projectId: 'hanon-notification-82381',
    storageBucket: 'hanon-notification-82381.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBBdw1V0xp1w2rLHN-mE2SIDngMP3i9Hfc',
    appId: '1:494353954202:ios:33a1c03219363aa153f623',
    messagingSenderId: '494353954202',
    projectId: 'hanon-notification-82381',
    storageBucket: 'hanon-notification-82381.firebasestorage.app',
    iosBundleId: 'com.example.hanon',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBBdw1V0xp1w2rLHN-mE2SIDngMP3i9Hfc',
    appId: '1:494353954202:ios:33a1c03219363aa153f623',
    messagingSenderId: '494353954202',
    projectId: 'hanon-notification-82381',
    storageBucket: 'hanon-notification-82381.firebasestorage.app',
    iosBundleId: 'com.example.hanon',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBJ38e5MYrM28fspAYoIlGD1tUvkFz0nKE',
    appId: '1:494353954202:web:ab92dd3632a2cdcf53f623',
    messagingSenderId: '494353954202',
    projectId: 'hanon-notification-82381',
    authDomain: 'hanon-notification-82381.firebaseapp.com',
    storageBucket: 'hanon-notification-82381.firebasestorage.app',
    measurementId: 'G-J9BC8TZ8HQ',
  );

}