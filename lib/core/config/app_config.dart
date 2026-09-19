import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

import 'google_auth_config.dart';

class AppConfig {
  AppConfig._();

  /// Web OAuth client ID — must match backend `GOOGLE_CLIENT_ID`.
  /// Set in [GoogleAuthConfig] for local dev, or pass `--dart-define=GOOGLE_WEB_CLIENT_ID=...`.
  static const String googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue: GoogleAuthConfig.webClientId,
  );

  /// iOS OAuth client ID — set the same value in `ios/Runner/Info.plist` as `GIDClientID`.
  static const String googleIosClientId = String.fromEnvironment(
    'GOOGLE_IOS_CLIENT_ID',
    defaultValue: GoogleAuthConfig.iosClientId,
  );

  static String get apiHost {
    if (kIsWeb) return 'http://localhost:5001';
    if (!kIsWeb && Platform.isAndroid) return 'http://10.0.2.2:5001';
    return 'http://localhost:5001';
  }

  static String get apiBaseUrl => '$apiHost/api';
}
