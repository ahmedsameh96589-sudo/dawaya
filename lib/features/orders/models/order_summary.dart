class OrderSummary {
  OrderSummary({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.total,
    required this.createdAt,
    required this.itemCount,
    required this.paymentMethod,
    required this.paymentStatus,
  });

  final String id;
  final String orderNumber;
  final String status;
  final double total;
  final DateTime createdAt;
  final int itemCount;
  final String paymentMethod;
  final String paymentStatus;

  factory OrderSummary.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> pricing =
        json['pricing'] as Map<String, dynamic>? ?? {};
    final List<dynamic> items = json['items'] as List<dynamic>? ?? [];
    final String createdAtRaw = json['createdAt'] as String? ?? '';
    return OrderSummary(
      id: json['_id'] as String? ?? '',
      orderNumber: json['orderNumber'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      total: (pricing['total'] as num?)?.toDouble() ?? 0,
      createdAt: DateTime.tryParse(createdAtRaw) ?? DateTime.now(),
      itemCount: items.length,
      paymentMethod: json['paymentMethod'] as String? ?? '',
      paymentStatus: json['paymentStatus'] as String? ?? 'pending',
    );
  }
}
