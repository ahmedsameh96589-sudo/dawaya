import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../data/reminder_store.dart';
import '../models/medicine_reminder.dart';

/// Opens the "new reminder" sheet. [medicineName] and [productId] pre-fill it
/// when the user comes from a product page.
Future<void> showAddReminderSheet(
  BuildContext context, {
  String medicineName = '',
  String? productId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) =>
        AddReminderSheet(medicineName: medicineName, productId: productId),
  );
}

class AddReminderSheet extends ConsumerStatefulWidget {
  const AddReminderSheet({super.key, this.medicineName = '', this.productId});

  final String medicineName;
  final String? productId;

  @override
  ConsumerState<AddReminderSheet> createState() => _AddReminderSheetState();
}

class _AddReminderSheetState extends ConsumerState<AddReminderSheet> {
  late final TextEditingController _name = TextEditingController(
    text: widget.medicineName,
  );
  final TextEditingController _dose = TextEditingController();
  final List<TimeOfDay> _times = [const TimeOfDay(hour: 9, minute: 0)];
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _dose.dispose();
    super.dispose();
  }

  Future<void> _addTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 21, minute: 0),
    );
    if (picked == null) return;
    setState(() {
      if (!_times.any(
        (t) => t.hour == picked.hour && t.minute == picked.minute,
      )) {
        _times.add(picked);
      }
      _times.sort(MedicineReminder.compareTimes);
    });
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter the medicine name.')));
      return;
    }
    setState(() => _saving = true);
    try {
      await ref
          .read(reminderStoreProvider.notifier)
          .add(
            MedicineReminder(
              id: DateTime.now().microsecondsSinceEpoch.toRadixString(36),
              medicineName: name,
              productId: widget.productId,
              dose: _dose.text.trim(),
              times: List.of(_times),
            ),
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Reminder set for $name.')));
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Medicine reminder',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Medicine',
                  prefixIcon: Icon(Icons.medication_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _dose,
                decoration: const InputDecoration(
                  labelText: 'Dose (optional)',
                  hintText: '1 tablet after breakfast',
                  prefixIcon: Icon(Icons.notes_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Every day at',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final t in _times)
                    InputChip(
                      label: Text(t.format(context)),
                      avatar: const Icon(Icons.alarm, size: 18),
                      onDeleted: _times.length > 1
                          ? () => setState(() => _times.remove(t))
                          : null,
                    ),
                  ActionChip(
                    label: const Text('Add time'),
                    avatar: const Icon(Icons.add, size: 18),
                    onPressed: _addTime,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Save reminder',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
