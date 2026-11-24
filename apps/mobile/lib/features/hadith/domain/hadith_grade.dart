enum HadithGrade { authentic, good, other }

/// Reads the publisher's grade text, in Arabic or a translation.
HadithGrade hadithGrade(String grade) {
  final text = grade.toLowerCase();
  if (text.contains('صحيح') ||
      text.contains('authentic') ||
      text.contains('sahih')) {
    return HadithGrade.authentic;
  }
  if (text.contains('حسن') || text.contains('hasan') || text.contains('good')) {
    return HadithGrade.good;
  }
  return HadithGrade.other;
}
