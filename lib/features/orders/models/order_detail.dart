import 'order_summary.dart';

/// The delivery pipeline, in order. Cancelled and returned sit outside it.
const List<String> kOrderPipeline = [
  'pending',
  'confirmed',
  'preparing',
  'out_for_delivery',
  'delivered',
];

class OrderStatusEvent {
  const OrderStatusEvent({
    required this.status,
    required this.note,
    required this.at,
  });

  final String status;
  final String note;
  final DateTime at;

  factory OrderStatusEvent.fromJson(Map<String, dynamic> json) =>
      OrderStatusEvent(
        status: json['status'] as String? ?? '',
        note: json['note'] as String? ?? '',
        at: DateTime.tryParse(json['at'] as String? ?? '') ?? DateTime.now(),
      );
}

class OrderLine {
  const OrderLine({
    required this.name,
    required this.image,
    required this.quantity,
    required this.subtotal,
  });

  final String name;
  final String image;
  final int quantity;
  final double subtotal;

  factory OrderLine.fromJson(Map<String, dynamic> json) => OrderLine(
    name: json['name'] as String? ?? '',
    image: json['image'] as String? ?? '',
    quantity: (json['quantity'] as num?)?.toInt() ?? 1,
    subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
  );
}

/// One order with everything the tracking screen shows.
class OrderDetail {
  const OrderDetail({
    required this.summary,
    required this.items,
    required this.history,
    required this.address,
    required this.subtotal,
    required this.deliveryFee,
    required this.discount,
    this.estimatedDelivery,
    this.cancelReason,
  });

  final OrderSummary summary;
  final List<OrderLine> items;

  /// Oldest first.
  final List<OrderStatusEvent> history;
  final String address;
  final double subtotal;
  final double deliveryFee;
  final double discount;
  final DateTime? estimatedDelivery;
  final String? cancelReason;

  String get status => summary.status;
  bool get isCancelled => status == 'cancelled' || status == 'returned';

  /// Only orders the pharmacy has not started preparing can be cancelled.
  bool get canCancel => status == 'pending' || status == 'confirmed';

  /// Index of the current step in [kOrderPipeline], or the last reached
  /// step for a cancelled order.
  int get stepIndex {
    final i = kOrderPipeline.indexOf(status);
    if (i >= 0) return i;
    final reached = history
        .map((e) => kOrderPipeline.indexOf(e.status))
        .where((i) => i >= 0);
    return reached.isEmpty ? 0 : reached.reduce((a, b) => a > b ? a : b);
  }

  factory OrderDetail.fromJson(Map<String, dynamic> json) {
    final pricing = json['pricing'] as Map<String, dynamic>? ?? {};
    final addr = json['deliveryAddress'] as Map<String, dynamic>? ?? {};
    final history =
        (json['statusHistory'] as List<dynamic>? ?? [])
            .map((e) => OrderStatusEvent.fromJson(e as Map<String, dynamic>))
            .toList()
          ..sort((a, b) => a.at.compareTo(b.at));
    final addressParts = [
      addr['street'],
      if (addr['building'] != null) 'Building ${addr['building']}',
      if (addr['floor'] != null) 'Floor ${addr['floor']}',
      if (addr['apartment'] != null) 'Apt ${addr['apartment']}',
      addr['district'],
      addr['city'],
    ].whereType<String>().where((p) => p.trim().isNotEmpty);

    return OrderDetail(
      summary: OrderSummary.fromJson(json),
      items: (json['items'] as List<dynamic>? ?? [])
          .map((e) => OrderLine.fromJson(e as Map<String, dynamic>))
          .toList(),
      history: history,
      address: addressParts.join(', '),
      subtotal: (pricing['subtotal'] as num?)?.toDouble() ?? 0,
      deliveryFee: (pricing['deliveryFee'] as num?)?.toDouble() ?? 0,
      discount: (pricing['couponDiscount'] as num?)?.toDouble() ?? 0,
      estimatedDelivery: DateTime.tryParse(
        json['estimatedDelivery'] as String? ?? '',
      ),
      cancelReason: json['cancelReason'] as String?,
    );
  }
}
