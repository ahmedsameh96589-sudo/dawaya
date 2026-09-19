import 'package:dawayaa/core/services/auth_session.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  test('a started session survives an app restart', () async {
    await AuthSession.start(token: 'jwt', userId: 'u1', role: 'user', name: 'Ahmed');

    // Simulate a cold start: memory is empty, storage is not.
    AuthSession.token = null;
    AuthSession.name = null;
    await AuthSession.restore();

    expect(AuthSession.isLoggedIn, isTrue);
    expect(AuthSession.userId, 'u1');
    expect(AuthSession.name, 'Ahmed');
  });

  test('clear signs the user out everywhere', () async {
    await AuthSession.start(token: 'jwt', userId: 'u1');
    await AuthSession.clear();
    await AuthSession.restore();

    expect(AuthSession.isLoggedIn, isFalse);
    expect(AuthSession.userId, isNull);
  });

  test('updateName persists the new name', () async {
    await AuthSession.start(token: 'jwt', name: 'Old');
    await AuthSession.updateName('New');
    AuthSession.name = null;
    await AuthSession.restore();

    expect(AuthSession.name, 'New');
  });

  test('restoring with nothing saved leaves the user signed out', () async {
    await AuthSession.restore();

    expect(AuthSession.isLoggedIn, isFalse);
  });
}
