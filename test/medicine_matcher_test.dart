import 'package:dawayaa/features/catalog/data/medicine_matcher.dart';
import 'package:dawayaa/features/catalog/data/prescription_parser.dart';
import 'package:dawayaa/features/catalog/models/product.dart';
import 'package:flutter_test/flutter_test.dart';

Product product(
  String id,
  String name, {
  String ingredient = '',
  String strength = '',
}) => Product.fromJson({
  '_id': id,
  'name': name,
  'price': 10,
  'stock': 5,
  'activeIngredient': ingredient,
  'strength': strength,
});

MedicineResult scanned(String line) => PrescriptionParser.extract(line).single;

void main() {
  final catalog = [
    product(
      'p1',
      'Panadol Extra',
      ingredient: 'Paracetamol',
      strength: '500mg',
    ),
    product('p2', 'Panadol Cold & Flu', ingredient: 'Paracetamol'),
    product('a1', 'Augmentin 1g', ingredient: 'Amoxicillin Clavulanate'),
    product('b1', 'Brufen 400mg', ingredient: 'Ibuprofen'),
    product('v1', 'Ventolin Inhaler', ingredient: 'Salbutamol'),
  ];

  test('matches an exact name', () {
    final match = MedicineMatcher.match(scanned('Brufen 400mg tab'), catalog);

    expect(match?.product.id, 'b1');
    expect(match!.confidence, greaterThan(0.95));
  });

  test('tolerates OCR mistakes', () {
    expect(
      MedicineMatcher.match(
        scanned('Panad0l Extra 500mg'),
        catalog,
      )?.product.id,
      'p1',
    );
    expect(
      MedicineMatcher.match(scanned('Augrnentin 1g'), catalog)?.product.id,
      'a1',
    );
  });

  test('matches by active ingredient when the brand is not stocked', () {
    final match = MedicineMatcher.match(
      scanned('Ibuprofen 400mg tablet'),
      catalog,
    );

    expect(match?.product.id, 'b1');
  });

  test('prefers the product whose name covers more of the scanned words', () {
    expect(
      MedicineMatcher.match(scanned('Panadol Extra tab'), catalog)?.product.id,
      'p1',
    );
  });

  test('returns null when nothing is close enough', () {
    expect(MedicineMatcher.match(scanned('Concor 5mg tab'), catalog), isNull);
  });

  test('ignores form words so they do not create false matches', () {
    expect(MedicineMatcher.match(scanned('Zyrtec inhaler'), catalog), isNull);
  });
}
