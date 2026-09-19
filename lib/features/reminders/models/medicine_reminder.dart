import 'package:flutter/material.dart';

/// A daily reminder to take one medicine at one or more times.
class MedicineReminder {
  const MedicineReminder({
    required this.id,
    required this.medicineName,
    required this.times,
    this.productId,
    this.dose = '',
    this.enabled = true,
  });

  final String id;
  final String medicineName;

  /// Catalog product this was created from, if any.
  final String? productId;

  /// Free text such as "1 tablet after breakfast".
  final String dose;
  final List<TimeOfDay> times;
  final bool enabled;

  MedicineReminder copyWith({
    String? medicineName,
    String? dose,
    List<TimeOfDay>? times,
    bool? enabled,
  }) => MedicineReminder(
    id: id,
    productId: productId,
    medicineName: medicineName ?? this.medicineName,
    dose: dose ?? this.dose,
    times: times ?? this.times,
    enabled: enabled ?? this.enabled,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'medicineName': medicineName,
    if (productId != null) 'productId': productId,
    'dose': dose,
    'times': times.map((t) => '${t.hour}:${t.minute}').toList(),
    'enabled': enabled,
  };

  factory MedicineReminder.fromJson(Map<String, dynamic> json) =>
      MedicineReminder(
        id: json['id'] as String,
        medicineName: json['medicineName'] as String? ?? '',
        productId: json['productId'] as String?,
        dose: json['dose'] as String? ?? '',
        times: (json['times'] as List<dynamic>? ?? const []).map((t) {
          final parts = (t as String).split(':');
          return TimeOfDay(
            hour: int.parse(parts[0]),
            minute: int.parse(parts[1]),
          );
        }).toList()..sort(compareTimes),
        enabled: json['enabled'] as bool? ?? true,
      );

  static int compareTimes(TimeOfDay a, TimeOfDay b) =>
      (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute);
}
