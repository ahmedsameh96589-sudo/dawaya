import 'package:flutter/material.dart';

import 'app/app.dart';
import 'core/services/auth_session.dart';
import 'core/services/push_notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthSession.restore();
  await PushNotificationService.initialize();
  runApp(const DawayaaApp());
}
