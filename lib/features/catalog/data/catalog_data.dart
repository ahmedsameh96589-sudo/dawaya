import '../models/category.dart';
import '../models/product.dart';

class CatalogData {
  CatalogData._();

  static const List<Category> categories = <Category>[
    Category(
      id: 'painkillers',
      name: 'Painkillers',
      imageUrl:
          'https://images.unsplash.com/photo-1505751172876-fa1923c5c528?w=200',
    ),
    Category(
      id: 'antibiotics',
      name: 'Antibiotics',
      imageUrl:
          'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?w=200',
    ),
    Category(
      id: 'cold_flu',
      name: 'Cold & Flu',
      imageUrl:
          'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=200',
    ),
    Category(
      id: 'diabetes',
      name: 'Diabetes',
      imageUrl:
          'https://images.unsplash.com/photo-1502741126161-b048400d54ef?w=200',
    ),
    Category(
      id: 'stomach_digestion',
      name: 'Stomach & Digestion',
      imageUrl:
          'https://images.unsplash.com/photo-1505576391880-b3f9d713dc4f?w=200',
    ),
  ];

  static const List<Product> products = <Product>[
    Product(
      id: 'panadol_extra',
      name: 'Panadol Extra',
      price: '100 EGP',
      imageUrl:
          'https://images.unsplash.com/photo-1580281658223-9b93f18ae9ae?w=600',
      description:
          'Pain reliever and fever reducer for headaches, body aches, and fever.',
      categoryId: 'painkillers',
    ),
    Product(
      id: 'brufen_400',
      name: 'Brufen 400mg',
      price: '80 EGP',
      imageUrl:
          'https://images.unsplash.com/photo-1587854692152-cbe660dbde88?w=600',
      description:
          'Anti-inflammatory pain relief for muscle pain, fever, and headaches.',
      categoryId: 'painkillers',
    ),
    Product(
      id: 'paracetamol_500',
      name: 'Paracetamol 500mg',
      price: '60 EGP',
      imageUrl:
          'https://images.unsplash.com/photo-1584308666999-f0a7c2806a44?w=600',
      description:
          'Gentle pain relief and fever control for daily use.',
      categoryId: 'painkillers',
    ),
    Product(
      id: 'cataflam_25',
      name: 'Cataflam 25mg',
      price: '80 EGP',
      imageUrl:
          'https://images.unsplash.com/photo-1587854692152-cbe660dbde88?w=600',
      description:
          'Diclofenac potassium for pain and inflammation relief.',
      categoryId: 'painkillers',
    ),
    Product(
      id: 'augmentin_1g',
      name: 'Augmentin 1g',
      price: '150 EGP',
      imageUrl:
          'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?w=600',
      description:
          'Broad-spectrum antibiotic for respiratory and skin infections.',
      categoryId: 'antibiotics',
    ),
    Product(
      id: 'amoxicillin_500',
      name: 'Amoxicillin 500mg',
      price: '120 EGP',
      imageUrl:
          'https://images.unsplash.com/photo-1587854692152-cbe660dbde88?w=600',
      description: 'Penicillin antibiotic for bacterial infections.',
      categoryId: 'antibiotics',
    ),
    Product(
      id: 'azithromycin_500',
      name: 'Azithromycin 500mg',
      price: '140 EGP',
      imageUrl:
          'https://images.unsplash.com/photo-1580281658223-9b93f18ae9ae?w=600',
      description: 'Macrolide antibiotic for chest and throat infections.',
      categoryId: 'antibiotics',
    ),
    Product(
      id: 'cefuroxime_500',
      name: 'Cefuroxime 500mg',
      price: '160 EGP',
      imageUrl:
          'https://images.unsplash.com/photo-1584308666999-f0a7c2806a44?w=600',
      description: 'Second-generation cephalosporin antibiotic.',
      categoryId: 'antibiotics',
    ),
    Product(
      id: 'actifed',
      name: 'Actifed',
      price: '110 EGP',
      imageUrl:
          'https://images.unsplash.com/photo-1502741126161-b048400d54ef?w=600',
      description: 'Relief for congestion, runny nose, and sneezing.',
      categoryId: 'cold_flu',
    ),
    Product(
      id: 'tylol',
      name: 'Tylol',
      price: '95 EGP',
      imageUrl:
          'https://images.unsplash.com/photo-1587854692152-cbe660dbde88?w=600',
      description: 'Cold and flu relief with pain and fever control.',
      categoryId: 'cold_flu',
    ),
    Product(
      id: 'flurest',
      name: 'Flurest',
      price: '105 EGP',
      imageUrl:
          'https://images.unsplash.com/photo-1580281658223-9b93f18ae9ae?w=600',
      description: 'Multi-symptom flu relief for day and night.',
      categoryId: 'cold_flu',
    ),
    Product(
      id: 'panadol_cold',
      name: 'Panadol Cold & Flu',
      price: '115 EGP',
      imageUrl:
          'https://images.unsplash.com/photo-1584308666999-f0a7c2806a44?w=600',
      description: 'Targeted relief for flu symptoms and fever.',
      categoryId: 'cold_flu',
    ),
    Product(
      id: 'metformin_500',
      name: 'Metformin 500mg',
      price: '130 EGP',
      imageUrl:
          'https://images.unsplash.com/photo-1505576391880-b3f9d713dc4f?w=600',
      description: 'Helps control blood sugar for type 2 diabetes.',
      categoryId: 'diabetes',
    ),
    Product(
      id: 'gliclazide_80',
      name: 'Gliclazide 80mg',
      price: '125 EGP',
      imageUrl:
          'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?w=600',
      description: 'Oral diabetes medication to lower blood sugar.',
      categoryId: 'diabetes',
    ),
    Product(
      id: 'insulin_pen',
      name: 'Insulin Pen',
      price: '300 EGP',
      imageUrl:
          'https://images.unsplash.com/photo-1505751172876-fa1923c5c528?w=600',
      description: 'Convenient insulin delivery for daily use.',
      categoryId: 'diabetes',
    ),
    Product(
      id: 'omeprazole_20',
      name: 'Omeprazole 20mg',
      price: '90 EGP',
      imageUrl:
          'https://images.unsplash.com/photo-1587854692152-cbe660dbde88?w=600',
      description: 'Reduces stomach acid and heartburn symptoms.',
      categoryId: 'stomach_digestion',
    ),
    Product(
      id: 'gaviscon',
      name: 'Gaviscon',
      price: '85 EGP',
      imageUrl:
          'https://images.unsplash.com/photo-1584308666999-f0a7c2806a44?w=600',
      description: 'Soothes acid reflux and indigestion quickly.',
      categoryId: 'stomach_digestion',
    ),
    Product(
      id: 'antinal',
      name: 'Antinal',
      price: '70 EGP',
      imageUrl:
          'https://images.unsplash.com/photo-1502741126161-b048400d54ef?w=600',
      description: 'Supports digestive comfort and gut health.',
      categoryId: 'stomach_digestion',
    ),
    Product(
      id: 'pantoprazole_40',
      name: 'Pantoprazole 40mg',
      price: '95 EGP',
      imageUrl:
          'https://images.unsplash.com/photo-1580281658223-9b93f18ae9ae?w=600',
      description: 'Long-lasting relief from acid-related discomfort.',
      categoryId: 'stomach_digestion',
    ),
  ];

  static List<Product> productsForCategory(String categoryId) {
    return products
        .where((Product product) => product.categoryId == categoryId)
        .toList();
  }

  static List<Product> relatedProducts(Product product, {int limit = 2}) {
    return products
        .where((Product item) =>
            item.categoryId == product.categoryId && item.id != product.id)
        .take(limit)
        .toList();
  }

  static List<Product> get featuredProducts {
    return products.take(6).toList();
  }
}
