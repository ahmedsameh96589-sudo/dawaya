import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../cart/models/order_request.dart';
import '../models/order_detail.dart';
import '../models/order_summary.dart';

class OrderRepository {
  OrderRepository(this._api);

  final ApiClient _api;

  /// Places an order and returns its id.
  Future<String> placeOrder(OrderRequest request) async {
    final body = await _api.post(
      '/orders',
      body: request.toJson(),
      timeout: const Duration(seconds: 15),
    );
    return dataObject(body, 'order')['_id'] as String? ?? '';
  }

  Future<List<OrderSummary>> fetchMyOrders({
    int page = 1,
    int limit = 20,
  }) async {
    final body = await _api.get(
      '/orders',
      query: {'page': '$page', 'limit': '$limit'},
    );
    return dataList(body, 'orders').map(OrderSummary.fromJson).toList();
  }

  Future<OrderDetail> fetchOrder(String id) async =>
      OrderDetail.fromJson(dataObject(await _api.get('/orders/$id'), 'order'));

  Future<OrderDetail> cancelOrder(String id, {String? reason}) async {
    final body = await _api.put(
      '/orders/$id/cancel',
      body: {if (reason != null && reason.isNotEmpty) 'reason': reason},
    );
    return OrderDetail.fromJson(dataObject(body, 'order'));
  }
}

final orderRepositoryProvider = Provider<OrderRepository>(
  (ref) => OrderRepository(ref.watch(apiClientProvider)),
);

final myOrdersProvider = FutureProvider.autoDispose<List<OrderSummary>>(
  (ref) => ref.watch(orderRepositoryProvider).fetchMyOrders(),
);

/// One order's details, refreshed every 30 seconds while it is still on
/// its way so status changes show up without a manual refresh.
final orderDetailProvider = FutureProvider.autoDispose
    .family<OrderDetail, String>((ref, id) async {
      final order = await ref.watch(orderRepositoryProvider).fetchOrder(id);
      if (!order.isCancelled && order.status != 'delivered') {
        final timer = Timer(
          const Duration(seconds: 30),
          () => ref.invalidateSelf(),
        );
        ref.onDispose(timer.cancel);
      }
      return order;
    });
