import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/providers.dart';
import 'core/services/auth_session.dart';
import 'core/services/push_notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthSession.restore();
  await PushNotificationService.initialize();
  runApp(
    UncontrolledProviderScope(
      container: appContainer,
      child: const DawayaaApp(),
    ),
  );
}
