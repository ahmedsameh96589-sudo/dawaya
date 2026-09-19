import 'package:flutter/material.dart';

class AppLocaleController extends ValueNotifier<Locale> {
  AppLocaleController() : super(const Locale('en'));

  void setLanguageCode(String code) {
    value = Locale(code.toLowerCase() == 'ar' ? 'ar' : 'en');
  }
}

class AppLocaleScope extends InheritedNotifier<AppLocaleController> {
  const AppLocaleScope({
    super.key,
    required AppLocaleController controller,
    required super.child,
  }) : super(notifier: controller);

  static AppLocaleController controllerOf(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppLocaleScope>();
    assert(scope != null, 'AppLocaleScope is missing in widget tree');
    return scope!.notifier!;
  }

  static Locale localeOf(BuildContext context) {
    return controllerOf(context).value;
  }
}

class AppLocalizer {
  AppLocalizer(this.locale);

  final Locale locale;

  bool get isArabic => locale.languageCode == 'ar';
  String get languageCode => isArabic ? 'ar' : 'en';

  static AppLocalizer of(BuildContext context) {
    return AppLocalizer(AppLocaleScope.localeOf(context));
  }

  static const Map<String, String> _en = {
    'profile': 'Profile',
    'login': 'Login',
    'retry': 'Retry',
    'editProfile': 'Edit Profile',
    'myOrders': 'My Orders',
    'favorite': 'Favorite',
    'paymentMethods': 'Payment methods',
    'settings': 'Settings',
    'helpAndSupport': 'Help and Support',
    'logOut': 'Log Out',
    'home': 'Home',
    'substitute': 'Substitute',
    'cart': 'Cart',
    'language': 'Language',
    'comingSoon': 'Coming soon',
    'pleaseLoginProfile': 'Please login to view your profile.',
    'news': 'News',
    'serverError': 'Unable to connect to server',
    'categories': 'Categories',
    'items': 'Items',
    'showAll': 'Show All',
    'search': 'Search',
    'notifications': 'Notifications',
    'noNotifications': 'No notifications yet.',
    'pleaseLoginNotifications': 'Please login to view your notifications.',
    'markAllRead': 'Mark all as read',
  };

  static const Map<String, String> _ar = {
    'profile': 'الملف الشخصي',
    'login': 'تسجيل الدخول',
    'retry': 'إعادة المحاولة',
    'editProfile': 'تعديل الملف الشخصي',
    'myOrders': 'طلباتي',
    'favorite': 'المفضلة',
    'paymentMethods': 'طرق الدفع',
    'settings': 'الإعدادات',
    'helpAndSupport': 'المساعدة والدعم',
    'logOut': 'تسجيل الخروج',
    'home': 'الرئيسية',
    'substitute': 'البدائل',
    'cart': 'السلة',
    'language': 'اللغة',
    'comingSoon': 'قريبًا',
    'pleaseLoginProfile': 'سجل الدخول لعرض ملفك الشخصي.',
    'news': 'الأخبار',
    'serverError': 'تعذّر الاتصال بالسيرفر',
    'categories': 'التصنيفات',
    'items': 'المنتجات',
    'showAll': 'عرض الكل',
    'search': 'ابحث',
    'notifications': 'الإشعارات',
    'noNotifications': 'لا توجد إشعارات حالياً.',
    'pleaseLoginNotifications': 'سجل الدخول لعرض إشعاراتك.',
    'markAllRead': 'تحديد الكل كمقروء',
  };

  String t(String key) {
    final table = isArabic ? _ar : _en;
    return table[key] ?? key;
  }
}
