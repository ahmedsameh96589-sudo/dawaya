import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../cart/models/order_request.dart';
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
}

final orderRepositoryProvider = Provider<OrderRepository>(
  (ref) => OrderRepository(ref.watch(apiClientProvider)),
);

final myOrdersProvider = FutureProvider.autoDispose<List<OrderSummary>>(
  (ref) => ref.watch(orderRepositoryProvider).fetchMyOrders(),
);
