import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/services/auth_session.dart';

class LoginResult {
  const LoginResult({
    required this.userId,
    required this.needsVerification,
    required this.message,
    this.skipOtp = false,
    this.token,
    this.role,
    this.name,
  });

  final String userId;
  final bool needsVerification;
  final String message;

  /// Doctor accounts log in directly (no OTP on User collection).
  final bool skipOtp;
  final String? token;
  final String? role;
  final String? name;
}

class VerifyOtpResult {
  const VerifyOtpResult({
    this.token,
    this.resetToken,
    this.role,
    this.name,
    required this.message,
  });

  final String? token;
  final String? resetToken;
  final String? role;
  final String? name;
  final String message;
}

class ForgotPasswordResult {
  const ForgotPasswordResult({this.userId, required this.message});

  final String? userId;
  final String message;
}

class GoogleAuthResult {
  const GoogleAuthResult({
    required this.token,
    required this.userId,
    required this.message,
    this.role,
    this.name,
  });

  final String token;
  final String userId;
  final String message;
  final String? role;
  final String? name;
}

class AuthRepository {
  AuthRepository(this._api);

  final ApiClient _api;

  Future<LoginResult> login({
    required String email,
    required String password,
  }) async {
    final Json body;
    try {
      body = await _api.post(
        '/auth/login',
        body: {'email': email, 'password': password},
      );
    } on ApiException catch (e) {
      // Unverified accounts get a 403 with the user id to verify.
      final data = e.body['data'] as Json? ?? const {};
      final userId = data['userId'] as String? ?? '';
      if (e.statusCode == 403 &&
          data['needsVerification'] == true &&
          userId.isNotEmpty) {
        return LoginResult(
          userId: userId,
          needsVerification: true,
          message: e.message,
        );
      }
      rethrow;
    }

    final data = body['data'] as Json? ?? const {};
    final userId = data['userId'] as String? ?? '';
    final token = body['token'] as String?;
    final role = data['role'] as String?;
    final isDoctor = role == 'doctor' || data['accountType'] == 'doctor';

    if (isDoctor && token != null && token.isNotEmpty) {
      return LoginResult(
        userId: userId,
        needsVerification: false,
        skipOtp: true,
        token: token,
        role: role ?? 'doctor',
        name: data['name'] as String?,
        message: body['message'] as String? ?? 'Doctor login successful.',
      );
    }

    return LoginResult(
      userId: userId,
      needsVerification: false,
      message: body['message'] as String? ?? 'Login OTP sent.',
    );
  }

  /// Returns the new user's id, which the OTP screen verifies.
  Future<String> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    final body = await _api.post(
      '/auth/register',
      body: {
        'name': name,
        'email': email,
        'phone': phone,
        'password': password,
      },
    );
    return (body['data'] as Json? ?? const {})['userId'] as String? ?? '';
  }

  /// Verifies an OTP. For login and registration this also starts the
  /// session, so the token is saved before any other request runs.
  Future<VerifyOtpResult> verifyOtp({
    required String userId,
    required String otp,
    required String purpose,
  }) async {
    final body = await _api.post(
      '/auth/verify-otp',
      body: {'userId': userId, 'otp': otp, 'purpose': purpose},
    );
    final data = body['data'] as Json? ?? const {};
    final user = data['user'] as Json?;
    final token = body['token'] as String?;
    final role = user?['role'] as String?;
    final name = user?['name'] as String?;

    if (token != null && token.isNotEmpty) {
      await AuthSession.start(
        token: token,
        userId: userId,
        role: role,
        name: name,
      );
    }

    return VerifyOtpResult(
      token: token,
      resetToken: data['resetToken'] as String?,
      role: role,
      name: name,
      message: body['message'] as String? ?? 'OTP verified.',
    );
  }

  Future<GoogleAuthResult> googleAuth({required String idToken}) async {
    final body = await _api.post(
      '/auth/google',
      body: {'idToken': idToken},
      timeout: const Duration(seconds: 15),
    );
    final user = dataObject(body, 'user');
    final token = body['token'] as String?;
    final userId = user['_id'] as String? ?? user['id'] as String? ?? '';

    if (token == null || token.isEmpty || userId.isEmpty) {
      throw ApiException('Invalid Google auth response from server.');
    }

    final role = user['role'] as String?;
    final name = user['name'] as String?;
    await AuthSession.start(
      token: token,
      userId: userId,
      role: role ?? 'user',
      name: name,
    );

    return GoogleAuthResult(
      token: token,
      userId: userId,
      role: role,
      name: name,
      message: body['message'] as String? ?? 'Google sign-in successful.',
    );
  }

  Future<ForgotPasswordResult> forgotPassword({required String email}) async {
    final body = await _api.post(
      '/auth/forgot-password',
      body: {'email': email},
    );
    return ForgotPasswordResult(
      userId: body['userId'] as String?,
      message: body['message'] as String? ?? 'OTP sent.',
    );
  }

  Future<void> resendOtp({required String userId, required String purpose}) =>
      _api.post(
        '/auth/resend-otp',
        body: {'userId': userId, 'purpose': purpose},
      );

  Future<void> resetPassword({
    required String userId,
    required String resetToken,
    required String newPassword,
  }) => _api.post(
    '/auth/reset-password',
    body: {
      'userId': userId,
      'resetToken': resetToken,
      'newPassword': newPassword,
    },
  );
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(apiClientProvider)),
);
