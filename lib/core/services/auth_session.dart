class AuthSession {
  static String? token;
  static String? userId;
  static String? role;
  static String? name;

  static void clear() {
    token = null;
    userId = null;
    role = null;
    name = null;
  }
}
