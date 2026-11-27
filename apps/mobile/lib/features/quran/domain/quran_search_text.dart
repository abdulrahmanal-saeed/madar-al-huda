const _daggerAlef = '\u0670';
final _diacritics = RegExp(r'[\u0610-\u061a\u064b-\u065f\u06d6-\u06ed\u0640]');
final _alef = RegExp('[أإآٱ]');
final _digits = RegExp('[٠-٩۰-۹]');

/// Normalizes a query or a name. Display text stays intact.
String quranSearchText(String text) =>
    quranVerseSearchText(text).replaceAll(_daggerAlef, '').trim();

/// Keeps dagger alefs in indexed verses so either spelling can match.
String quranVerseSearchText(String text) => text
    .toLowerCase()
    .replaceAll(_diacritics, '')
    .replaceAll(_alef, 'ا')
    .replaceAllMapped(_digits, (match) {
      final digit = match[0]!.codeUnitAt(0);
      return (digit >= 0x6f0 ? digit - 0x6f0 : digit - 0x660).toString();
    })
    .trim();

/// Matches a normalized query against text from [quranVerseSearchText].
RegExp quranVerseSearchPattern(String query) {
  final letters = query.runes.map((rune) {
    final letter = String.fromCharCode(rune);
    return letter == 'ا' ? '[ا$_daggerAlef]' : RegExp.escape(letter);
  });
  // An indexed dagger alef can match a written alef or be skipped.
  return RegExp(letters.join('$_daggerAlef?'), unicode: true);
}
