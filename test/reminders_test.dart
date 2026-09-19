import 'package:dawayaa/features/reminders/data/reminder_scheduler.dart';
import 'package:dawayaa/features/reminders/data/reminder_store.dart';
import 'package:dawayaa/features/reminders/models/medicine_reminder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Records what would have been handed to the OS.
class FakeScheduler extends ReminderScheduler {
  FakeScheduler() : super(FlutterLocalNotificationsPlugin());

  final List<String> log = [];

  @override
  Future<void> schedule(MedicineReminder r) async =>
      log.add('schedule ${r.id} ${r.enabled ? "on" : "off"}');

  @override
  Future<void> cancel(MedicineReminder r) async => log.add('cancel ${r.id}');
}

final reminder = MedicineReminder(
  id: 'r1',
  medicineName: 'Panadol',
  dose: '1 tablet',
  times: const [TimeOfDay(hour: 21, minute: 30), TimeOfDay(hour: 9, minute: 0)],
);

void main() {
  group('MedicineReminder', () {
    test('survives a JSON round trip with times sorted', () {
      final back = MedicineReminder.fromJson(reminder.toJson());

      expect(back.medicineName, 'Panadol');
      expect(back.dose, '1 tablet');
      expect(back.times, const [
        TimeOfDay(hour: 9, minute: 0),
        TimeOfDay(hour: 21, minute: 30),
      ]);
      expect(back.enabled, isTrue);
    });
  });

  group('ReminderScheduler', () {
    late tz.Location cairo;
    setUpAll(() {
      tzdata.initializeTimeZones();
      cairo = tz.getLocation('Africa/Cairo');
    });

    test('picks today when the time is still ahead', () {
      final now = tz.TZDateTime(cairo, 2026, 9, 19, 8, 0);
      final next = ReminderScheduler.nextOccurrence(
        const TimeOfDay(hour: 9, minute: 0),
        now,
      );

      expect(next, tz.TZDateTime(cairo, 2026, 9, 19, 9, 0));
    });

    test('rolls over to tomorrow when the time has passed', () {
      final now = tz.TZDateTime(cairo, 2026, 9, 19, 22, 0);
      final next = ReminderScheduler.nextOccurrence(
        const TimeOfDay(hour: 9, minute: 0),
        now,
      );

      expect(next, tz.TZDateTime(cairo, 2026, 9, 20, 9, 0));
    });

    test('gives each time slot of a reminder a distinct positive id', () {
      final ids = {
        for (var i = 0; i < 8; i++) ReminderScheduler.notificationId('r1', i),
      };

      expect(ids, hasLength(8));
      expect(ids.every((id) => id > 0 && id <= 0x7FFFFFFF), isTrue);
      expect(
        ReminderScheduler.notificationId('r1', 0),
        isNot(ReminderScheduler.notificationId('r2', 0)),
      );
    });
  });

  group('ReminderStore', () {
    late FakeScheduler scheduler;
    late ProviderContainer container;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      scheduler = FakeScheduler();
      container = ProviderContainer(
        overrides: [reminderSchedulerProvider.overrideWithValue(scheduler)],
      );
      addTearDown(container.dispose);
    });

    test('adding a reminder persists it and schedules it', () async {
      await container.read(reminderStoreProvider.future);
      await container.read(reminderStoreProvider.notifier).add(reminder);

      expect(scheduler.log, ['schedule r1 on']);

      // A fresh store (new app launch) reads it back from disk.
      final fresh = ProviderContainer(
        overrides: [reminderSchedulerProvider.overrideWithValue(scheduler)],
      );
      addTearDown(fresh.dispose);
      final list = await fresh.read(reminderStoreProvider.future);
      expect(list.single.medicineName, 'Panadol');
    });

    test(
      'disabling cancels the OS notifications; removing forgets it',
      () async {
        await container.read(reminderStoreProvider.future);
        final store = container.read(reminderStoreProvider.notifier);
        await store.add(reminder);
        scheduler.log.clear();

        await store.setEnabled('r1', false);
        expect(scheduler.log, ['schedule r1 off']);
        expect(
          container.read(reminderStoreProvider).value!.single.enabled,
          isFalse,
        );

        await store.remove('r1');
        expect(scheduler.log.last, 'cancel r1');
        expect(container.read(reminderStoreProvider).value, isEmpty);
      },
    );
  });
}
