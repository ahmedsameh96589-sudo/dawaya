import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../core/localization/app_localization.dart';
import '../core/theme/app_theme.dart';
import 'providers.dart';
import '../features/cart/presentation/cart_provider.dart';
import '../features/auth/presentation/splash_onboarding.dart';
import '../features/auth/presentation/login_page.dart';
import '../features/auth/presentation/signup_page.dart';
import '../features/auth/presentation/forget_password_screen.dart';
import '../features/auth/presentation/scan_prescription_screen.dart';
import '../features/presentation/home_page.dart';

class DawayaaApp extends StatelessWidget {
  const DawayaaApp({super.key});

  static final AppLocaleController _localeController = AppLocaleController();

  @override
  Widget build(BuildContext context) {
    return CartProvider(
      controller: appContainer.read(cartControllerProvider),
      child: AppLocaleScope(
        controller: _localeController,
        child: ValueListenableBuilder<Locale>(
          valueListenable: _localeController,
          builder: (context, locale, _) {
            return MaterialApp(
              title: 'Dawaya',
              navigatorKey: rootNavigatorKey,
              scaffoldMessengerKey: rootMessengerKey,
              theme: AppTheme.light,
              debugShowCheckedModeBanner: false,
              locale: locale,
              supportedLocales: const [
                Locale('en'),
                Locale('ar'),
              ],
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              initialRoute: '/',
              routes: {
                '/': (context) => const SplashScreen(),
                '/onboarding': (context) => const OnboardingScreen(),
                '/login': (context) => const LoginPage(),
                '/signup': (context) => const SignUpPage(),
                '/forget': (context) => const ForgetPasswordScreen(),
                '/scan': (context) => const ScanPrescriptionScreen(),
                '/home': (context) => const HomePage(title: 'Dawaya'),
              },
            );
          },
        ),
      ),
    );
  }
}
