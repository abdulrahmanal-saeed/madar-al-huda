import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:madar_al_huda/core/theme/app_theme.dart';
import 'package:madar_al_huda/core/theme/brand_colors.dart';
import 'package:material_ui/material_ui.dart';

/// WCAG 2.x relative luminance contrast ratio.
double contrast(Color a, Color b) {
  double channel(double c) =>
      c <= 0.03928 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();
  double lum(Color c) =>
      0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b);
  final la = lum(a), lb = lum(b);
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void main() {
  test('brand colours match docs/BRAND.md', () {
    expect(BrandColors.primaryGreen, const Color(0xFF173F39));
    expect(BrandColors.mutedGold, const Color(0xFFC7A86D));
    expect(BrandColors.ivory, const Color(0xFFF8F5ED));
    expect(BrandColors.darkInk, const Color(0xFF263B38));
  });

  test('light scheme is built on the brand palette', () {
    const s = AppTheme.lightScheme;
    expect(s.primary, BrandColors.primaryGreen);
    expect(s.surface, BrandColors.ivory);
    expect(s.brightness, Brightness.light);
    expect(AppTheme.darkScheme.brightness, Brightness.dark);
  });

  for (final (name, s) in [
    ('light', AppTheme.lightScheme),
    ('dark', AppTheme.darkScheme),
  ]) {
    group('$name scheme meets WCAG AA (4.5:1) for text pairs', () {
      final pairs = <String, (Color, Color)>{
        'onSurface/surface': (s.onSurface, s.surface),
        'onSurface/surfaceContainerLow': (s.onSurface, s.surfaceContainerLow),
        'onSurface/surfaceContainerHighest': (
          s.onSurface,
          s.surfaceContainerHighest,
        ),
        'onSurfaceVariant/surface': (s.onSurfaceVariant, s.surface),
        'onSurfaceVariant/surfaceContainerLow': (
          s.onSurfaceVariant,
          s.surfaceContainerLow,
        ),
        'onPrimary/primary': (s.onPrimary, s.primary),
        'onPrimaryContainer/primaryContainer': (
          s.onPrimaryContainer,
          s.primaryContainer,
        ),
        'onSecondary/secondary': (s.onSecondary, s.secondary),
        'onSecondaryContainer/secondaryContainer': (
          s.onSecondaryContainer,
          s.secondaryContainer,
        ),
        'secondary/surface (group headers)': (s.secondary, s.surface),
        'primary/surface (links, buttons)': (s.primary, s.surface),
        'onError/error': (s.onError, s.error),
        'onInverseSurface/inverseSurface': (
          s.onInverseSurface,
          s.inverseSurface,
        ),
      };
      pairs.forEach((label, pair) {
        test(label, () {
          expect(
            contrast(pair.$1, pair.$2),
            greaterThanOrEqualTo(4.5),
            reason: '$label = ${contrast(pair.$1, pair.$2).toStringAsFixed(2)}',
          );
        });
      });
    });
  }

  test('Home hero text is readable on the lightest hero tone', () {
    for (final bg in [BrandColors.primaryGreen, BrandColors.heroGreenEnd]) {
      expect(contrast(BrandColors.ivory, bg), greaterThanOrEqualTo(4.5));
      expect(contrast(BrandColors.goldBright, bg), greaterThanOrEqualTo(4.5));
    }
  });

  test('muted gold is decorative only on ivory (documented limitation)', () {
    expect(
      contrast(BrandColors.mutedGold, BrandColors.ivory),
      lessThan(4.5),
      reason: 'If this starts passing, BRAND.md guidance can be relaxed.',
    );
  });

  test('themes use the bundled bilingual UI font', () {
    expect(
      AppTheme.light().textTheme.bodyMedium?.fontFamily,
      AppTheme.fontFamily,
    );
    expect(
      AppTheme.dark().textTheme.titleLarge?.fontFamily,
      AppTheme.headingFontFamily,
    );
    expect(
      AppTheme.dark().textTheme.labelMedium?.fontFamily,
      AppTheme.fontFamily,
    );
  });

  test('component text styles carry real font sizes', () {
    for (final theme in [AppTheme.light(), AppTheme.dark()]) {
      expect(theme.appBarTheme.titleTextStyle?.fontSize, 22);
      expect(theme.textTheme.bodyMedium?.fontSize, 14);
      expect(theme.textTheme.headlineMedium?.fontSize, 28);
      final label = theme.navigationBarTheme.labelTextStyle?.resolve({});
      expect(label?.fontSize, isNotNull);
    }
  });

  test('reduce motion removes page transitions', () {
    final normal = AppTheme.light().pageTransitionsTheme.builders;
    final reduced = AppTheme.light(reduceMotion: true)
        .pageTransitionsTheme
        .builders;
    expect(
      reduced[TargetPlatform.android].runtimeType,
      isNot(normal[TargetPlatform.android].runtimeType),
    );
    expect(reduced.keys, containsAll(TargetPlatform.values));
  });
}
