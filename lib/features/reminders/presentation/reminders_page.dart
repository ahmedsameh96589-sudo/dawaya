import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/async_states.dart';
import '../data/reminder_store.dart';
import '../models/medicine_reminder.dart';
import 'add_reminder_sheet.dart';

class RemindersPage extends ConsumerWidget {
  const RemindersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reminders = ref.watch(reminderStoreProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Medicine reminders'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showAddReminderSheet(context),
        backgroundColor: AppColors.brandBlue,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_alarm),
        label: const Text('New reminder'),
      ),
      body: reminders.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorRetryView(
          error: error,
          onRetry: () => ref.invalidate(reminderStoreProvider),
        ),
        data: (list) => list.isEmpty
            ? const EmptyStateView(
                icon: Icons.alarm_outlined,
                title: 'No reminders yet',
                message:
                    'Add one here, or from any medicine page, and we\'ll '
                    'remind you every day at the times you choose.',
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) => _ReminderCard(reminder: list[i]),
              ),
      ),
    );
  }
}

class _ReminderCard extends ConsumerWidget {
  const _ReminderCard({required this.reminder});

  final MedicineReminder reminder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.read(reminderStoreProvider.notifier);
    final muted = !reminder.enabled;

    return Dismissible(
      key: ValueKey(reminder.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: AlignmentDirectional.centerEnd,
        padding: const EdgeInsetsDirectional.only(end: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) {
        store.remove(reminder.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Removed ${reminder.medicineName} reminder.')),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 10,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: muted ? Colors.black12 : AppColors.cardBlue,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.medication_outlined,
                color: muted ? Colors.black38 : AppColors.brandBlue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reminder.medicineName,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: muted ? Colors.black45 : Colors.black87,
                    ),
                  ),
                  if (reminder.dose.isNotEmpty)
                    Text(
                      reminder.dose,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 13,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    reminder.times.map((t) => t.format(context)).join(' · '),
                    style: TextStyle(
                      color: muted ? Colors.black38 : AppColors.brandBlue,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Switch.adaptive(
              value: reminder.enabled,
              activeColor: AppColors.brandBlue,
              onChanged: (v) => store.setEnabled(reminder.id, v),
            ),
          ],
        ),
      ),
    );
  }
}
