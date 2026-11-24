/// Folds the spellings people type for the same words into one key, for
/// searching Arabic and Latin text alike.
library;

final _diacritics = RegExp('[ً-ْٰـ]');
const _latin = {
  'á': 'a', 'à': 'a', 'â': 'a', 'ä': 'a', 'ã': 'a', 'å': 'a', 'ā': 'a', //
  'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e', 'ē': 'e', //
  'í': 'i', 'ì': 'i', 'î': 'i', 'ï': 'i', 'ī': 'i', 'ı': 'i', //
  'ó': 'o', 'ò': 'o', 'ô': 'o', 'ö': 'o', 'õ': 'o', 'ø': 'o', 'ō': 'o', //
  'ú': 'u', 'ù': 'u', 'û': 'u', 'ü': 'u', 'ū': 'u', //
  'ç': 'c', 'ñ': 'n', 'ş': 's', 'ș': 's', 'ğ': 'g', 'ţ': 't', 'ț': 't',
};

/// Folds the spellings people type for the same place into one key.
String normalizeSearch(String text) {
  var value = text.trim().toLowerCase().replaceAll(_diacritics, '');
  value = value
      .replaceAll(RegExp('[أإآٱ]'), 'ا')
      .replaceAll('ة', 'ه')
      .replaceAll('ى', 'ي')
      .replaceAll('ؤ', 'و')
      .replaceAll('ئ', 'ي')
      .replaceAll(RegExp(r"[-'’.,]"), ' ')
      .replaceAll(RegExp(r'\s+'), ' ');
  final buffer = StringBuffer();
  for (final rune in value.runes) {
    final char = String.fromCharCode(rune);
    buffer.write(_latin[char] ?? char);
  }
  value = buffer.toString();
  // «القاهرة» and «قاهرة» are the same search.
  return value
      .split(' ')
      .map(
        (word) =>
            word.length > 3 && word.startsWith('ال') ? word.substring(2) : word,
      )
      .join(' ');
}
