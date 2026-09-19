/// Local Google OAuth client IDs for development.
///
/// **Quick setup:** IDs below are pre-filled for this project. Run `flutter run`
/// (no `--dart-define` needed). See [GOOGLE_AUTH_SETUP.md] for Google Console
/// steps (Android SHA-1, Web client, iOS).
///
/// `--dart-define=GOOGLE_WEB_CLIENT_ID=...` overrides these values (CI/production).
class GoogleAuthConfig {
  GoogleAuthConfig._();

  /// Web OAuth client ID — must match backend `GOOGLE_CLIENT_ID`.
  /// Google Cloud Console → Credentials → **Web application** client.
  static const String webClientId = '462093455929-tmmk7lu77q1qqvldjmnj3h30mthg6jbh.apps.googleusercontent.com';

  /// iOS OAuth client ID — must match `GIDClientID` in `ios/Runner/Info.plist`.
  /// Google Cloud Console → Credentials → **iOS** client.
  static const String iosClientId = '462093455929-nalf1uq8kb9jc3mt9air8cu0h1tfain8.apps.googleusercontent.com';

  static bool get isConfigured => webClientId.isNotEmpty;
}
