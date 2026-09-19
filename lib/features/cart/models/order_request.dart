import 'checkout_address.dart';

class OrderRequest {
  const OrderRequest({
    required this.deliveryAddress,
    required this.paymentMethod,
    this.notes,
  });

  final CheckoutAddress deliveryAddress;
  final String paymentMethod;
  final String? notes;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'deliveryAddress': deliveryAddress.toJson(),
      'paymentMethod': paymentMethod,
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
    };
  }
}
