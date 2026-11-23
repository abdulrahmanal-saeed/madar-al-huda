import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../content/managed_library.dart';
import '../localization/civil_hijri_date.dart';
import 'brand_colors.dart';

/// Colours, corner radius and text size published from the dashboard's
/// «الثيم والألوان» page. The app only applies a theme that passes the same
/// readability checks the dashboard enforces; anything else keeps the brand.
class RemoteTheme {
  const RemoteTheme({
    required this.primary,
    required this.gold,
    required this.background,
    required this.ink,
    this.radius = 16,
    this.textScale = 1,
    this.ramadanAuto = false,
  });

  /// Reads `appearance.theme` from the library feed; null when missing,
  /// malformed or hard to read.
  static RemoteTheme? fromFeed(Map<String, Object?>? feed) {
    final appearance = feed?['appearance'];
    final data = appearance is Map ? appearance['theme'] : null;
    if (data is! Map) return null;
    final primary = _color(data['primary']);
    final gold = _color(data['gold']);
    final background = _color(data['background']);
    final ink = _color(data['ink']);
    final radius = data['radius'];
    final scale = data['textScale'];
    if (primary == null ||
        gold == null ||
        background == null ||
        ink == null ||
        radius is! int ||
        radius < 4 ||
        radius > 32 ||
        scale is! int ||
        scale < 90 ||
        scale > 125) {
      return null;
    }
    final theme = RemoteTheme(
      primary: primary,
      gold: gold,
      background: background,
      ink: ink,
      radius: radius.toDouble(),
      textScale: scale / 100,
      ramadanAuto: data['ramadanAuto'] == true,
    );
    return theme.readable ? theme : null;
  }

  /// The Ramadan preset, used when [ramadanAuto] is on during Ramadan.
  static const ramadan = RemoteTheme(
    primary: Color(0xFF1E2A4A),
    gold: Color(0xFFC9A24A),
    background: Color(0xFFF7F1E3),
    ink: Color(0xFF1A1F33),
  );

  final Color primary;
  final Color gold;
  final Color background;
  final Color ink;
  final double radius;
  final double textScale;
  final bool ramadanAuto;

  /// WCAG AA (4.5:1) for text, buttons and the primary colour.
  bool get readable =>
      contrastRatio(ink, background) >= 4.5 &&
      contrastRatio(BrandColors.paper, primary) >= 4.5 &&
      contrastRatio(primary, background) >= 4.5;

  /// This theme with the Ramadan colours, keeping radius and text size.
  RemoteTheme withColorsOf(RemoteTheme other) => RemoteTheme(
    primary: other.primary,
    gold: other.gold,
    background: other.background,
    ink: other.ink,
    radius: radius,
    textScale: textScale,
    ramadanAuto: ramadanAuto,
  );

  static Color? _color(Object? value) {
    if (value is! String || !RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(value)) {
      return null;
    }
    return Color(0xFF000000 | int.parse(value.substring(1), radix: 16));
  }
}

double contrastRatio(Color a, Color b) {
  final first = a.computeLuminance();
  final second = b.computeLuminance();
  return (math.max(first, second) + 0.05) / (math.min(first, second) + 0.05);
}

/// The theme to apply now, or null for the built-in brand theme.
final remoteThemeProvider = Provider<RemoteTheme?>((ref) {
  final feed = ref.watch(managedLibraryProvider).asData?.value;
  final theme = RemoteTheme.fromFeed(feed);
  if (theme == null) return null;
  if (theme.ramadanAuto && civilHijri(DateTime.now())?.month == 9) {
    return theme.withColorsOf(RemoteTheme.ramadan);
  }
  return theme;
});
