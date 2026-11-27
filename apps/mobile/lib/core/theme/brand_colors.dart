import 'package:material_ui/material_ui.dart';

import 'brand_season.dart';

/// Brand palette from `docs/BRAND.md`.
///
/// P00-03 selected creative direction; owner aesthetic and trademark signoff remain pending.
/// Gold is an accent colour: it does not reach text contrast on ivory, so it
/// must never be used for body text on light surfaces (see contrast tests).
abstract final class BrandColors {
  static const Color primaryGreen = Color(0xFF0F4A43);
  static const Color mutedGold = Color(0xFFB8893A);
  static const Color ivory = Color(0xFFF5F0E6);
  static const Color darkInk = Color(0xFF12332F);

  // Derived tones (light scheme).
  static const Color paper = Color(0xFFFFFDF8);
  static const Color sand = Color(0xFFEEE7D9);
  static const Color sandDeep = Color(0xFFE9E2D1);
  static const Color line = Color(0xFFE4DCCB);
  static const Color greenMist = Color(0xFFE3EDE8);
  static const Color goldMist = Color(0xFFF1E5C9);
  static const Color goldDeep = Color(0xFF6E5420);

  /// Lightest tone of the Home hero gradient. Hero text (ivory, bright gold)
  /// is contrast-tested against it.
  static const Color heroGreenEnd = Color(0xFF0C2B27);

  // Derived tones (dark scheme).
  static const Color night = Color(0xFF0D1917);
  static const Color nightRaised = Color(0xFF13221F);
  static const Color nightHigh = Color(0xFF1A2C28);
  static const Color nightHighest = Color(0xFF223631);
  static const Color nightLine = Color(0xFF34473F);
  static const Color greenGlow = Color(0xFF9CCFC1);
  static const Color goldBright = Color(0xFFD9BE85);
  static const Color ivoryDim = Color(0xFFECE6D8);

