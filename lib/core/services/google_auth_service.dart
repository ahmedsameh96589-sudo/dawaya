import 'dart:async';
import 'dart:io' show Platform, SocketException;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../../features/cart/presentation/cart_provider.dart';
import '../../features/presentation/home_page.dart';
import 'push_notification_service.dart';
import '../../app/providers.dart';
import '../../features/auth/data/auth_repository.dart';

class GoogleAuthService {
  GoogleAuthService._();

  /// Web client ID as [serverClientId] is required on Android/iOS to obtain an
  /// ID token for backend verification. On web, [clientId] must be the Web client.
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: const ['email', 'profile'],
    serverClientId: _nonEmpty(AppConfig.googleWebClientId),
    clientId: kIsWeb
        ? _nonEmpty(AppConfig.googleWebClientId)
        : (!kIsWeb &&
                Platform.isIOS &&
                AppConfig.googleIosClientId.isNotEmpty
            ? AppConfig.googleIosClientId
            : null),
  );

  static String? _nonEmpty(String value) =>
      value.isNotEmpty ? value : null;

  static Future<void> signInAndAuthenticate(BuildContext context) async {
    if (AppConfig.googleWebClientId.isEmpty) {
      throw Exception(
        'Google Sign-In is not configured. Set webClientId in '
        'lib/core/config/google_auth_config.dart or pass '
        '--dart-define=GOOGLE_WEB_CLIENT_ID=.... See GOOGLE_AUTH_SETUP.md.',
      );
    }

    final account = await _signInWithGoogle();
    if (account == null) return;

    final idToken = await _fetchIdToken(account);

    final result = await _authenticateWithBackend(idToken);

    if (!context.mounted) return;

    CartProvider.of(context).loadFromServer(force: true);
    await PushNotificationService.registerTokenWithBackend();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const HomePage(title: 'Dawaya')),
      (route) => false,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.message)),
    );
  }

  static Future<GoogleSignInAccount?> _signInWithGoogle() async {
    try {
      return await _googleSignIn.signIn();
    } on PlatformException catch (e) {
      if (e.code == 'sign_in_canceled') return null;
      throw _mapGooglePlatformError(e);
    }
  }

  static Future<String> _fetchIdToken(GoogleSignInAccount account) async {
    GoogleSignInAuthentication auth;
    try {
      auth = await account.authentication;
    } on PlatformException catch (e) {
      throw _mapGooglePlatformError(e);
    }

    final idToken = auth.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw Exception(
        'Could not get Google ID token. On Android, confirm serverClientId '
        '(Web client ID) is set in google_auth_config.dart and matches the '
        'Web OAuth client in Google Cloud Console.',
      );
    }
    return idToken;
  }

  static Future<GoogleAuthResult> _authenticateWithBackend(
    String idToken,
  ) async {
    try {
      return await appContainer.read(authRepositoryProvider).googleAuth(idToken: idToken);
    } on SocketException catch (e) {
      throw Exception(
        'Cannot reach the backend at ${AppConfig.apiBaseUrl} '
        '(${e.message}). Start the API server on port 5001.',
      );
    } on TimeoutException {
      throw Exception(
        'Backend request timed out at ${AppConfig.apiBaseUrl}. '
        'Is the server running on port 5001?',
      );
    } on http.ClientException catch (e) {
      throw Exception(
        'Network error contacting ${AppConfig.apiBaseUrl}: ${e.message}',
      );
    } on Exception catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '');
      if (message.contains('Invalid or expired Google token') ||
          message.contains('Google ID token')) {
        throw Exception(
          'Backend rejected the Google token: $message. '
          'Set GOOGLE_CLIENT_ID in the backend .env to the same Web client ID '
          'as google_auth_config.dart (${AppConfig.googleWebClientId}).',
        );
      }
      rethrow;
    }
  }

  static Exception _mapGooglePlatformError(PlatformException e) {
    final message = e.message ?? '';
    final isDeveloperError = e.code == 'sign_in_failed' &&
        (message.contains('Api10') ||
            message.contains('10:') ||
            message.toLowerCase().contains('developer_error'));

    if (isDeveloperError) {
      return Exception(
        'Google Sign-In failed (Api10 / DEVELOPER_ERROR). Register the debug '
        'SHA-1 and package name com.example.dawayaa in Google Cloud Console → '
        'Credentials → Android OAuth client. '
        'Run: keytool -list -v -keystore ~/.android/debug.keystore '
        '-alias androiddebugkey -storepass android -keypass android',
      );
    }

    return Exception('Google Sign-In error (${e.code}): $message');
  }

  static Future<void> signOut() async {
    await _googleSignIn.signOut();
  }
}
