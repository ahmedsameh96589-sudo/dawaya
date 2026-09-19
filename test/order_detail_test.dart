import 'package:dawayaa/features/orders/models/order_detail.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> order(
  String status,
  List<String> history, {
  String? reason,
}) => {
  '_id': 'o1',
  'orderNumber': 'DWY-1',
  'status': status,
  'pricing': {'subtotal': 100, 'deliveryFee': 20, 'total': 120},
  'items': [
    {'name': 'Panadol', 'quantity': 2, 'subtotal': 100},
  ],
  'deliveryAddress': {
    'street': '5 Tahrir St',
    'building': '12',
    'city': 'Cairo',
  },
  'statusHistory': [
    for (var i = 0; i < history.length; i++)
      {'status': history[i], 'at': '2026-09-19T10:0$i:00Z', 'note': ''},
  ],
  if (reason != null) 'cancelReason': reason,
};

void main() {
  test('steps follow the delivery pipeline', () {
    expect(OrderDetail.fromJson(order('pending', ['pending'])).stepIndex, 0);
    expect(
      OrderDetail.fromJson(
        order('preparing', ['pending', 'confirmed', 'preparing']),
      ).stepIndex,
      2,
    );
    expect(OrderDetail.fromJson(order('delivered', [])).stepIndex, 4);
  });

  test('a cancelled order remembers how far it got', () {
    final o = OrderDetail.fromJson(
      order('cancelled', [
        'pending',
        'confirmed',
        'cancelled',
      ], reason: 'Changed my mind'),
    );

    expect(o.isCancelled, isTrue);
    expect(o.stepIndex, 1);
    expect(o.canCancel, isFalse);
    expect(o.cancelReason, 'Changed my mind');
  });

  test('only pending and confirmed orders can be cancelled', () {
    expect(OrderDetail.fromJson(order('pending', [])).canCancel, isTrue);
    expect(OrderDetail.fromJson(order('confirmed', [])).canCancel, isTrue);
    expect(OrderDetail.fromJson(order('preparing', [])).canCancel, isFalse);
    expect(OrderDetail.fromJson(order('delivered', [])).canCancel, isFalse);
  });

  test('history is sorted oldest first and the address is readable', () {
    final o = OrderDetail.fromJson(
      order('confirmed', ['confirmed', 'pending']),
    );

    expect(o.history.map((e) => e.status), ['confirmed', 'pending']);
    expect(o.address, '5 Tahrir St, Building 12, Cairo');
    expect(o.items.single.quantity, 2);
    expect(o.summary.total, 120);
  });
}
