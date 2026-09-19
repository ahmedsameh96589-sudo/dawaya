import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// The signed-in user's session.
///
/// Values are kept in memory for fast synchronous access and mirrored to the
/// platform keychain / keystore so the user stays signed in across restarts.
class AuthSession {
  AuthSession._();

  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static const String _kToken = 'auth_token';
  static const String _kUserId = 'auth_user_id';
  static const String _kRole = 'auth_role';
  static const String _kName = 'auth_name';

  static String? token;
  static String? userId;
  static String? role;
  static String? name;

  static bool get isLoggedIn => token != null && token!.isNotEmpty;

  /// Stores a new session after a successful login.
  static Future<void> start({
    required String token,
    String? userId,
    String? role,
    String? name,
  }) async {
    AuthSession.token = token;
    AuthSession.userId = userId;
    AuthSession.role = role;
    AuthSession.name = name;
    await _persist();
  }

  static Future<void> updateName(String? name) async {
    AuthSession.name = name;
    await _write(_kName, name);
  }

  /// Loads a saved session, if any. Call once before `runApp`.
  static Future<void> restore() async {
    try {
      final values = await _storage.readAll();
      token = values[_kToken];
      userId = values[_kUserId];
      role = values[_kRole];
      name = values[_kName];
    } catch (_) {
      // Unreadable keychain (e.g. after a reinstall on iOS): start signed out.
      await clear();
    }
  }

  static Future<void> clear() async {
    token = null;
    userId = null;
    role = null;
    name = null;
    try {
      await _storage.deleteAll();
    } catch (_) {}
  }

  static Future<void> _persist() async {
    await _write(_kToken, token);
    await _write(_kUserId, userId);
    await _write(_kRole, role);
    await _write(_kName, name);
  }

  static Future<void> _write(String key, String? value) async {
    try {
      if (value == null) {
        await _storage.delete(key: key);
      } else {
        await _storage.write(key: key, value: value);
      }
    } catch (_) {}
  }
}
