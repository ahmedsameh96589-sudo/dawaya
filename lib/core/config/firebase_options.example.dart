import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Example Firebase options — copy values into `firebase_options.dart`
/// after running `flutterfire configure`, or pass `--dart-define` in CI.
class DefaultFirebaseOptions {
  DefaultFirebaseOptions._();

  static const String apiKey = 'YOUR_FIREBASE_API_KEY';
  static const String appId = 'YOUR_FIREBASE_APP_ID';
  static const String messagingSenderId = 'YOUR_FIREBASE_MESSAGING_SENDER_ID';
  static const String projectId = 'YOUR_FIREBASE_PROJECT_ID';
  static const String iosBundleId = 'com.example.dawayaa';

  static bool get isConfigured =>
      !apiKey.startsWith('YOUR_') && !appId.startsWith('YOUR_');

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
        apiKey: apiKey,
        appId: appId,
        messagingSenderId: messagingSenderId,
        projectId: projectId,
        storageBucket: '$projectId.appspot.com',
      );

  static FirebaseOptions get ios => FirebaseOptions(
        apiKey: apiKey,
        appId: appId,
        messagingSenderId: messagingSenderId,
        projectId: projectId,
        storageBucket: '$projectId.appspot.com',
        iosBundleId: iosBundleId,
      );
}
