import 'dart:async';
import 'dart:io';
import 'package:dawayaa/core/services/auth_session.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../presentation/prescription_request.dart';


class PrescriptionService {
  PrescriptionService._();
  static final PrescriptionService instance = PrescriptionService._();

  static const String _baseUrl = 'http://10.0.2.2:5001/api';

  // ── BUG FIX: Removed the separate _token field and setToken().
  // PrescriptionService now reads directly from AuthSession.token,
  // the same single source of truth that ApiService uses.
  // Before this fix, setToken() was never called after login, so
  // _token was always null → every request got "Invalid or expired token".
  Map<String, String> get _authHeaders => {
        'Authorization': 'Bearer ${AuthSession.token ?? ''}',
      };

  Map<String, String> get _jsonHeaders => {
        'Authorization': 'Bearer ${AuthSession.token ?? ''}',
        'Content-Type': 'application/json',
      };

  // ── Submit prescription (multipart upload) ──────────────────────────────────
  Future<String> submitPrescription({
    required String productId,
    required String productName,
    required File imageFile,
  }) async {
    final uri     = Uri.parse('$_baseUrl/prescriptions');
    final request = http.MultipartRequest('POST', uri)
      ..headers.addAll(_authHeaders)
      ..fields['productId']   = productId
      ..fields['productName'] = productName
      ..files.add(await http.MultipartFile.fromPath('prescription', imageFile.path));

    final streamed  = await request.send();
    final response  = await http.Response.fromStream(streamed);

    if (response.statusCode != 201) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final err  = body['message'] ?? body['error'] ?? 'Upload failed';
      throw Exception(err);
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return body['data']['prescription']['_id'] as String;
  }

  // ── Poll a single prescription every 5 seconds ─────────────────────────────
  Stream<PrescriptionRequest?> watchRequest(String requestId) async* {
    while (true) {
      try {
        final uri      = Uri.parse('$_baseUrl/prescriptions/$requestId');
        final response = await http.get(uri, headers: _authHeaders);

        if (response.statusCode == 200) {
          final body         = jsonDecode(response.body) as Map<String, dynamic>;
          final prescription = body['data']['prescription'] as Map<String, dynamic>;
          yield PrescriptionRequest.fromJson(prescription);
        } else {
          yield null;
        }
      } catch (_) {
        yield null;
      }
      await Future.delayed(const Duration(seconds: 5));
    }
  }

  // ── Admin: fetch all pending prescriptions ──────────────────────────────────
  Future<List<PrescriptionRequest>> fetchPending() async {
    final uri      = Uri.parse('$_baseUrl/admin/prescriptions?status=pending_review');
    final response = await http.get(uri, headers: _authHeaders);

    if (response.statusCode != 200) {
      throw Exception('Failed to load prescriptions');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final list = body['data']['prescriptions'] as List<dynamic>;
    return list
        .map((e) => PrescriptionRequest.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── Admin: approve ──────────────────────────────────────────────────────────
  Future<void> approve(String id, {String? note}) async {
    final uri      = Uri.parse('$_baseUrl/admin/prescriptions/$id/review');
    final response = await http.put(
      uri,
      headers: _jsonHeaders,
      body: jsonEncode({
        'status':     'approved',
        'reviewNote': note ?? '',
      }),
    );
    if (response.statusCode != 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(body['message'] ?? 'Approve failed');
    }
  }

  // ── Admin: reject ───────────────────────────────────────────────────────────
  Future<void> reject(String id, {String? note}) async {
    final uri      = Uri.parse('$_baseUrl/admin/prescriptions/$id/review');
    final response = await http.put(
      uri,
      headers: _jsonHeaders,
      body: jsonEncode({
        'status':     'rejected',
        'reviewNote': note ?? '',
      }),
    );
    if (response.statusCode != 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(body['message'] ?? 'Reject failed');
    }
  }
}