class CheckoutAddress {
  const CheckoutAddress({
    required this.label,
    required this.street,
    required this.city,
    this.building,
    this.floor,
    this.apartment,
    this.district,
    this.postalCode,
  });

  final String label;
  final String street;
  final String city;
  final String? building;
  final String? floor;
  final String? apartment;
  final String? district;
  final String? postalCode;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'label': label,
      'street': street,
      'city': city,
      if (building != null && building!.isNotEmpty) 'building': building,
      if (floor != null && floor!.isNotEmpty) 'floor': floor,
      if (apartment != null && apartment!.isNotEmpty) 'apartment': apartment,
      if (district != null && district!.isNotEmpty) 'district': district,
      if (postalCode != null && postalCode!.isNotEmpty) 'postalCode': postalCode,
    };
  }
}
