import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../models/category.dart';
import '../models/product.dart';

class CatalogRepository {
  CatalogRepository(this._api);

  final ApiClient _api;

  Future<List<Category>> fetchCategories() async {
    final body = await _api.get('/categories');
    return dataList(body, 'categories').map(Category.fromJson).toList();
  }

  Future<List<Product>> fetchMedicines({String? search}) async {
    final body = await _api.get(
      '/medicines',
      query: (search == null || search.isEmpty) ? null : {'search': search},
    );
    return dataList(body, 'medicines').map(Product.fromJson).toList();
  }

  /// Medicines with the same active ingredient.
  Future<List<Product>> fetchAlternatives(String medicineId) async {
    final body = await _api.get('/medicines/$medicineId/alternatives');
    return dataList(body, 'alternatives').map(Product.fromJson).toList();
  }

  Future<void> createMedicine(MedicineInput input) =>
      _api.post('/medicines', body: input.toJson());

  Future<void> updateMedicine(String id, MedicineInput input) =>
      _api.put('/medicines/$id', body: input.toJson());

  Future<void> deleteMedicine(String id) => _api.delete('/medicines/$id');
}

/// The fields an admin edits when creating or updating a medicine.
class MedicineInput {
  const MedicineInput({
    required this.name,
    required this.price,
    required this.categoryId,
    this.description,
    this.discountPercent = 0,
    this.stock = 0,
    this.images = const [],
    this.requiresPrescription = false,
    this.isFeatured = false,
  });

  final String name;
  final double price;
  final String categoryId;
  final String? description;
  final double discountPercent;
  final int stock;
  final List<String> images;
  final bool requiresPrescription;
  final bool isFeatured;

  Json toJson() => {
    'name': name,
    'price': price,
    'category': categoryId,
    if (description != null) 'description': description,
    if (images.isNotEmpty) 'images': images,
    'discountPercent': discountPercent,
    'stock': stock,
    'requiresPrescription': requiresPrescription,
    'isFeatured': isFeatured,
  };
}

final catalogRepositoryProvider = Provider<CatalogRepository>(
  (ref) => CatalogRepository(ref.watch(apiClientProvider)),
);

final categoriesProvider = FutureProvider<List<Category>>(
  (ref) => ref.watch(catalogRepositoryProvider).fetchCategories(),
);

final medicinesProvider = FutureProvider<List<Product>>(
  (ref) => ref.watch(catalogRepositoryProvider).fetchMedicines(),
);
