import 'package:dawayaa/features/catalog/data/prescription_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PrescriptionParser.extract', () {
    test('finds medicine lines and their dose, form and frequency', () {
      const text = '''
Dr. Ahmed Clinic
Panadol Extra 500mg tab twice daily
Augmentin 1g
Ventolin inhaler when needed
''';

      final meds = PrescriptionParser.extract(text);

      expect(meds.map((m) => m.name), ['Panadol Extra', 'Augmentin', 'Ventolin']);
      expect(meds[0].dose, '500mg');
      expect(meds[0].form, 'tab');
      expect(meds[0].frequency, 'twice');
      expect(meds[1].dose, '1g');
      expect(meds[2].form, 'inhaler');
    });

    test('ignores headers, dates and very short lines', () {
      const text = 'Dr. Mona Adel\n12/03/2026\nRx\nok';

      expect(PrescriptionParser.extract(text), isEmpty);
    });

    test('accepts frequency-only lines only when they are long enough', () {
      expect(PrescriptionParser.extract('od'), isEmpty);
      expect(
        PrescriptionParser.extract('Omeprazole once daily'),
        hasLength(1),
      );
    });

    test('matching is case-insensitive', () {
      final meds = PrescriptionParser.extract('BRUFEN 400 MG TABLET');

      expect(meds.single.dose, '400 MG');
      expect(meds.single.form, 'TABLET');
    });

    test('keeps the trimmed original line', () {
      final meds = PrescriptionParser.extract('   Zyrtec 10mg   ');

      expect(meds.single.rawLine, 'Zyrtec 10mg');
    });
  });

  group('PrescriptionParser.cleanName', () {
    test('takes the leading capitalised words', () {
      expect(PrescriptionParser.cleanName('Panadol Extra 500mg'), 'Panadol Extra');
    });

    test('falls back to the text before the first number', () {
      expect(PrescriptionParser.cleanName('panadol 500mg'), 'panadol');
    });
  });
}
