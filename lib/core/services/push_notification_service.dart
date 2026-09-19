import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../app/app.dart';
import '../../features/chat/presentation/chat_page.dart';
import '../../features/notifications/models/app_notification.dart';
import '../../features/orders/presentation/orders_page.dart';
import '../config/firebase_options.dart';
import 'api_services.dart';
import 'auth_session.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (!DefaultFirebaseOptions.isConfigured) return;
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (_) {
    // Firebase may already be initialized in the isolate.
  }
}

class PushNotificationService {
  PushNotificationService._();

  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;
  static bool _firebaseReady = false;
  static Timer? _pollTimer;
  static final Set<String> _seenNotificationIds = {};
  static bool _pollBaselineSet = false;
  static const Duration _pollInterval = Duration(seconds: 30);

  static bool get isAvailable => DefaultFirebaseOptions.isConfigured;

  static Future<void> initialize() async {
    if (_initialized) return;

    await _setupLocalNotifications();
    await _requestAndroidNotificationPermission();

    if (!DefaultFirebaseOptions.isConfigured) {
      debugPrint(
        '🔔 Push: Firebase not configured — in-app polling fallback only. '
        'Update lib/core/config/firebase_options.dart or pass --dart-define values.',
      );
      _initialized = true;
      return;
    }

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      await _requestPermission();

      FirebaseMessaging.onMessage.listen(_onForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
      FirebaseMessaging.instance.onTokenRefresh.listen(_registerToken);

      final initial = await FirebaseMessaging.instance.getInitialMessage();
      if (initial != null) {
        _handleNotificationTap(initial);
      }

      _firebaseReady = true;
      debugPrint('🔔 Push: Firebase Messaging initialized.');
      await registerTokenWithBackend();
    } catch (e) {
      debugPrint('🔔 Push: Firebase init failed — using polling fallback: $e');
    }

    _initialized = true;
  }

  static Future<void> registerTokenWithBackend() async {
    if (AuthSession.token == null || AuthSession.token!.isEmpty) {
      return;
    }

    startInAppNotificationPolling();

    if (!_firebaseReady) {
      debugPrint('🔔 Push: FCM token skipped — Firebase not ready.');
      return;
    }

    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) {
        debugPrint('🔔 Push: FCM token is null (check google-services.json / permissions).');
        return;
      }
      await ApiService.registerFcmToken(token);
      debugPrint('🔔 Push: FCM token registered with backend.');
    } catch (e) {
      debugPrint('🔔 Push: FCM token registration failed: $e');
    }
  }

  static void startInAppNotificationPolling() {
    if (AuthSession.token == null || AuthSession.token!.isEmpty) return;

    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(_pollInterval, (_) => _pollForNewNotifications());
    unawaited(_pollForNewNotifications());
  }

  static void stopInAppNotificationPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _seenNotificationIds.clear();
    _pollBaselineSet = false;
  }

  static Future<void> _pollForNewNotifications() async {
    if (AuthSession.token == null || AuthSession.token!.isEmpty) {
      stopInAppNotificationPolling();
      return;
    }

    try {
      final feed = await ApiService.fetchNotifications(limit: 20);
      _processPolledNotifications(feed.notifications);
    } catch (e) {
      debugPrint('🔔 Push: polling fallback error: $e');
    }
  }

  static void _processPolledNotifications(List<AppNotification> notifications) {
    if (!_pollBaselineSet) {
      for (final notification in notifications) {
        if (notification.id.isNotEmpty) {
          _seenNotificationIds.add(notification.id);
        }
      }
      _pollBaselineSet = true;
      return;
    }

    for (final notification in notifications) {
      if (notification.id.isEmpty || _seenNotificationIds.contains(notification.id)) {
        continue;
      }
      _seenNotificationIds.add(notification.id);
      if (!notification.isRead) {
        unawaited(_showLocalNotification(
          id: notification.id.hashCode,
          title: notification.title.isNotEmpty ? notification.title : 'DAWAYA',
          body: notification.message,
          payload: jsonEncode({
            'type': notification.type,
            'refModel': notification.refModel,
            'refId': notification.refId,
            'consultationId': notification.refId,
          }),
        ));
      }
    }
  }

  static Future<void> _registerToken(String token) async {
    if (AuthSession.token == null || AuthSession.token!.isEmpty) return;
    try {
      await ApiService.registerFcmToken(token);
      debugPrint('🔔 Push: FCM token refresh uploaded.');
    } catch (e) {
      debugPrint('🔔 Push: FCM token refresh upload failed: $e');
    }
  }

  static Future<void> _setupLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload == null || payload.isEmpty) return;
        try {
          _handleNotificationTap(
            RemoteMessage(data: Map<String, String>.from(jsonDecode(payload))),
          );
        } catch (_) {}
      },
    );

    const channel = AndroidNotificationChannel(
      'dawayaa_messages',
      'Chat messages',
      description: 'New consultation and chat message alerts',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  static Future<void> _requestAndroidNotificationPermission() async {
    if (!Platform.isAndroid) return;

    final status = await Permission.notification.status;
    if (status.isGranted) return;

    final result = await Permission.notification.request();
    debugPrint('🔔 Push: Android POST_NOTIFICATIONS permission = $result');
  }

  static Future<void> _requestPermission() async {
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('🔔 Push: iOS/APNs permission = ${settings.authorizationStatus}');

    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  static Future<void> _onForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    final title = notification?.title ?? message.data['title'] ?? 'DAWAYA';
    final body = notification?.body ?? message.data['message'] ?? '';

    if (title.isEmpty && body.isEmpty) return;

    await _showLocalNotification(
      id: message.hashCode,
      title: title,
      body: body,
      payload: jsonEncode(message.data),
    );
  }

  static Future<void> _showLocalNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'dawayaa_messages',
        'Chat messages',
        channelDescription: 'New consultation and chat message alerts',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: DarwinNotificationDetails(),
    );

    await _localNotifications.show(id, title, body, details, payload: payload);
  }

  static void _handleNotificationTap(RemoteMessage message) {
    final data = message.data;
    final type = data['type'] ?? '';
    final refModel = data['refModel'] ?? '';
    final consultationId =
        data['consultationId'] ?? data['refId'] ?? '';

    final navigator = DawayaaApp.rootNavigatorKey.currentState;
    if (navigator == null) return;

    if (type == 'consultation_update' ||
        refModel == 'Consultation' ||
        consultationId.isNotEmpty) {
      if (consultationId.isNotEmpty) {
        navigator.push(
          MaterialPageRoute<void>(
            builder: (_) => ChatPage(consultationId: consultationId),
          ),
        );
        return;
      }
    }

    if (type == 'order_update' || refModel == 'Order') {
      navigator.push(
        MaterialPageRoute<void>(builder: (_) => const OrdersPage()),
      );
    }
  }
}
