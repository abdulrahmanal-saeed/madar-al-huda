import 'package:intl/intl.dart';

/// The locale used for numbers: Arabic text shows Arabic-Indic digits
/// (٠١٢…), matching the dates and times, instead of intl's default Latin
/// digits for plain `ar`.
String numberLocale(String language) =>
    language == 'ar' || language.startsWith('ar-') || language.startsWith('ar_')
    ? 'ar_EG'
    : language;

/// Grouped decimal numbers in the app's language.
NumberFormat decimalFormat(String language) =>
    NumberFormat.decimalPattern(numberLocale(language));

/// Replaces Latin digits in [text] with Arabic-Indic ones for Arabic.
String localizedDigits(String text, String language) =>
    numberLocale(language) == 'ar_EG'
    ? text.replaceAllMapped(
        RegExp('[0-9]'),
        (match) => '٠١٢٣٤٥٦٧٨٩'[int.parse(match[0]!)],
      )
    : text;
