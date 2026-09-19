class Product {
  const Product({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.description,
    required this.categoryId,
    this.activeIngredient = '',
    this.strength = '',
    this.priceValue = 0,
    this.discountPercent = 0,
    this.stock = 0,
    this.images = const [],
    this.requiresPrescription = false,
    this.isFeatured = false,
  });

  final String id;
  final String name;
  final String price;
  final String imageUrl;
  final String description;
  final String categoryId;
  final String activeIngredient;
  final String strength;
  final double priceValue;
  final double discountPercent;
  final int stock;
  final List<String> images;
  final bool requiresPrescription;
  final bool isFeatured;

  bool get isOutOfStock => stock <= 0;

  factory Product.fromJson(Map<String, dynamic> json) {
    const String baseHostUrl = 'http://10.0.2.2:5001';
    final List<dynamic> rawImages = json['images'] as List<dynamic>? ?? [];
    final String updatedAt = json['updatedAt'] as String? ?? '';
    String addCacheBust(String url) {
      if (updatedAt.isEmpty) return url;
      final separator = url.contains('?') ? '&' : '?';
      return '$url${separator}v=$updatedAt';
    }

    String resolveImage(String image) {
      if (image.isEmpty) return '';
      if (image.startsWith('http')) return addCacheBust(image);
      if (image.startsWith('/uploads')) {
        return addCacheBust('$baseHostUrl$image');
      }
      return addCacheBust('$baseHostUrl/uploads/$image');
    }

    final List<String> images = rawImages
        .map((e) => resolveImage(e as String))
        .where((e) => e.isNotEmpty)
        .toList();
    final String imageUrl = images.isNotEmpty
        ? images.first
        : 'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?w=200';

    final dynamic category = json['category'];
    final String categoryId = category is Map
        ? category['_id'] as String? ?? ''
        : category as String? ?? '';

    final num priceNum = json['price'] as num? ?? 0;
    final num discount = json['discountPercent'] as num? ?? 0;
    final double finalPrice = priceNum * (1 - discount / 100);
    final num stockNum = json['stock'] as num? ?? 0;
    final bool requiresPrescription =
        json['requiresPrescription'] as bool? ?? false;
    final bool isFeatured = json['isFeatured'] as bool? ?? false;
    final String activeIngredient = json['activeIngredient'] as String? ?? '';
    final String strength = json['strength'] as String? ?? '';

    String description = (json['description'] as String? ?? '').trim();
    if (description.isEmpty) {
      description = (json['subtitle'] as String? ?? '').trim();
    }
    if (description.isEmpty) {
      final String ingredient = (json['activeIngredient'] as String? ?? '')
          .trim();
      final String strength = (json['strength'] as String? ?? '').trim();
      if (ingredient.isNotEmpty || strength.isNotEmpty) {
        description = strength.isNotEmpty
            ? 'Active ingredient: $ingredient ($strength)'
            : 'Active ingredient: $ingredient';
      }
    }
    if (description.isEmpty) {
      description = 'No description available.';
    }

    return Product(
      id: json['_id'] as String,
      name: json['name'] as String,
      price: '${finalPrice.toStringAsFixed(0)} EGP',
      imageUrl: imageUrl,
      description: description,
      categoryId: categoryId,
      activeIngredient: activeIngredient,
      strength: strength,
      priceValue: priceNum.toDouble(),
      discountPercent: discount.toDouble(),
      stock: stockNum.toInt(),
      images: images,
      requiresPrescription: requiresPrescription,
      isFeatured: isFeatured,
    );
  }
}
