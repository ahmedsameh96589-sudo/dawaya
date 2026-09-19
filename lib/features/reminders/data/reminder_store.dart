import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/push_notification_service.dart';
import '../models/medicine_reminder.dart';
import 'reminder_scheduler.dart';

final reminderSchedulerProvider = Provider<ReminderScheduler>(
  (ref) => ReminderScheduler(PushNotificationService.localNotifications),
);

/// The user's reminders, kept on the device so they work offline and keep
/// firing after the app is closed.
class ReminderStore extends AsyncNotifier<List<MedicineReminder>> {
  static const _key = 'medicine_reminders';

  @override
  Future<List<MedicineReminder>> build() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? const [];
    return raw
        .map(
          (e) =>
              MedicineReminder.fromJson(jsonDecode(e) as Map<String, dynamic>),
        )
        .toList();
  }

  Future<void> add(MedicineReminder reminder) =>
      _update((list) => [...list, reminder], reminder);

  Future<void> remove(String id) async {
    final current = state.value ?? const [];
    final victim = current.where((r) => r.id == id).firstOrNull;
    if (victim == null) return;
    await ref.read(reminderSchedulerProvider).cancel(victim);
    await _save(current.where((r) => r.id != id).toList());
  }

  Future<void> setEnabled(String id, bool enabled) async {
    final current = state.value ?? const [];
    final target = current.where((r) => r.id == id).firstOrNull;
    if (target == null) return;
    final updated = target.copyWith(enabled: enabled);
    await _update(
      (list) => [for (final r in list) r.id == id ? updated : r],
      updated,
    );
  }

  /// Re-registers every enabled reminder with the OS. Call after a
  /// reinstall or when notification permission is granted late.
  Future<void> rescheduleAll() async {
    final scheduler = ref.read(reminderSchedulerProvider);
    for (final r in state.value ?? const <MedicineReminder>[]) {
      await scheduler.schedule(r);
    }
  }

  Future<void> _update(
    List<MedicineReminder> Function(List<MedicineReminder>) change,
    MedicineReminder toSchedule,
  ) async {
    await ref.read(reminderSchedulerProvider).schedule(toSchedule);
    await _save(change(state.value ?? const []));
  }

  Future<void> _save(List<MedicineReminder> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _key,
      list.map((r) => jsonEncode(r.toJson())).toList(),
    );
    state = AsyncData(list);
  }
}

final reminderStoreProvider =
    AsyncNotifierProvider<ReminderStore, List<MedicineReminder>>(
      ReminderStore.new,
    );

/// Lets tests replace the OS plugin.
typedef LocalNotifications = FlutterLocalNotificationsPlugin;
