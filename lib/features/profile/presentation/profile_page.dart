import 'dart:async';

import 'package:flutter/material.dart';
import '../../../core/localization/app_localization.dart';
import '../../../core/services/auth_session.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/presentation/login_page.dart';
import '../../cart/presentation/cart_provider.dart';
import '../../cart/presentation/cart_page.dart';
import '../../chat/presentation/consultations_page.dart';
import '../../orders/presentation/orders_page.dart';
import '../../presentation/home_page.dart';
import '../../presentation/substitute_page.dart';
import '../../notifications/presentation/notifications_page.dart';
import '../../../core/services/push_notification_service.dart';
import '../models/user_profile.dart';
import 'edit_profile_page.dart';
import 'favorites_page.dart';
import '../../notifications/data/notification_repository.dart';
import '../data/profile_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> with WidgetsBindingObserver {
  Future<UserProfile>? _profileFuture;
  int _notificationUnreadCount = 0;
  Timer? _notificationPollTimer;
  static const Duration _notificationPollInterval = Duration(seconds: 5);

  bool get _isLoggedIn =>
      AuthSession.isLoggedIn;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (_isLoggedIn) {
      _profileFuture = ref.read(profileRepositoryProvider).fetchMyProfile();
      _loadNotificationBadge();
      _startNotificationPolling();
    }
  }

  @override
  void dispose() {
    _notificationPollTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _isLoggedIn) {
      _loadNotificationBadge();
    }
  }

  void _startNotificationPolling() {
    _notificationPollTimer?.cancel();
    _notificationPollTimer = Timer.periodic(_notificationPollInterval, (_) {
      if (mounted && _isLoggedIn) {
        _loadNotificationBadge();
      }
    });
  }

  Future<void> _loadNotificationBadge() async {
    try {
      final feed = await ref.read(notificationRepositoryProvider).fetchNotifications(limit: 1);
      if (!mounted) return;
      if (feed.unreadCount != _notificationUnreadCount) {
        setState(() => _notificationUnreadCount = feed.unreadCount);
      }
    } catch (_) {}
  }

  Future<void> _refreshProfile() async {
    setState(() {
      _profileFuture = ref.read(profileRepositoryProvider).fetchMyProfile();
    });
    await Future.wait([_profileFuture!, _loadNotificationBadge()]);
  }

  Future<void> _openEdit(UserProfile profile) async {
    final updated = await Navigator.of(context).push<UserProfile>(
      MaterialPageRoute<UserProfile>(
        builder: (_) => EditProfilePage(profile: profile),
      ),
    );
    if (updated != null) {
      setState(() {
        _profileFuture = Future.value(updated);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizer.of(context);
    if (!_isLoggedIn) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.t('profile'))),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.t('pleaseLoginProfile')),
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

    _profileFuture ??= ref.read(profileRepositoryProvider).fetchMyProfile();

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: RefreshIndicator(
        onRefresh: _refreshProfile,
        child: FutureBuilder<UserProfile>(
          future: _profileFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(snapshot.error.toString()),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _refreshProfile,
                    child: const Text('Retry'),
                  ),
                ],
              );
            }
            final profile = snapshot.data!;
            final isDoctor = AuthSession.role == 'doctor';
            return Stack(
              children: [
                ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 140),
                  children: [
                    SizedBox(
                      height: 260,
                      child: Stack(
                        children: [
                          Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  AppColors.brandBlue,
                                  Color(0xFF081E5E),
                                ],
                              ),
                            ),
                          ),
                          SafeArea(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 10,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    l10n.t('profile'),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () async {
                                      await Navigator.of(context).push(
                                        MaterialPageRoute<void>(
                                          builder: (_) =>
                                              const NotificationsPage(),
                                        ),
                                      );
                                      if (mounted) _loadNotificationBadge();
                                    },
                                    icon: Badge(
                                      isLabelVisible: _notificationUnreadCount > 0,
                                      label: Text(
                                        _notificationUnreadCount > 99
                                            ? '99+'
                                            : '$_notificationUnreadCount',
                                      ),
                                      child: const Icon(
                                        Icons.notifications_none,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            top: 90,
                            left: 0,
                            right: 0,
                            child: Column(
                              children: [
                                Stack(
                                  alignment: Alignment.bottomRight,
                                  children: [
                                    const CircleAvatar(
                                      radius: 46,
                                      backgroundColor: Colors.white,
                                      child: Icon(
                                        Icons.person_outline,
                                        size: 50,
                                        color: AppColors.brandBlue,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () => _openEdit(profile),
                                      child: Container(
                                        width: 28,
                                        height: 28,
                                        decoration: BoxDecoration(
                                          color: AppColors.brandAccent,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 2,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.edit,
                                          size: 14,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  profile.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      child: _MenuCard(
                        items: [
                          _MenuItem(
                            icon: Icons.edit_outlined,
                            label: l10n.t('editProfile'),
                            onTap: () => _openEdit(profile),
                          ),
                          if (!isDoctor) ...[
                            _MenuItem(
                              icon: Icons.receipt_long,
                              label: l10n.t('myOrders'),
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => const OrdersPage(),
                                  ),
                                );
                              },
                            ),
                            _MenuItem(
                              icon: Icons.favorite_border,
                              label: l10n.t('favorite'),
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => const FavoritesPage(),
                                  ),
                                );
                              },
                            ),
                            _MenuItem(
                              icon: Icons.credit_card,
                              label: l10n.t('paymentMethods'),
                              onTap: () {
                                _showComingSoon(context);
                              },
                            ),
                          ],
                          _MenuItem(
                            icon: Icons.settings_outlined,
                            label: l10n.t('language'),
                            onTap: () {
                              _showLanguagePicker(context);
                            },
                          ),
                          _MenuItem(
                            icon: Icons.help_outline,
                            label: l10n.t('helpAndSupport'),
                            onTap: () {
                              _showComingSoon(context);
                            },
                          ),
                        ],
                      ),
                    ),
                    Center(
                      child: SizedBox(
                        width: 160,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            PushNotificationService.stopInAppNotificationPolling();
                            AuthSession.clear();
                            CartProvider.of(context).resetLocal();
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute<void>(
                                builder: (_) => const LoginPage(),
                              ),
                              (route) => false,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.brandBlue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(22),
                            ),
                          ),
                          icon: const Icon(Icons.logout),
                          label: Text(l10n.t('logOut')),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
                _buildChatFab(context),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: _buildBottomBar(context),
    );
  }

  void _showComingSoon(BuildContext context) {
    final l10n = AppLocalizer.of(context);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.t('comingSoon'))));
  }

  Future<void> _showLanguagePicker(BuildContext context) async {
    final controller = AppLocaleScope.controllerOf(context);
    final l10n = AppLocalizer.of(context);
    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) {
        final active = AppLocalizer.of(ctx).languageCode;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(title: Text(l10n.t('language'))),
              RadioListTile<String>(
                value: 'en',
                groupValue: active,
                title: const Text('English'),
                onChanged: (value) => Navigator.of(ctx).pop(value),
              ),
              RadioListTile<String>(
                value: 'ar',
                groupValue: active,
                title: const Text('العربية'),
                onChanged: (value) => Navigator.of(ctx).pop(value),
              ),
            ],
          ),
        );
      },
    );
    if (selected != null) {
      controller.setLanguageCode(selected);
    }
  }

  Widget _buildBottomBar(BuildContext context) {
    final l10n = AppLocalizer.of(context);
    return BottomAppBar(
      color: AppColors.brandBlue,
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      child: SizedBox(
        height: 72,
        child: Row(
          children: <Widget>[
            Expanded(
              child: _BottomNavItem(
                icon: Icons.home_outlined,
                label: l10n.t('home'),
                onTap: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute<void>(
                      builder: (_) => const HomePage(title: 'Dawaya'),
                    ),
                    (route) => false,
                  );
                },
              ),
            ),
            Expanded(
              child: _BottomNavItem(
                icon: Icons.swap_horiz,
                label: l10n.t('substitute'),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const SubstitutePage(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 36),
            Expanded(
              child: _BottomNavItem(
                icon: Icons.shopping_cart_outlined,
                label: l10n.t('cart'),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const CartPage()),
                  );
                },
              ),
            ),
            Expanded(
              child: _BottomNavItem(
                icon: Icons.person_outline,
                label: l10n.t('profile'),
                isActive: true,
                onTap: () {},
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatFab(BuildContext context) {
    return Positioned(
      right: 16,
      bottom: 120,
      child: FloatingActionButton(
        heroTag: 'chatFabProfile',
        mini: true,
        backgroundColor: AppColors.brandBlue,
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const ConsultationsPage()),
          );
        },
        child: const Icon(Icons.chat_bubble_outline, color: Colors.white),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({required this.items});

  final List<_MenuItem> items;

  @override
  Widget build(BuildContext context) {
    final List<Widget> rows = [];
    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      rows.add(_MenuRow(item: item));
      if (i != items.length - 1) {
        rows.add(
          const Divider(height: 1, thickness: 1, color: Color(0xFFE2F0F5)),
        );
      }
    }

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.cardBlue,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: rows),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.item});

  final _MenuItem item;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: item.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(item.icon, color: AppColors.brandBlue),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item.label,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.black54),
          ],
        ),
      ),
    );
  }
}

class _MenuItem {
  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    required this.icon,
    required this.label,
    this.isActive = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Color color = isActive ? Colors.white : Colors.white70;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(icon, color: color),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
