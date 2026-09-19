import '../../catalog/models/product.dart';

class CartItem {
  CartItem({
    required this.product,
    this.quantity = 1,
  });

  final Product product;
  int quantity;

  factory CartItem.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> medicine =
        json['medicine'] as Map<String, dynamic>? ?? <String, dynamic>{};
    return CartItem(
      product: Product.fromJson(medicine),
      quantity: json['quantity'] as int? ?? 1,
    );
  }
}
