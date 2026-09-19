import 'package:dawayaa/features/orders/data/order_repository.dart';
import 'package:dawayaa/features/orders/models/order_detail.dart';
import 'package:dawayaa/features/orders/presentation/order_details_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

OrderDetail sample(String status, List<String> history) =>
    OrderDetail.fromJson({
      '_id': 'o1',
      'orderNumber': 'DWY-42',
      'status': status,
      'paymentMethod': 'cash_on_delivery',
      'pricing': {'subtotal': 100, 'deliveryFee': 20, 'total': 120},
      'items': [
        {'name': 'Panadol Extra', 'quantity': 2, 'subtotal': 100},
      ],
      'deliveryAddress': {'street': '5 Tahrir St', 'city': 'Cairo'},
      'statusHistory': [
        for (var i = 0; i < history.length; i++)
          {
            'status': history[i],
            'at': '2026-09-19T10:0$i:00Z',
            'note': i == 0 ? 'Order placed successfully.' : '',
          },
      ],
    });

Widget page(OrderDetail order) => ProviderScope(
  overrides: [orderDetailProvider.overrideWith((ref, id) async => order)],
  child: const MaterialApp(home: OrderDetailsPage(orderId: 'o1')),
);

void main() {
  testWidgets(
    'shows the timeline, items and address for an order in progress',
    (tester) async {
      await tester.pumpWidget(
        page(sample('preparing', ['pending', 'confirmed', 'preparing'])),
      );
      await tester.pumpAndSettle();

      expect(find.text('DWY-42'), findsOneWidget);
      expect(find.text('Preparing your medicines'), findsOneWidget);
      expect(find.text('Order placed successfully.'), findsOneWidget);
      expect(find.text('2 × Panadol Extra'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('5 Tahrir St, Cairo'), 200);
      expect(find.text('5 Tahrir St, Cairo'), findsOneWidget);
      expect(find.text('Cancel order'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('offers cancellation while the order is still pending', (
    tester,
  ) async {
    await tester.pumpWidget(page(sample('pending', ['pending'])));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Cancel order'), 200);
    await tester.ensureVisible(find.text('Cancel order'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cancel order'));
    await tester.pumpAndSettle();

    expect(find.text('Cancel this order?'), findsOneWidget);
  });

  testWidgets('explains a cancelled order', (tester) async {
    await tester.pumpWidget(
      page(sample('cancelled', ['pending', 'cancelled'])),
    );
    await tester.pumpAndSettle();

    expect(find.text('Order cancelled'), findsOneWidget);
    expect(find.text('This order was cancelled.'), findsOneWidget);
  });
}
