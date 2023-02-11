// File generated by FlutterFire CLI.
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
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
    apiKey: 'AIzaSyBx-lVFK128d3N99sDs14sNHG_pu2dRAX0',
    appId: '1:122178755483:web:ccf35a716bb83df3f99f3e',
    messagingSenderId: '122178755483',
    projectId: 'seniorproject-3df90',
    authDomain: 'seniorproject-3df90.firebaseapp.com',
    databaseURL: 'https://seniorproject-3df90-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'seniorproject-3df90.appspot.com',
    measurementId: 'G-FYLSKP7071',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyB9KdK-K3AHUxL2gukM2o3ksJ4QW6X7lSg',
    appId: '1:122178755483:android:fc2ac1a9d0389d18f99f3e',
    messagingSenderId: '122178755483',
    projectId: 'seniorproject-3df90',
    databaseURL: 'https://seniorproject-3df90-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'seniorproject-3df90.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDR2PJhN0LUuE-EIdIcRVh8TZIDaZLINgU',
    appId: '1:122178755483:ios:6d3ec2e3d36e1e84f99f3e',
    messagingSenderId: '122178755483',
    projectId: 'seniorproject-3df90',
    databaseURL: 'https://seniorproject-3df90-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'seniorproject-3df90.appspot.com',
    iosClientId: '122178755483-ener42a608av3a890r90v8cptroctif0.apps.googleusercontent.com',
    iosBundleId: 'com.example.manager',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDR2PJhN0LUuE-EIdIcRVh8TZIDaZLINgU',
    appId: '1:122178755483:ios:6d3ec2e3d36e1e84f99f3e',
    messagingSenderId: '122178755483',
    projectId: 'seniorproject-3df90',
    databaseURL: 'https://seniorproject-3df90-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'seniorproject-3df90.appspot.com',
    iosClientId: '122178755483-ener42a608av3a890r90v8cptroctif0.apps.googleusercontent.com',
    iosBundleId: 'com.example.manager',
  );
}
