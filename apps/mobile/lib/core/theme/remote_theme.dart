import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../content/managed_library.dart';
import '../storage/storage_providers.dart';
import 'brand_colors.dart';
import 'brand_palette.dart';

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
    this.palettes = const {},
  });

  /// Reads `appearance.theme` from the library feed; null when missing,
  /// malformed or hard to read.
  static RemoteTheme? fromFeed(Map<String, Object?>? feed) {
    final appearance = feed?['appearance'];
    if (appearance is Map && appearance.containsKey('palettes')) {
      return _fromPalettes(appearance);
    }
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
    primary: BrandColors.legacyRamadanPrimary,
    gold: BrandColors.legacyRamadanGold,
    background: BrandColors.legacyRamadanBackground,
    ink: BrandColors.legacyRamadanInk,
  );

  final Color primary;
  final Color gold;
  final Color background;
  final Color ink;
  final double radius;
  final double textScale;
  final bool ramadanAuto;
  final Map<String, BrandPalette> palettes;

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

  static RemoteTheme? _fromPalettes(Map<Object?, Object?> appearance) {
    final payload = appearance['palettes'];
    if (payload is! Map || payload['version'] != 1) return null;
    final profiles = payload['profiles'];
    if (profiles is! Map) return null;
    final palettes = <String, BrandPalette>{};
    for (final profile in BrandColors.palettes.entries) {
      final values = profiles[profile.key];
      if (values is! Map) return null;
      final colors = <String, Color>{};
      for (final role in profile.value.keys) {
        final value = values[role];
        final alpha = switch (role) {
          'outlineVariant' || 'surfaceTint' => true,
          _ => false,
        };
        final color = _color(value, alpha: alpha);
        if (color == null) return null;
        colors[role] = color;
      }
      if (BrandColors.contrastPairs.any(
        (pair) => contrastRatio(colors[pair.$1]!, colors[pair.$2]!) < 4.5,
      )) {
        return null;
      }
      palettes[profile.key] = BrandColors.resolve(profile.key, colors);
    }
    final regular = palettes['regular-light']!.scheme;
    final settings = appearance['theme'];
    final radius = settings is Map ? settings['radius'] : null;
    final scale = settings is Map ? settings['textScale'] : null;
    return RemoteTheme(
      primary: regular.primary,
      gold: regular.secondary,
      background: regular.surface,
      ink: regular.onSurface,
      radius: radius is int && radius >= 4 && radius <= 32
          ? radius.toDouble()
          : 16,
      textScale: scale is int && scale >= 90 && scale <= 125 ? scale / 100 : 1,
      palettes: Map.unmodifiable(palettes),
    );
  }

  static final _rgb = RegExp(r'^#[0-9A-Fa-f]{6}$');
  static final _argb = RegExp(r'^#[0-9A-Fa-f]{8}$');

  static Color? _color(Object? value, {bool alpha = false}) {
    if (value is! String ||
        !(_rgb.hasMatch(value) || (alpha && _argb.hasMatch(value)))) {
      return null;
    }
    final rgb = int.parse(value.substring(1), radix: 16);
    return Color(value.length == 7 ? 0xFF000000 | rgb : rgb);
  }
}

double contrastRatio(Color a, Color b) {
  final first = a.computeLuminance();
  final second = b.computeLuminance();
  return (math.max(first, second) + 0.05) / (math.min(first, second) + 0.05);
}

/// A damaged or temporarily unavailable feed keeps the last readable palette.
final _remoteThemeState = NotifierProvider<RemoteThemeController, RemoteTheme?>(
  RemoteThemeController.new,
);

final remoteThemeProvider = Provider<RemoteTheme?>(
  (ref) => ref.watch(_remoteThemeState),
);

class RemoteThemeController extends Notifier<RemoteTheme?> {
  static const cacheKey = 'brand.palette.v1';

  @override
  RemoteTheme? build() {
    final store = ref.watch(keyValueStoreProvider);
    final cached = store.getString(cacheKey);
    RemoteTheme? previous;
    if (cached != null) {
      try {
        previous = RemoteTheme.fromFeed({'appearance': jsonDecode(cached)});
      } on FormatException {
        // The bundled palette is always available.
      }
    }

    ref.listen(managedLibraryProvider, (_, next) {
      final feed = next.asData?.value;
      if (feed == null) return;
      final parsed = RemoteTheme.fromFeed(feed);
      if (parsed != null || !_hasPalettes(feed)) {
        state = parsed;
      }
      if (parsed != null && parsed.palettes.isNotEmpty) {
        unawaited(
          store
              .setString(cacheKey, jsonEncode(feed['appearance']))
              .catchError((Object _) {}),
        );
      }
    });

    final current = ref.read(managedLibraryProvider).asData?.value;
    return RemoteTheme.fromFeed(current) ??
        (current == null || _hasPalettes(current) ? previous : null);
  }

  static bool _hasPalettes(Map<String, Object?> feed) {
    final appearance = feed['appearance'];
    return appearance is Map && appearance.containsKey('palettes');
  }
}
