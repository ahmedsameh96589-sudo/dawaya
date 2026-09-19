import 'package:flutter/foundation.dart';

import '../../../core/services/api_services.dart';
import '../../../core/services/auth_session.dart';
import '../../catalog/models/product.dart';
import 'cart_model.dart';

class CartController extends ChangeNotifier {
  final Map<String, CartItem> _items = <String, CartItem>{};
  bool _isSyncing = false;
  bool _loaded = false;
  String? _error;

  List<CartItem> get items => _items.values.toList();
  bool get isSyncing => _isSyncing;
  String? get error => _error;

  void resetLocal() {
    _items.clear();
    _loaded = false;
    _error = null;
    notifyListeners();
  }

  bool _hasAuth() {
    return AuthSession.isLoggedIn;
  }

  void _requireAuth() {
    if (!_hasAuth()) {
      throw Exception('Please login to use cart.');
    }
  }

  void _setItems(List<CartItem> items) {
    _items
      ..clear()
      ..addEntries(items.map((item) => MapEntry(item.product.id, item)));
  }

  Future<void> loadFromServer({bool force = false}) async {
    if (_isSyncing) return;
    if (!force && _loaded) return;
    if (!_hasAuth()) {
      _error = 'Please login to sync cart.';
      notifyListeners();
      return;
    }
    _isSyncing = true;
    _error = null;
    notifyListeners();
    try {
      final items = await ApiService.fetchCart();
      _setItems(items);
      _loaded = true;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  Future<void> add(Product product) async {
    _requireAuth();
    if (product.isOutOfStock) {
      throw Exception('Out of stock');
    }
    _isSyncing = true;
    _error = null;
    notifyListeners();
    try {
      final items = await ApiService.addToCart(
        medicineId: product.id,
        quantity: 1,
      );
      _setItems(items);
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  Future<void> remove(Product product) async {
    _requireAuth();
    _isSyncing = true;
    _error = null;
    notifyListeners();
    try {
      final items = await ApiService.removeFromCart(product.id);
      _setItems(items);
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  Future<void> increment(Product product) async {
    await add(product);
  }

  Future<void> decrement(Product product) async {
    _requireAuth();
    final CartItem? existing = _items[product.id];
    if (existing == null) return;
    if (existing.quantity <= 1) {
      await remove(product);
      return;
    }

    _isSyncing = true;
    _error = null;
    notifyListeners();
    try {
      final items = await ApiService.updateCartItem(
        medicineId: product.id,
        quantity: existing.quantity - 1,
      );
      _setItems(items);
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  Future<void> clear() async {
    _requireAuth();
    _isSyncing = true;
    _error = null;
    notifyListeners();
    try {
      final items = await ApiService.clearCart();
      _setItems(items);
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  int get totalItems {
    return _items.values.fold<int>(
      0,
      (int sum, CartItem item) => sum + item.quantity,
    );
  }

  double get totalPrice {
    return _items.values.fold<double>(
      0,
      (double sum, CartItem item) =>
          sum + _parsePrice(item.product.price) * item.quantity,
    );
  }

  double _parsePrice(String value) {
    final String cleaned = value.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(cleaned) ?? 0;
  }
}
