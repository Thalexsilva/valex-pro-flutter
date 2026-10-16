/// Only explicit load notation is numeric. A drop of 10–15%, an incline or
/// heart-rate percentage must never be interpreted as a fraction of the load.
double? prescriptionLoadPercentage(String text) {
  final match = RegExp(
    r'(?:@|\s[-–]\s+)\s*(\d+(?:[.,]\d+)?)\s*%(?!\s*(?:FC|VO|de inclina))',
    caseSensitive: false,
  ).firstMatch(text);
  return match == null
      ? null
      : double.tryParse(match.group(1)!.replaceAll(',', '.'));
}

String resolvePrescriptionLoad(
  String rawLoad,
  String explicitLoad,
  String description,
) {
  if (explicitLoad.isNotEmpty) return explicitLoad;
  final base = double.tryParse(
    rawLoad
        .trim()
        .replaceFirst(RegExp(r'\s*kg$', caseSensitive: false), '')
        .replaceAll(',', '.'),
  );
  if (base != null && base > 0) {
    final percentage = prescriptionLoadPercentage(description);
    if (percentage != null) return '≈ ${(base * percentage / 100).round()} kg';
    if (description.contains('%')) return '';
    return '${base.toStringAsFixed(base.truncateToDouble() == base ? 0 : 1)} kg';
  }
  return rawLoad == 'Definir kg' ? '' : rawLoad;
}
