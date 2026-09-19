import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/auth_session.dart';
import '../../../core/widgets/async_states.dart';
import '../../auth/presentation/login_page.dart';
import '../data/order_repository.dart';
import '../models/order_summary.dart';
import 'order_details_page.dart';

class OrdersPage extends ConsumerWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!AuthSession.isLoggedIn) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Orders')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Please login to view your orders.'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const LoginPage()),
                  );
                },
                child: const Text('Login'),
              ),
            ],
          ),
        ),
      );
    }

    final orders = ref.watch(myOrdersProvider);
    Future<void> refresh() => ref.refresh(myOrdersProvider.future);

    return Scaffold(
      appBar: AppBar(title: const Text('My Orders')),
      body: RefreshIndicator(
        onRefresh: refresh,
        child: orders.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => ErrorRetryView(error: error, onRetry: refresh),
          data: (orders) => orders.isEmpty
              ? const EmptyStateView(
                  icon: Icons.receipt_long_outlined,
                  title: 'No orders yet',
                  message: 'Medicines you order will show up here.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: orders.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) =>
                      _OrderCard(order: orders[index]),
                ),
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});

  final OrderSummary order;

  @override
  Widget build(BuildContext context) {
    final String created =
        '${order.createdAt.day}/${order.createdAt.month}/${order.createdAt.year}';
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => OrderDetailsPage(orderId: order.id),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 10,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    order.orderNumber.isEmpty ? 'Order' : order.orderNumber,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                _StatusBadge(status: order.status),
              ],
            ),
            const SizedBox(height: 8),
            Text('Items: ${order.itemCount}'),
            const SizedBox(height: 4),
            Text('Total: ${order.total.toStringAsFixed(0)} EGP'),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(child: Text('Date: $created')),
                const Text(
                  'Track order',
                  style: TextStyle(
                    color: Color(0xFF0B2A7D),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: Color(0xFF0B2A7D),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  Color _color() {
    switch (status) {
      case 'confirmed':
        return Colors.blue;
      case 'preparing':
        return Colors.orange;
      case 'out_for_delivery':
        return Colors.purple;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color().withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.replaceAll('_', ' '),
        style: TextStyle(
          color: _color(),
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}
