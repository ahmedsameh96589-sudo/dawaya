import 'package:dawayaa/features/reminders/data/reminder_scheduler.dart';
import 'package:dawayaa/features/reminders/data/reminder_store.dart';
import 'package:dawayaa/features/reminders/presentation/reminders_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SilentScheduler extends ReminderScheduler {
  SilentScheduler() : super(FlutterLocalNotificationsPlugin());
  @override
  Future<void> schedule(r) async {}
  @override
  Future<void> cancel(r) async {}
}

Widget app() => ProviderScope(
  overrides: [reminderSchedulerProvider.overrideWithValue(SilentScheduler())],
  child: const MaterialApp(home: RemindersPage()),
);

void main() {
  testWidgets('shows an empty state and opens the new-reminder sheet', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    expect(find.text('No reminders yet'), findsOneWidget);

    await tester.tap(find.text('New reminder'));
    await tester.pumpAndSettle();

    expect(find.text('Medicine reminder'), findsOneWidget);
    expect(find.text('9:00 AM'), findsOneWidget);
  });

  testWidgets('lists saved reminders with their times', (tester) async {
    SharedPreferences.setMockInitialValues({
      'medicine_reminders': [
        '{"id":"r1","medicineName":"Concor","dose":"1 tablet","times":["8:0","20:30"],"enabled":true}',
      ],
    });
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    expect(find.text('Concor'), findsOneWidget);
    expect(find.text('1 tablet'), findsOneWidget);
    expect(find.text('8:00 AM · 8:30 PM'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
