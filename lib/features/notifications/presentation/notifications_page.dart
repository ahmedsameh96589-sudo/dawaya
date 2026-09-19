import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/localization/app_localization.dart';
import '../../../core/services/auth_session.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/presentation/login_page.dart';
import '../../notifications/models/app_notification.dart';
import '../../chat/presentation/chat_page.dart';
import '../../orders/presentation/orders_page.dart';
import '../data/notification_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage>
    with WidgetsBindingObserver {
  Future<NotificationFeed>? _notificationsFuture;
  Timer? _pollTimer;
  static const Duration _pollInterval = Duration(seconds: 5);

  bool get _isLoggedIn =>
      AuthSession.isLoggedIn;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (_isLoggedIn) {
      _notificationsFuture = ref.read(notificationRepositoryProvider).fetchNotifications();
      _startPolling();
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _isLoggedIn) {
      _pollNotifications(silent: true);
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(_pollInterval, (_) {
      if (mounted && _isLoggedIn) {
        _pollNotifications(silent: true);
      }
    });
  }

  Future<void> _pollNotifications({bool silent = false}) async {
    try {
      final feed = await ref.read(notificationRepositoryProvider).fetchNotifications();
      if (!mounted) return;
      setState(() => _notificationsFuture = Future.value(feed));
    } catch (_) {
      if (!silent && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizer.of(context).t('serverError'))),
        );
      }
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _notificationsFuture = ref.read(notificationRepositoryProvider).fetchNotifications();
    });
    await _notificationsFuture;
  }

  Future<void> _markAllAsRead() async {
    try {
      await ref.read(notificationRepositoryProvider).markAllAsRead();
      if (!mounted) return;
      await _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _openNotification(AppNotification notification) async {
    if (!notification.isRead && notification.id.isNotEmpty) {
      try {
        await ref.read(notificationRepositoryProvider).markAsRead(notification.id);
        if (mounted) {
          setState(() {
            _notificationsFuture = ref.read(notificationRepositoryProvider).fetchNotifications();
          });
        }
      } catch (_) {
        // Opening the target is more important than blocking on read state.
      }
    }

    if (!mounted) return;
    if (notification.refModel == 'Consultation' ||
        notification.type == 'consultation_update') {
      final consultationId = notification.refId;
      if (consultationId.isNotEmpty) {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ChatPage(consultationId: consultationId),
          ),
        );
        return;
      }
    }
    if (notification.refModel == 'Order' ||
        notification.type == 'order_update') {
      Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => const OrdersPage()));
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(notification.message)));
  }

  Future<void> _deleteNotification(AppNotification notification) async {
    try {
      await ref.read(notificationRepositoryProvider).delete(notification.id);
      if (!mounted) return;
      await _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizer.of(context);

    if (!_isLoggedIn) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.t('notifications'))),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.t('pleaseLoginNotifications')),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const LoginPage()),
                  );
                },
                child: Text(l10n.t('login')),
              ),
            ],
          ),
        ),
      );
    }

    _notificationsFuture ??= ref.read(notificationRepositoryProvider).fetchNotifications();

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(l10n.t('notifications')),
        backgroundColor: AppColors.brandBlue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _markAllAsRead,
            icon: const Icon(Icons.done_all),
            tooltip: l10n.t('markAllRead'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<NotificationFeed>(
          future: _notificationsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  const Icon(Icons.wifi_off, size: 48, color: Colors.grey),
                  const SizedBox(height: 12),
                  Center(child: Text(l10n.t('serverError'))),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _refresh,
                    child: Text(l10n.t('retry')),
                  ),
                ],
              );
            }

            final feed =
                snapshot.data ??
                const NotificationFeed(notifications: [], unreadCount: 0);
            final notifications = feed.notifications;
            if (notifications.isEmpty) {
              return ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  const SizedBox(height: 80),
                  const Icon(
                    Icons.notifications_none,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 12),
                  Center(child: Text(l10n.t('noNotifications'))),
                ],
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = notifications[index];
                return Dismissible(
                  key: ValueKey(item.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) => _deleteNotification(item),
                  child: _NotificationCard(
                    notification: item,
                    onTap: () => _openNotification(item),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.notification, required this.onTap});

  final AppNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = _notificationColor(notification.type);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: notification.isRead ? Colors.white : const Color(0xFFEAF7FA),
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(_notificationIcon(notification.type), color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      if (!notification.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.brandAccent,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    notification.message,
                    style: const TextStyle(color: Colors.black54, height: 1.35),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatDate(notification.createdAt),
                    style: const TextStyle(color: Colors.black38, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.black38),
          ],
        ),
      ),
    );
  }

  IconData _notificationIcon(String type) {
    switch (type) {
      case 'order_update':
        return Icons.receipt_long;
      case 'prescription_update':
        return Icons.medication_outlined;
      case 'consultation_update':
        return Icons.chat_bubble_outline;
      case 'promo':
        return Icons.local_offer_outlined;
      default:
        return Icons.notifications_none;
    }
  }

  Color _notificationColor(String type) {
    switch (type) {
      case 'order_update':
        return Colors.blue;
      case 'prescription_update':
        return Colors.green;
      case 'consultation_update':
        return Colors.deepPurple;
      case 'promo':
        return Colors.orange;
      default:
        return AppColors.brandBlue;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inHours < 1) return '${difference.inMinutes} min ago';
    if (difference.inDays < 1) return '${difference.inHours} h ago';
    return '${date.day}/${date.month}/${date.year}';
  }
}
