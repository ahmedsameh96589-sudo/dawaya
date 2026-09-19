import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/uploads.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/async_states.dart';
import '../data/order_repository.dart';
import '../models/order_detail.dart';

/// Tracks one order: a step timeline built from the order's status history,
/// the items, the delivery address, and a cancel button while that is
/// still allowed.
class OrderDetailsPage extends ConsumerWidget {
  const OrderDetailsPage({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = orderDetailProvider(orderId);
    final order = ref.watch(provider);
    Future<void> refresh() => ref.refresh(provider.future);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(order.value?.summary.orderNumber ?? 'Order'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: refresh,
        child: order.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => ErrorRetryView(error: error, onRetry: refresh),
          data: (order) => ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _TimelineCard(order: order),
              const SizedBox(height: 16),
              _ItemsCard(order: order),
              const SizedBox(height: 16),
              _DeliveryCard(order: order),
              if (order.canCancel) ...[
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: () => _confirmCancel(context, ref),
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Cancel order'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmCancel(BuildContext context, WidgetRef ref) async {
    final reason = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel this order?'),
        content: TextField(
          controller: reason,
          decoration: const InputDecoration(hintText: 'Reason (optional)'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep order'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Cancel order'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await ref
          .read(orderRepositoryProvider)
          .cancelOrder(orderId, reason: reason.text.trim());
      ref.invalidate(orderDetailProvider(orderId));
      ref.invalidate(myOrdersProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Order cancelled.')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }
}

class _TimelineCard extends StatelessWidget {
  const _TimelineCard({required this.order});

  final OrderDetail order;

  static const _labels = {
    'pending': 'Order placed',
    'confirmed': 'Confirmed by pharmacy',
    'preparing': 'Preparing your medicines',
    'out_for_delivery': 'On its way',
    'delivered': 'Delivered',
  };

  static const _icons = {
    'pending': Icons.receipt_long_outlined,
    'confirmed': Icons.verified_outlined,
    'preparing': Icons.medication_outlined,
    'out_for_delivery': Icons.delivery_dining_outlined,
    'delivered': Icons.home_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final current = order.stepIndex;
    final reachedAt = {for (final e in order.history) e.status: e};

    return _Card(
      title: order.isCancelled ? 'Order cancelled' : 'Order status',
      child: Column(
        children: [
          for (var i = 0; i < kOrderPipeline.length; i++)
            _TimelineStep(
              icon: _icons[kOrderPipeline[i]]!,
              label: _labels[kOrderPipeline[i]]!,
              event: reachedAt[kOrderPipeline[i]],
              state: order.isCancelled
                  ? (i <= current ? _StepState.cancelled : _StepState.upcoming)
                  : i < current
                  ? _StepState.done
                  : i == current
                  ? _StepState.current
                  : _StepState.upcoming,
              isLast: i == kOrderPipeline.length - 1,
            ),
          if (order.isCancelled)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 18, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      order.cancelReason?.isNotEmpty == true
                          ? order.cancelReason!
                          : 'This order was cancelled.',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            )
          else if (order.estimatedDelivery != null &&
              order.status != 'delivered')
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                'Estimated delivery: ${_date(order.estimatedDelivery!)}',
                style: const TextStyle(color: Colors.black54),
              ),
            ),
        ],
      ),
    );
  }
}

enum _StepState { done, current, upcoming, cancelled }

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({
    required this.icon,
    required this.label,
    required this.event,
    required this.state,
    required this.isLast,
  });

  final IconData icon;
  final String label;
  final OrderStatusEvent? event;
  final _StepState state;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final color = switch (state) {
      _StepState.done => AppColors.brandAccent,
      _StepState.current => AppColors.brandBlue,
      _StepState.cancelled => Colors.red.shade300,
      _StepState.upcoming => Colors.black26,
    };
    final filled = state != _StepState.upcoming;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: filled ? color : Colors.transparent,
                  border: Border.all(color: color, width: 2),
                  boxShadow: state == _StepState.current
                      ? [
                          BoxShadow(
                            color: color.withOpacity(0.35),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: filled ? Colors.white : color,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: state == _StepState.done
                        ? AppColors.brandAccent
                        : Colors.black12,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: 6, bottom: isLast ? 0 : 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: state == _StepState.current
                          ? FontWeight.w700
                          : FontWeight.w600,
                      color: state == _StepState.upcoming
                          ? Colors.black38
                          : Colors.black87,
                    ),
                  ),
                  if (event != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      _date(event!.at, withTime: true),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black45,
                      ),
                    ),
                    if (event!.note.isNotEmpty)
                      Text(
                        event!.note,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black54,
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemsCard extends StatelessWidget {
  const _ItemsCard({required this.order});

  final OrderDetail order;

  @override
  Widget build(BuildContext context) {
    return _Card(
      title: 'Items (${order.items.length})',
      child: Column(
        children: [
          for (final line in order.items)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      Uploads.resolve(line.image),
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 44,
                        height: 44,
                        color: AppColors.cardBlue,
                        child: const Icon(
                          Icons.medication,
                          color: AppColors.brandBlue,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${line.quantity} × ${line.name}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text('${line.subtotal.toStringAsFixed(0)} EGP'),
                ],
              ),
            ),
          const Divider(),
          _priceRow('Subtotal', order.subtotal),
          _priceRow('Delivery', order.deliveryFee),
          if (order.discount > 0) _priceRow('Discount', -order.discount),
          const SizedBox(height: 4),
          _priceRow('Total', order.summary.total, bold: true),
        ],
      ),
    );
  }

  Widget _priceRow(String label, double value, {bool bold = false}) {
    final style = TextStyle(
      fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text('${value.toStringAsFixed(0)} EGP', style: style),
        ],
      ),
    );
  }
}

class _DeliveryCard extends StatelessWidget {
  const _DeliveryCard({required this.order});

  final OrderDetail order;

  @override
  Widget build(BuildContext context) {
    final payment = order.summary.paymentMethod == 'cash_on_delivery'
        ? 'Cash on delivery'
        : 'Card (demo)';
    return _Card(
      title: 'Delivery',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoRow(
            Icons.location_on_outlined,
            order.address.isEmpty ? '—' : order.address,
          ),
          const SizedBox(height: 8),
          _infoRow(
            Icons.payments_outlined,
            '$payment · ${order.summary.paymentStatus}',
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 20, color: AppColors.brandBlue),
      const SizedBox(width: 10),
      Expanded(child: Text(text)),
    ],
  );
}

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

String _date(DateTime d, {bool withTime = false}) {
  final local = d.toLocal();
  final date = '${local.day}/${local.month}/${local.year}';
  if (!withTime) return date;
  final h = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final m = local.minute.toString().padLeft(2, '0');
  return '$date, $h:$m ${local.hour < 12 ? 'AM' : 'PM'}';
}
