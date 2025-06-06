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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for ios - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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
    apiKey: 'AIzaSyDbneH-vQuzRopmaw-HvgsoY29dbfr1pLE',
    appId: '1:959672649851:web:a86c63fb4709e176f3fade',
    messagingSenderId: '959672649851',
    projectId: 'cook-56d92',
    authDomain: 'cook-56d92.firebaseapp.com',
    storageBucket: 'cook-56d92.firebasestorage.app',
    measurementId: 'G-4R1VDNE5B5',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyB6bEWqmzlPAFdWfNbcsLRLrjZ-qxYGRQI',
    appId: '1:959672649851:android:868b8a53ccfb19f6f3fade',
    messagingSenderId: '959672649851',
    projectId: 'cook-56d92',
    storageBucket: 'cook-56d92.firebasestorage.app',
  );
}
