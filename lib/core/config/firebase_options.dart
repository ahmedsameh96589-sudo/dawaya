import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Firebase options for DAWAYA push notifications (project: dawaya-366c3).
///
/// Values match `android/app/google-services.json` and
/// `ios/Runner/GoogleService-Info.plist`. Override in CI with `--dart-define`.
class DefaultFirebaseOptions {
  DefaultFirebaseOptions._();

  static const String _projectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
    defaultValue: 'dawaya-366c3',
  );
  static const String _messagingSenderId = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
    defaultValue: '1079464992241',
  );
  static const String _storageBucket = String.fromEnvironment(
    'FIREBASE_STORAGE_BUCKET',
    defaultValue: 'dawaya-366c3.firebasestorage.app',
  );

  static const String _androidApiKey = String.fromEnvironment(
    'FIREBASE_ANDROID_API_KEY',
    defaultValue: 'AIzaSyDqpmXstLc7a_FsVlP7ePZckug-go_Aqdw',
  );
  static const String _androidAppId = String.fromEnvironment(
    'FIREBASE_ANDROID_APP_ID',
    defaultValue: '1:1079464992241:android:15d41629bab73e76b83850',
  );

  static const String _iosApiKey = String.fromEnvironment(
    'FIREBASE_IOS_API_KEY',
    defaultValue: 'AIzaSyBB_txYUyYFdWQyn6bxZrRjk-rEeGnv_Lc',
  );
  static const String _iosAppId = String.fromEnvironment(
    'FIREBASE_IOS_APP_ID',
    defaultValue: '1:1079464992241:ios:9951744a9acaf150b83850',
  );
  static const String _iosBundleId = String.fromEnvironment(
    'FIREBASE_IOS_BUNDLE_ID',
    defaultValue: 'com.example.dawayaa',
  );

  static bool get isConfigured =>
      _projectId.isNotEmpty &&
      !_projectId.startsWith('YOUR_') &&
      _androidApiKey.isNotEmpty &&
      !_androidApiKey.startsWith('YOUR_') &&
      _androidAppId.isNotEmpty &&
      !_androidAppId.startsWith('YOUR_') &&
      _iosApiKey.isNotEmpty &&
      !_iosApiKey.startsWith('YOUR_') &&
      _iosAppId.isNotEmpty &&
      !_iosAppId.startsWith('YOUR_');

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Push notifications are not configured for web.');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'Push notifications are not supported on $defaultTargetPlatform.',
        );
    }
  }

  static FirebaseOptions get android => FirebaseOptions(
        apiKey: _androidApiKey,
        appId: _androidAppId,
        messagingSenderId: _messagingSenderId,
        projectId: _projectId,
        storageBucket: _storageBucket,
      );

  static FirebaseOptions get ios => FirebaseOptions(
        apiKey: _iosApiKey,
        appId: _iosAppId,
        messagingSenderId: _messagingSenderId,
        projectId: _projectId,
        storageBucket: _storageBucket,
        iosBundleId: _iosBundleId,
      );
}
