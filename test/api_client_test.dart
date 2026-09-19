import 'dart:async';
import 'dart:convert';

import 'package:dawayaa/core/network/api_client.dart';
import 'package:dawayaa/core/services/auth_session.dart';
import 'package:dawayaa/features/auth/data/auth_repository.dart';
import 'package:dawayaa/features/catalog/data/catalog_repository.dart';
import 'package:dawayaa/features/chat/data/chat_repository.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

http.Response json(Object body, [int status = 200]) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
);

ApiClient clientFor(
  MockClientHandler handler, {
  FutureOr<void> Function()? onUnauthorized,
}) => ApiClient(
  httpClient: MockClient(handler),
  baseUrl: 'https://api.test/api',
  onUnauthorized: onUnauthorized,
);

void main() {
  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    await AuthSession.clear();
  });

  group('ApiClient', () {
    test('sends the bearer token when signed in', () async {
      await AuthSession.start(token: 'abc');
      late http.Request sent;
      final api = clientFor((req) async {
        sent = req;
        return json({'ok': true});
      });

      await api.get('/cart');

      expect(sent.url.toString(), 'https://api.test/api/cart');
      expect(sent.headers['Authorization'], 'Bearer abc');
    });

    test('sends no token when signed out', () async {
      late http.Request sent;
      final api = clientFor((req) async {
        sent = req;
        return json({});
      });

      await api.get('/categories');

      expect(sent.headers.containsKey('Authorization'), isFalse);
    });

    test(
      'turns error responses into ApiException with the server message',
      () async {
        final api = clientFor(
          (_) async => json({'message': 'Out of stock'}, 400),
        );

        expect(
          () => api.post('/cart/add', body: {}),
          throwsA(
            isA<ApiException>()
                .having((e) => e.message, 'message', 'Out of stock')
                .having((e) => e.statusCode, 'statusCode', 400),
          ),
        );
      },
    );

    test('signs out when a signed-in request is rejected with 401', () async {
      await AuthSession.start(token: 'expired');
      var calls = 0;
      final api = clientFor(
        (_) async => json({'message': 'Invalid or expired token.'}, 401),
        onUnauthorized: () => calls++,
      );

      await expectLater(api.get('/orders'), throwsA(isA<ApiException>()));
      expect(calls, 1);
    });

    test('a 401 on login (wrong password) does not trigger sign-out', () async {
      var calls = 0;
      final api = clientFor(
        (_) async => json({'message': 'Invalid credentials.'}, 401),
        onUnauthorized: () => calls++,
      );

      await expectLater(api.post('/auth/login'), throwsA(isA<ApiException>()));
      expect(calls, 0);
    });

    test('reports a friendly message when the server is unreachable', () async {
      final api = clientFor((_) async => throw http.ClientException('refused'));

      expect(
        () => api.get('/news'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            contains('Could not reach the server'),
          ),
        ),
      );
    });
  });

  group('repositories', () {
    test('catalog search encodes the query', () async {
      late Uri url;
      final repo = CatalogRepository(
        clientFor((req) async {
          url = req.url;
          return json({
            'data': {'medicines': []},
          });
        }),
      );

      await repo.fetchMedicines(search: 'بنادول & co');

      expect(url.queryParameters['search'], 'بنادول & co');
    });

    test('login returns needsVerification for unverified accounts', () async {
      final repo = AuthRepository(
        clientFor(
          (_) async => json({
            'message': 'Please verify your account.',
            'data': {'userId': 'u1', 'needsVerification': true},
          }, 403),
        ),
      );

      final result = await repo.login(email: 'a@b.com', password: 'x');

      expect(result.needsVerification, isTrue);
      expect(result.userId, 'u1');
    });

    test('doctor login skips OTP and returns the token', () async {
      final repo = AuthRepository(
        clientFor(
          (_) async => json({
            'token': 'doc-jwt',
            'data': {'userId': 'd1', 'role': 'doctor', 'name': 'Dr. Mona'},
          }),
        ),
      );

      final result = await repo.login(email: 'dr@b.com', password: 'x');

      expect(result.skipOtp, isTrue);
      expect(result.token, 'doc-jwt');
    });

    test('verifying an OTP starts the session', () async {
      final repo = AuthRepository(
        clientFor(
          (_) async => json({
            'token': 'user-jwt',
            'data': {
              'user': {'role': 'user', 'name': 'Ahmed'},
            },
          }),
        ),
      );

      await repo.verifyOtp(userId: 'u1', otp: '123456', purpose: 'login');

      expect(AuthSession.token, 'user-jwt');
      expect(AuthSession.name, 'Ahmed');
    });

    test('starting a consultation reuses the open one', () async {
      await AuthSession.start(token: 'jwt', role: 'user');
      final requested = <String>[];
      final repo = ChatRepository(
        clientFor((req) async {
          requested.add('${req.method} ${req.url.path}');
          if (req.method == 'POST') {
            return json({
              'message': 'Already open',
              'data': {'consultationId': 'c9'},
            }, 400);
          }
          return json({
            'data': {
              'consultation': {'_id': 'c9', 'messages': []},
            },
          });
        }),
      );

      final consultation = await repo.startConsultation(doctorId: 'd1');

      expect(consultation.id, 'c9');
      expect(requested, [
        'POST /api/consultations',
        'GET /api/consultations/c9',
      ]);
    });
  });
}
