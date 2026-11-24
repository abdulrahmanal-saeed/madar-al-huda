import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/content/app_settings.dart';

const cairoRadioMediaId = 'cairo-quran-radio-live';

/// The public live stream of the Holy Quran Radio from Cairo. The host
/// redirects to plain http, which Android allows for this domain only
/// (res/xml/network_security_config.xml).
final defaultCairoRadioStream = Uri.https(
  'stream.radiojar.com',
  '/8s5u5tpdtwzuv',
);

Uri? _safe(Uri? stream) =>
    stream == null ||
        stream.scheme != 'https' ||
        stream.host.isEmpty ||
        stream.userInfo.isNotEmpty
    ? null
    : stream;

/// The dashboard's stream first, then a build setting, then the default,
/// so the radio always plays inside the app.
final cairoRadioStreamProvider = Provider<Uri?>((ref) {
  const configured = String.fromEnvironment('MADAR_CAIRO_RADIO_URL');
  return ref.watch(appSettingsProvider).radioStream ??
      _safe(Uri.tryParse(configured.trim())) ??
      defaultCairoRadioStream;
});
