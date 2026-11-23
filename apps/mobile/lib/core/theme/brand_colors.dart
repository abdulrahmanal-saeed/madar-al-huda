import 'package:material_ui/material_ui.dart';

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
}