  static const ColorScheme lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFFC43F23),
    onPrimary: Colors.white,
    primaryContainer: Color(0xFFE7E1F6),
    onPrimaryContainer: Color(0xFF1B1530),
    secondary: Color(0xFF6242CD),
    onSecondary: Colors.white,
    secondaryContainer: Color(0xFFF7D8CF),
    onSecondaryContainer: Color(0xFF552417),
    tertiary: Color(0xFF47339B),
    onTertiary: Colors.white,
    tertiaryContainer: Color(0xFFE7E1F6),
    onTertiaryContainer: Color(0xFF211851),
    error: Color(0xFFB3261E),
    onError: Colors.white,
    errorContainer: Color(0xFFF9DEDC),
    onErrorContainer: Color(0xFF410E0B),
    surface: Color(0xFFF3F0FA),
    onSurface: Color(0xFF1B1530),
    onSurfaceVariant: Color(0xFF716A8A),
    surfaceDim: Color(0xFFE7E1F6),
    surfaceBright: Colors.white,
    surfaceContainerLowest: Colors.white,
    surfaceContainerLow: Colors.white,
    surfaceContainer: Color(0xFFEEE9F9),
    surfaceContainerHigh: Color(0xFFE7E1F6),
    surfaceContainerHighest: Color(0xFFE1D9F3),
    outline: Color(0xFF807798),
    outlineVariant: Color(0x141B1530),
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: Color(0xFF1B1530),
    onInverseSurface: Color(0xFFF3F0FA),
    inversePrimary: Color(0xFFFF7A59),
    surfaceTint: Colors.transparent,
  );

  static const ColorScheme darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFFFF7A59),
    onPrimary: Color(0xFF1A0E0A),
    primaryContainer: Color(0xFF292143),
    onPrimaryContainer: Color(0xFFF3ECFA),
    secondary: Color(0xFFB7A4FF),
    onSecondary: Color(0xFF211851),
    secondaryContainer: Color(0xFF382B64),
    onSecondaryContainer: Color(0xFFE9DFFF),
    tertiary: Color(0xFFFFA28C),
    onTertiary: Color(0xFF38150C),
    tertiaryContainer: Color(0xFF49251E),
    onTertiaryContainer: Color(0xFFFFDACE),
    error: Color(0xFFF2B8B5),
    onError: Color(0xFF601410),
    errorContainer: Color(0xFF8C1D18),
    onErrorContainer: Color(0xFFF9DEDC),
    surface: Color(0xFF120E1C),
    onSurface: Color(0xFFF3ECFA),
    onSurfaceVariant: Color(0xFF9C92B8),
    surfaceDim: Color(0xFF120E1C),
    surfaceBright: Color(0xFF332852),
    surfaceContainerLowest: Color(0xFF100C18),
    surfaceContainerLow: Color(0xFF1D1730),
    surfaceContainer: Color(0xFF211A37),
    surfaceContainerHigh: Color(0xFF292143),
    surfaceContainerHighest: Color(0xFF332852),
    outline: Color(0xFF8B7EA8),
    outlineVariant: Color(0x14FFFFFF),
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: Color(0xFFF3ECFA),
    onInverseSurface: Color(0xFF120E1C),
    inversePrimary: Color(0xFFC43F23),
    surfaceTint: Colors.transparent,
  );

  /// Foundation colours for the seasonal application themes and splash.
  static (int, int, int, int, int, int, int, int) seasonal(
    BrandSeason season, {
    required bool dark,
  }) => switch ((season, dark)) {
    (BrandSeason.ramadan, false) => (
      0xFFFBF5E6,
      0xFFFFFFFF,
      0xFFF1E6C8,
      0xFF10283A,
      0xFF6B7480,
      0xFF9A5D07,
      0xFFFFFFFF,
      0xFF0C7161,
    ),
    (BrandSeason.ramadan, true) => (
      0xFF0C1626,
      0xFF14233A,
      0xFF1D3150,
      0xFFF6EFDC,
      0xFF93A3BC,
      0xFFF2B84B,
      0xFF2A1A00,
      0xFF5FD3B8,
    ),
    (BrandSeason.eid, false) => (
      0xFFF1FAF5,
      0xFFFFFFFF,
      0xFFDDF1E7,
      0xFF0C3326,
      0xFF5C7C70,
      0xFFC3255C,
      0xFFFFFFFF,
      0xFF08774F,
    ),
    (BrandSeason.eid, true) => (
      0xFF0B1B17,
      0xFF122A24,
      0xFF1B3D34,
      0xFFF2FBF6,
      0xFF8FB3A6,
      0xFFFF6B9A,
      0xFF2A0714,
      0xFF3EE0A8,
    ),
    (BrandSeason.regular, _) => throw StateError('Expected a seasonal theme'),
  };

  static Color splash(BrandSeason season, {required bool dark}) =>
      season == BrandSeason.regular
      ? (dark ? const Color(0xFF151220) : const Color(0xFFEDEAF6))
      : Color(seasonal(season, dark: dark).$1);

  static List<Color> readingHero(BrandSeason season) => switch (season) {
    BrandSeason.regular => const [Color(0xFF3A2A99), Color(0xFF1F1558)],
    BrandSeason.ramadan => const [Color(0xFF14606B), Color(0xFF0A2230)],
    BrandSeason.eid => const [Color(0xFF0E8A62), Color(0xFF063D2C)],
  };

  static List<Color> beadShades(Color base) => [
    Color.lerp(base, Colors.white, .72)!,
    base,
    Color.lerp(base, Colors.black, .35)!,
  ];

  static const lightReadingPaper = (
    paper: Color(0xfffaf7ff),
    ink: Color(0xff1b1530),
    border: Color(0xffe4def3),
    banner: Color(0xffeee9f8),
  );

  static const warmReadingPaper = (
    paper: Color(0xfff3e7cf),
    ink: Color(0xff3a2a12),
    border: Color(0xffd9c79f),
    banner: Color(0xffeadbbb),
  );

  static const nightReadingPaper = (
    paper: Color(0xff0d1917),
    ink: Color(0xffece6d8),
    border: Color(0xff34473f),
    banner: Color(0xff223631),
  );

  static const amberReadingPaper = (
    paper: Color(0xff1d1711),
    ink: Color(0xffe9d3a6),
    border: Color(0xff4a3a26),
    banner: Color(0xff2c2218),
  );
}
