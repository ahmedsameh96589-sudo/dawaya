import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../models/medicine_reminder.dart';

/// Schedules the phone's local notifications for [MedicineReminder]s.
///
/// Each (reminder, time) pair gets its own repeating daily notification, so
/// reminders keep firing when the app is closed. Ids are derived from the
/// reminder id so they can be cancelled later.
class ReminderScheduler {
  ReminderScheduler(this._plugin);

  final FlutterLocalNotificationsPlugin _plugin;

  static const String channelId = 'dawaya_reminders';
  static const int maxTimesPerReminder = 8;
  static bool _timezoneReady = false;

  static Future<void> ensureTimezone() async {
    if (_timezoneReady) return;
    tzdata.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (_) {
      // Unknown zone name: notifications still fire, using UTC offsets.
    }
    _timezoneReady = true;
  }

  Future<void> schedule(MedicineReminder reminder) async {
    await cancel(reminder);
    if (!reminder.enabled) return;
    await ensureTimezone();

    for (var i = 0; i < reminder.times.length && i < maxTimesPerReminder; i++) {
      final time = reminder.times[i];
      await _plugin.zonedSchedule(
        notificationId(reminder.id, i),
        'Time for ${reminder.medicineName}',
        reminder.dose.isEmpty ? 'Tap to mark it as taken.' : reminder.dose,
        nextOccurrence(time, tz.TZDateTime.now(tz.local)),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            'Medicine reminders',
            channelDescription: 'Daily reminders to take your medicines',
            importance: Importance.high,
            priority: Priority.high,
            category: AndroidNotificationCategory.reminder,
          ),
          iOS: DarwinNotificationDetails(
            interruptionLevel: InterruptionLevel.timeSensitive,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: '{"type":"reminder","reminderId":"${reminder.id}"}',
      );
    }
  }

  Future<void> cancel(MedicineReminder reminder) async {
    for (var i = 0; i < maxTimesPerReminder; i++) {
      await _plugin.cancel(notificationId(reminder.id, i));
    }
  }

  /// The next time [time] comes around, starting from [now].
  static tz.TZDateTime nextOccurrence(TimeOfDay time, tz.TZDateTime now) {
    var next = tz.TZDateTime(
      now.location,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    if (!next.isAfter(now)) next = next.add(const Duration(days: 1));
    return next;
  }

  /// A stable 31-bit id per (reminder, slot). Slot lives in the low bits so
  /// one reminder's ids never collide with each other.
  static int notificationId(String reminderId, int slot) =>
      ((reminderId.hashCode & 0x0FFFFFFF) << 3 | (slot & 7)) & 0x7FFFFFFF;
}
