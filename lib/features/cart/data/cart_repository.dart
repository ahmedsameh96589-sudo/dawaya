import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../models/cart_model.dart';

/// Server-side cart. Every call returns the cart's items after the change.
class CartRepository {
  CartRepository(this._api);

  final ApiClient _api;

  Future<List<CartItem>> fetchCart() async => _items(await _api.get('/cart'));

  Future<List<CartItem>> addToCart({
    required String medicineId,
    int quantity = 1,
  }) async => _items(
    await _api.post(
      '/cart/add',
      body: {'medicineId': medicineId, 'quantity': quantity},
    ),
  );

  Future<List<CartItem>> updateCartItem({
    required String medicineId,
    required int quantity,
  }) async => _items(
    await _api.put(
      '/cart/update',
      body: {'medicineId': medicineId, 'quantity': quantity},
    ),
  );

  Future<List<CartItem>> removeFromCart(String medicineId) async =>
      _items(await _api.delete('/cart/remove/$medicineId'));

  Future<List<CartItem>> clearCart() async =>
      _items(await _api.delete('/cart/clear'));

  List<CartItem> _items(Json body) {
    final cart = dataObject(body, 'cart');
    return (cart['items'] as List<dynamic>? ?? const [])
        .map((e) => CartItem.fromJson(e as Json))
        .toList();
  }
}

final cartRepositoryProvider = Provider<CartRepository>(
  (ref) => CartRepository(ref.watch(apiClientProvider)),
);
