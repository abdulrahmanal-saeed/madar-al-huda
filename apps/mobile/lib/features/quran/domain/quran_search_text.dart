final _diacritics = RegExp(
  r'[\u0610-\u061a\u064b-\u065f\u0670\u06d6-\u06ed\u0640]',
);
final _alef = RegExp('[أإآٱ]');
final _digits = RegExp('[٠-٩۰-۹]');

/// Normalizes a search query or index entry. Display text stays intact.
String quranSearchText(String text) => text
    .toLowerCase()
    .replaceAll(_diacritics, '')
    .replaceAll(_alef, 'ا')
    .replaceAllMapped(_digits, (match) {
      final digit = match[0]!.codeUnitAt(0);
      return (digit >= 0x6f0 ? digit - 0x6f0 : digit - 0x660).toString();
    })
    .trim();
