import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../models/app_notification.dart';

class NotificationRepository {
  NotificationRepository(this._api);

  final ApiClient _api;

  Future<NotificationFeed> fetchNotifications({
    int page = 1,
    int limit = 20,
  }) async => NotificationFeed.fromJson(
    await _api.get(
      '/notifications',
      query: {'page': '$page', 'limit': '$limit'},
    ),
  );

  Future<AppNotification> markAsRead(String id) async =>
      AppNotification.fromJson(
        dataObject(await _api.put('/notifications/$id/read'), 'notification'),
      );

  Future<void> markAllAsRead() => _api.put('/notifications/read-all');

  Future<void> delete(String id) => _api.delete('/notifications/$id');

  Future<void> clearAll() => _api.delete('/notifications');

  /// Lets the backend send push notifications to this device.
  Future<void> registerFcmToken(String fcmToken) =>
      _api.put('/notifications/fcm-token', body: {'fcmToken': fcmToken});
}

final notificationRepositoryProvider = Provider<NotificationRepository>(
  (ref) => NotificationRepository(ref.watch(apiClientProvider)),
);
