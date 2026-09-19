import 'dart:math' as math;

import '../models/product.dart';
import 'prescription_parser.dart';

/// A catalog product that a scanned prescription line most likely refers to.
class MedicineMatch {
  const MedicineMatch({required this.product, required this.confidence});

  final Product product;

  /// 0–1. Matches below [MedicineMatcher.threshold] are not returned.
  final double confidence;
}

/// Finds the catalog product for a medicine read from a prescription photo.
///
/// OCR output is noisy ("Panad0l", "Augrnentin"), so words are compared by
/// edit distance rather than exact equality. Dosage-form words and units
/// ("tab", "mg") are ignored, and a matching strength ("500mg") breaks ties
/// between products that share a name.
class MedicineMatcher {
  MedicineMatcher._();

  static const double threshold = 0.72;

  static const Set<String> _noise = {
    'tab', 'tabs', 'tablet', 'tablets', 'cap', 'caps', 'capsule', 'capsules',
    'syrup', 'drops', 'injection', 'inj', 'cream', 'ointment', 'gel', 'patch',
    'inhaler', 'spray', 'susp', 'suspension', 'mg', 'mcg', 'ml', 'g', 'iu',
    'unit', 'units', 'rx', 'sig', 'x',
    // Dosing instructions that often share the line with the name.
    'once', 'twice', 'three', 'times', 'daily', 'every', 'morning', 'night',
    'bd', 'tds', 'qid', 'od', 'bid', 'prn', 'sos', 'stat', 'after', 'before',
    'meals',
    'at',
    'in',
    'on',
    'of',
    'the',
    'and',
    'per',
    'po',
    'by',
    'to',
    'day',
    'days',
    'for',
    'week',
    'weeks',
    'hours',
  };

  static MedicineMatch? match(MedicineResult scanned, List<Product> catalog) {
    // The whole line, not just the parsed name: the parser stops at the first
    // non-letter, so "Panad0l Extra" would otherwise shrink to "Panad".
    final query = _words(scanned.rawLine);
    if (query.isEmpty) return null;
    final dose = _digits(scanned.dose ?? '');

    MedicineMatch? best;
    for (final product in catalog) {
      final name = _words(product.name);
      var score = math.max(
        _similarity(query, name),
        0.9 * _similarity(query, _words(product.activeIngredient)),
      );
      // Short codes like "C", "D3" or "B12" name different products even
      // when the rest of the name is identical, so they must agree.
      if (_conflictingCodes(query, name)) continue;

      // A one-word brand ("Panadol") still matches a variant on the
      // prescription ("Panadol Extra"), but scored as a best guess.
      if (name.length == 1) {
        score = math.max(score, 0.88 * _ratio(query.first, name.single));
      }
      if (score < threshold) continue;

      final strength = _digits('${product.name} ${product.strength}');
      if (dose.isNotEmpty && strength.contains(dose)) {
        score = math.min(1, score + 0.05);
      }
      if (best == null || score > best.confidence) {
        best = MedicineMatch(product: product, confidence: score);
      }
    }
    return best;
  }

  static bool _conflictingCodes(List<String> a, List<String> b) {
    bool isCode(String w) => w.length <= 3 || w.contains(RegExp(r'\d'));
    final codesA = a.where(isCode).toSet();
    final codesB = b.where(isCode).toSet();
    return codesA.isNotEmpty &&
        codesB.isNotEmpty &&
        codesA.intersection(codesB).isEmpty;
  }

  /// How well every query word is covered by some candidate word, weighted
  /// by word length so short words matter less.
  static double _similarity(List<String> query, List<String> candidate) {
    if (candidate.isEmpty) return 0;
    var total = 0.0;
    var weight = 0;
    for (final word in query) {
      var bestWord = 0.0;
      for (final other in candidate) {
        bestWord = math.max(bestWord, _ratio(word, other));
      }
      total += bestWord * word.length;
      weight += word.length;
    }
    return total / weight;
  }

  /// 1 − normalized Levenshtein distance.
  static double _ratio(String a, String b) {
    if (a == b) return 1;
    final longest = math.max(a.length, b.length);
    return 1 - _levenshtein(a, b) / longest;
  }

  static int _levenshtein(String a, String b) {
    var previous = List<int>.generate(b.length + 1, (i) => i);
    for (var i = 1; i <= a.length; i++) {
      final current = List<int>.filled(b.length + 1, 0)..[0] = i;
      for (var j = 1; j <= b.length; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        current[j] = math.min(
          math.min(current[j - 1] + 1, previous[j] + 1),
          previous[j - 1] + cost,
        );
      }
      previous = current;
    }
    return previous[b.length];
  }

  /// Lowercase words (Latin or Arabic) with strengths removed, OCR digit
  /// look-alikes fixed inside words, and form words and numbers dropped.
  static List<String> _words(String text) {
    return text
        .toLowerCase()
        // Drop strengths ("500mg", "1 g") first so the digit fixes below
        // don't turn "500mg" into "50omg".
        .replaceAll(RegExp(r'\d+(\.\d+)?\s*(mg|mcg|ml|g|iu|units?)\b'), ' ')
        .replaceAllMapped(RegExp(r'(?<=[a-z])0|0(?=[a-z])'), (_) => 'o')
        .replaceAllMapped(RegExp(r'(?<=[a-z])1(?=[a-z])'), (_) => 'l')
        .split(RegExp(r'[^a-z0-9؀-ۿ]+'))
        .where(
          (w) =>
              w.isNotEmpty &&
              !_noise.contains(w) &&
              !RegExp(r'^\d+$').hasMatch(w),
        )
        .toList();
  }

  static String _digits(String text) => text.replaceAll(RegExp(r'[^0-9]'), '');
}
