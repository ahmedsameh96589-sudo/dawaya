/// A medicine line found in OCR text from a prescription photo.
class MedicineResult {
  final String name;
  final String? dose;
  final String? form;
  final String? frequency;
  final String rawLine;

  const MedicineResult({
    required this.name,
    this.dose,
    this.form,
    this.frequency,
    required this.rawLine,
  });
}

/// Pulls likely medicine lines out of recognized prescription text.
///
/// A line counts as a medicine when it mentions a dose ("500 mg"), a dosage
/// form ("tab", "syrup"), or — for lines longer than 8 characters — a
/// frequency ("twice daily", "bd").
class PrescriptionParser {
  PrescriptionParser._();

  static final RegExp _dosePattern =
      RegExp(r'\b\d+\s*(mg|mcg|ml|g|iu|unit|units)\b', caseSensitive: false);
  static final RegExp _freqPattern = RegExp(
      r'\b(once|twice|three times|daily|every|morning|night|bd|tds|qid|od|bid|prn|sos|stat)\b',
      caseSensitive: false);
  static final RegExp _formPattern = RegExp(
      r'\b(tab|tablet|cap|capsule|syrup|drops|injection|inj|cream|ointment|gel|patch|inhaler|spray|susp|suspension)\b',
      caseSensitive: false);

  static List<MedicineResult> extract(String text) {
    final results = <MedicineResult>[];

    for (final rawLine in text.split('\n')) {
      final line = rawLine.trim();
      if (line.length < 3) continue;

      final hasDose = _dosePattern.hasMatch(line);
      final hasFreq = _freqPattern.hasMatch(line);
      final hasForm = _formPattern.hasMatch(line);

      if (hasDose || hasForm || (hasFreq && line.length > 8)) {
        results.add(MedicineResult(
          name: cleanName(line),
          dose: _dosePattern.firstMatch(line)?.group(0),
          form: _formPattern.firstMatch(line)?.group(0),
          frequency: _freqPattern.firstMatch(line)?.group(0),
          rawLine: line,
        ));
      }
    }

    return results;
  }

  /// The leading capitalised word(s), e.g. "Panadol Extra 500mg" → "Panadol
  /// Extra"; otherwise everything before the first number.
  static String cleanName(String line) {
    final nameMatch =
        RegExp(r'^([A-Z][a-zA-Z]+(?:\s[A-Z][a-zA-Z]+)*)').firstMatch(line);
    return nameMatch?.group(0) ?? line.split(RegExp(r'\s+\d')).first.trim();
  }
}
