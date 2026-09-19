import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/api_client.dart';
import '../core/network/realtime_client.dart';
import '../core/services/auth_session.dart';
import '../core/services/push_notification_service.dart';
import '../features/cart/data/cart_repository.dart';
import '../features/cart/models/cart_controller.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<ScaffoldMessengerState> rootMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

/// The app's single provider container. Widgets reach it through
/// `UncontrolledProviderScope` in `main.dart`; services that live outside
/// the widget tree (push notifications, Google sign-in) read it directly.
final ProviderContainer appContainer = ProviderContainer(
  overrides: [
    apiClientProvider.overrideWithValue(
      ApiClient(onUnauthorized: _signOutExpiredSession),
    ),
  ],
);

final cartControllerProvider = Provider<CartController>((ref) {
  final controller = CartController(ref.watch(cartRepositoryProvider));
  ref.onDispose(controller.dispose);
  return controller;
});

bool _signingOut = false;

/// Runs when a signed-in request gets a 401: the token expired or the
/// account was disabled. Clears the session and returns to the login screen.
Future<void> _signOutExpiredSession() async {
  if (_signingOut || !AuthSession.isLoggedIn) return;
  _signingOut = true;
  try {
    PushNotificationService.stopInAppNotificationPolling();
    appContainer.read(realtimeClientProvider).disconnect();
    await AuthSession.clear();
    appContainer.read(cartControllerProvider).resetLocal();
    rootNavigatorKey.currentState?.pushNamedAndRemoveUntil(
      '/login',
      (_) => false,
    );
    rootMessengerKey.currentState?.showSnackBar(
      const SnackBar(
        content: Text('Your session expired. Please sign in again.'),
      ),
    );
  } finally {
    _signingOut = false;
  }
}
