/// Deriva a sigla curta do badge de um dia de treino (ex.: "Treino A" -> "A"),
/// espelhando a heurística usada na capa, índice e cabeçalho de cada dia.
String getDayBadgeText(String dow) {
  if (dow.isEmpty) return 'A';
  String clean = dow
      .replaceAll(RegExp(r'treino\s*', caseSensitive: false), '')
      .trim();
  if (clean.isEmpty) clean = dow.trim();
  if (clean.length > 3) {
    final match = RegExp(
      r'\b[A-Z0-9]{1,2}\b',
      caseSensitive: false,
    ).firstMatch(clean);
    if (match != null) return match.group(0)!.toUpperCase();
    return clean.substring(0, 2).toUpperCase();
  }
  return clean.toUpperCase();
}
