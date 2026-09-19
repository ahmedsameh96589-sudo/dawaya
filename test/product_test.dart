import 'package:dawayaa/core/config/app_config.dart';
import 'package:dawayaa/features/catalog/models/product.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Map<String, dynamic> medicine([Map<String, dynamic> overrides = const {}]) => {
        '_id': 'm1',
        'name': 'Panadol',
        'price': 50,
        'stock': 3,
        ...overrides,
      };

  test('applies the discount to the displayed price', () {
    final product = Product.fromJson(medicine({'discountPercent': 20}));

    expect(product.price, '40 EGP');
    expect(product.priceValue, 50);
    expect(product.discountPercent, 20);
  });

  test('resolves uploaded image paths against the API host', () {
    final product = Product.fromJson(medicine({
      'images': ['/uploads/panadol.png', 'box.png'],
    }));

    expect(product.images, [
      '${AppConfig.apiHost}/uploads/panadol.png',
      '${AppConfig.apiHost}/uploads/box.png',
    ]);
    expect(product.imageUrl, product.images.first);
  });

  test('adds a cache-busting version when the product was updated', () {
    final product = Product.fromJson(medicine({
      'images': ['https://cdn.example.com/a.png'],
      'updatedAt': '2026-09-01',
    }));

    expect(product.imageUrl, 'https://cdn.example.com/a.png?v=2026-09-01');
  });

  test('reads the category id from an object or a plain id', () {
    expect(
      Product.fromJson(medicine({'category': {'_id': 'c1', 'name': 'Pain'}})).categoryId,
      'c1',
    );
    expect(Product.fromJson(medicine({'category': 'c2'})).categoryId, 'c2');
  });

  test('builds a description from the active ingredient when missing', () {
    final product = Product.fromJson(medicine({
      'activeIngredient': 'Paracetamol',
      'strength': '500mg',
    }));

    expect(product.description, 'Active ingredient: Paracetamol (500mg)');
  });

  test('reports stock status', () {
    expect(Product.fromJson(medicine({'stock': 0})).isOutOfStock, isTrue);
    expect(Product.fromJson(medicine()).isOutOfStock, isFalse);
  });
}
