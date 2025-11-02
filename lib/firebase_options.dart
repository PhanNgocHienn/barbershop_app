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
    apiKey: 'AIzaSyC4zdskH2B6_eKwtA5mIlJWHDaq-iQYMBk',
    appId: '1:137431124273:web:48796b15956d86cfa4c810',
    messagingSenderId: '137431124273',
    projectId: 'barbershop-app-1809b',
    authDomain: 'barbershop-app-1809b.firebaseapp.com',
    storageBucket: 'barbershop-app-1809b.firebasestorage.app',
    measurementId: 'G-LJP69HXMJS',
    databaseURL: 'https://barbershop-app-1809b-default-rtdb.firebaseio.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyC3qQX_wpLRBxZGPJXFAN5VIm850vIRbFs',
    appId: '1:137431124273:android:d5527a5ecf71d092a4c810',
    messagingSenderId: '137431124273',
    projectId: 'barbershop-app-1809b',
    storageBucket: 'barbershop-app-1809b.firebasestorage.app',
    databaseURL: 'https://barbershop-app-1809b-default-rtdb.firebaseio.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAV_c4lNaAMTuR-3yLtgZtNvB2bvHMzOc8',
    appId: '1:137431124273:ios:fa49805d2903d948a4c810',
    messagingSenderId: '137431124273',
    projectId: 'barbershop-app-1809b',
    storageBucket: 'barbershop-app-1809b.firebasestorage.app',
    iosBundleId: 'com.example.barbershopApp',
    databaseURL: 'https://barbershop-app-1809b-default-rtdb.firebaseio.com',
  );
}
