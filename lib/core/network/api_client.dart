import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../services/auth_session.dart';

typedef Json = Map<String, dynamic>;

/// An error response from the API, carrying the server's message.
class ApiException implements Exception {
  ApiException(this.message, {this.statusCode, this.body = const {}});

  final String message;
  final int? statusCode;

  /// The decoded error body, for endpoints that return extra data on
  /// failure (e.g. `needsVerification` on a 403 login).
  final Json body;

  @override
  String toString() => message;
}

/// The single HTTP client for the Dawaya API.
///
/// It owns the base URL, auth header, timeouts, JSON decoding and error
/// messages, so repositories only describe endpoints. When a signed-in
/// request comes back 401 (expired or revoked token), [onUnauthorized] runs
/// once so the app can sign the user out.
class ApiClient {
  ApiClient({
    http.Client? httpClient,
    String? baseUrl,
    this.onUnauthorized,
    this.timeout = const Duration(seconds: 10),
  }) : _http = httpClient ?? http.Client(),
       _baseUrl = baseUrl;

  final http.Client _http;
  final String? _baseUrl;
  final Duration timeout;
  final FutureOr<void> Function()? onUnauthorized;

  String get baseUrl => _baseUrl ?? AppConfig.apiBaseUrl;

  Map<String, String> _headers({bool json = true}) => {
    if (json) 'Content-Type': 'application/json',
    if (AuthSession.isLoggedIn) 'Authorization': 'Bearer ${AuthSession.token}',
  };

  Uri _uri(String path, [Map<String, String>? query]) {
    final uri = Uri.parse('$baseUrl$path');
    return (query == null || query.isEmpty)
        ? uri
        : uri.replace(queryParameters: query);
  }

  Future<Json> get(String path, {Map<String, String>? query}) =>
      _send(() => _http.get(_uri(path, query), headers: _headers()));

  Future<Json> post(String path, {Object? body, Duration? timeout}) => _send(
    () => _http.post(_uri(path), headers: _headers(), body: _encode(body)),
    timeout: timeout,
  );

  Future<Json> put(String path, {Object? body}) => _send(
    () => _http.put(_uri(path), headers: _headers(), body: _encode(body)),
  );

  Future<Json> delete(String path) =>
      _send(() => _http.delete(_uri(path), headers: _headers()));

  /// Uploads one file as `multipart/form-data`.
  Future<Json> upload(
    String path, {
    required String fileField,
    required String filePath,
    Map<String, String> fields = const {},
  }) {
    return _send(() async {
      final request = http.MultipartRequest('POST', _uri(path))
        ..headers.addAll(_headers(json: false))
        ..fields.addAll(fields)
        ..files.add(await http.MultipartFile.fromPath(fileField, filePath));
      return http.Response.fromStream(await _http.send(request));
    }, timeout: const Duration(seconds: 30));
  }

  String? _encode(Object? body) => body == null ? null : jsonEncode(body);

  Future<Json> _send(
    Future<http.Response> Function() request, {
    Duration? timeout,
  }) async {
    final sentToken = AuthSession.isLoggedIn;
    final http.Response response;
    try {
      response = await request().timeout(timeout ?? this.timeout);
    } on TimeoutException {
      throw ApiException(
        'The server took too long to respond. Please try again.',
      );
    } on http.ClientException {
      throw ApiException('Could not reach the server. Check your connection.');
    }

    final body = _decode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) return body;

    if (response.statusCode == 401 && sentToken) {
      await onUnauthorized?.call();
    }

    throw ApiException(
      body['message'] as String? ?? 'Request failed (${response.statusCode}).',
      statusCode: response.statusCode,
      body: body,
    );
  }

  Json _decode(String raw) {
    try {
      final decoded = jsonDecode(raw);
      return decoded is Json ? decoded : {'data': decoded};
    } catch (_) {
      return {};
    }
  }
}

/// Reads `body['data'][key]` as a list of JSON objects.
List<Json> dataList(Json body, String key) =>
    ((body['data'] as Json? ?? const {})[key] as List<dynamic>? ?? const [])
        .cast<Json>();

/// Reads `body['data'][key]` as a JSON object.
Json dataObject(Json body, String key) =>
    (body['data'] as Json? ?? const {})[key] as Json? ?? const {};

/// Overridden in `main.dart` with a client that signs the user out on 401.
final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());
