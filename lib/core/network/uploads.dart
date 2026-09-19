import '../config/app_config.dart';
import '../services/auth_session.dart';

/// URLs and headers for files the backend serves from `/uploads`.
class Uploads {
  Uploads._();

  /// Turns a stored path (`/uploads/x.png`, `x.png`, or a full URL) into a
  /// loadable URL.
  static String resolve(String path) {
    if (path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    if (path.startsWith('/uploads')) return '${AppConfig.apiHost}$path';
    return '${AppConfig.apiHost}/uploads/$path';
  }

  /// Headers for private uploads (prescriptions, chat attachments), which
  /// the backend only serves to signed-in users and doctors.
  static Map<String, String> get headers => {
    if (AuthSession.isLoggedIn) 'Authorization': 'Bearer ${AuthSession.token}',
  };
}
