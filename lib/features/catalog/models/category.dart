class Category {
  const Category({
    required this.id,
    required this.name,
    required this.imageUrl,
  });

  final String id;
  final String name;
  final String imageUrl;

  factory Category.fromJson(Map<String, dynamic> json) {
    final String rawName = (json['name'] as String? ?? '').trim();
    final String image = (json['image'] as String? ?? '').trim();
    final String imageUrl = _resolveImageUrl(image, rawName);
    return Category(
      id: json['_id'] as String,
      name: rawName,
      imageUrl: imageUrl,
    );
  }

  static String _normalizeName(String value) {
    return value.toLowerCase().trim();
  }

  static String _resolveImageUrl(String image, String categoryName) {
    const String baseHostUrl = 'http://localhost:5001';
    final normalizedImage = image.trim();

    if (normalizedImage.isEmpty || normalizedImage == 'default-category.png') {
      return _fallbackImageForName(categoryName);
    }

    if (normalizedImage.startsWith('http')) return normalizedImage;
    if (normalizedImage.startsWith('/uploads')) {
      return '$baseHostUrl$normalizedImage';
    }
    return '$baseHostUrl/uploads/$normalizedImage';
  }

  static const Map<String, String> _arabicCategoryNames = {
    'pain relief': 'مسكنات الألم',
    'painkiller': 'مسكنات الألم',
    'antibiotics': 'مضادات حيوية',
    'vitamins & supplements': ' فيتامينات و مكملات غذائية',
    'chronic disease': 'مرض مزمن',
    'baby care': 'العناية بالطفل',
    'mother care': 'العناية بالأم',
    'skin care': 'العناية بالبشرة',
    'hair care': 'العناية بالشعر',
    'dental care': 'العناية بالأسنان',
    'cold & flu': 'البرد والإنفلونزا',
    'diabetes': 'السكري',
    'heart': 'القلب',
    'stomach': 'المعدة',
    'allergy': 'الحساسية',
  };

  static const Map<String, String> _categoryFallbackImages = {
    'pain relief':
        'https://m.media-amazon.com/images/I/61grcfYAnAL._AC_SL1000_.jpg',
    'painkiller':
        'https://images.unsplash.com/photo-1587854692152-cbe660dbde88?w=300',
    'antibiotics':
        'https://images.unsplash.com/photo-1471864190281-a93a3070b6de?w=300',
    'vitamins':
        'https://images.unsplash.com/photo-1616671276441-2f2c277b8bf2?w=300',
    'supplements':
        'https://images.unsplash.com/photo-1579722821273-0f6c7d44362f?w=300',
    'baby care':
        'https://images.unsplash.com/photo-1515488042361-ee00e0ddd4e4?w=300',
    'mother care':
        'https://images.unsplash.com/photo-1505751172876-fa1923c5c528?w=300',
    'skin care':
        'https://images.unsplash.com/photo-1522335789203-aabd1fc54bc9?w=300',
    'hair care':
        'https://images.unsplash.com/photo-1522337360788-8b13dee7a37e?w=300',
    'dental care':
        'https://images.unsplash.com/photo-1606811971618-4486d14f3f99?w=300',
    'cold & flu':
        'https://images.unsplash.com/photo-1603398938378-e54eab446dde?w=300',
    'diabetes':
        'https://images.unsplash.com/photo-1579165466949-3180a3d056d1?w=300',
    'heart':
        'https://images.unsplash.com/photo-1530026405186-ed1f139313f8?w=300',
    'stomach':
        'https://images.unsplash.com/photo-1576091160399-112ba8d25d1d?w=300',
    'allergy':
        'https://images.unsplash.com/photo-1582719478250-c89cae4dc85b?w=300',
  };

  static String _fallbackImageForName(String categoryName) {
    final normalized = _normalizeName(categoryName);
    return _categoryFallbackImages[normalized] ??
        'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?w=300';
  }

  String localizedName(String languageCode) {
    if (languageCode != 'ar') return name;
    final normalized = _normalizeName(name);
    return _arabicCategoryNames[normalized] ?? name;
  }
}
