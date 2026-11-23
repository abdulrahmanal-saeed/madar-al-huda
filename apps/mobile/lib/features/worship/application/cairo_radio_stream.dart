import 'package:flutter_riverpod/flutter_riverpod.dart';

const cairoRadioMediaId = 'cairo-quran-radio-live';

final cairoRadioStreamProvider = Provider<Uri?>((ref) {
  const configured = String.fromEnvironment('MADAR_CAIRO_RADIO_URL');
  final stream = Uri.tryParse(configured.trim());
  if (stream == null ||
      stream.scheme != 'https' ||
      stream.host.isEmpty ||
      stream.userInfo.isNotEmpty) {
    return null;
  }
  return stream;
});
