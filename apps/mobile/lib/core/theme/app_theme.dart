import 'dart:ui' show FontVariation;

import 'package:material_ui/material_ui.dart';

import 'app_tokens.dart';
import 'brand_colors.dart';

/// Builds the Madar Al-Huda light and dark themes.
abstract final class AppTheme {
  /// Bundled UI font (Arabic + Latin). See pubspec.yaml for licensing.
  static const String fontFamily = 'IBMPlexSansArabic';
  static const String headingFontFamily = 'ReemKufi';
  static const String quranFontFamily = 'AmiriQuran';
  static const String readingFontFamily = 'Amiri';

  static TextStyle headingStyle(FontWeight weight) => TextStyle(
    fontFamily: headingFontFamily,
    fontFamilyFallback: const [fontFamily],
    fontWeight: weight,
    fontVariations: [FontVariation.weight(weight.value.toDouble())],
  );

  static const ColorScheme lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: BrandColors.primaryGreen,
    onPrimary: BrandColors.ivory,
    primaryContainer: BrandColors.greenMist,
    onPrimaryContainer: BrandColors.primaryGreen,
    secondary: BrandColors.goldDeep,
    onSecondary: Colors.white,
    secondaryContainer: BrandColors.goldMist,
    onSecondaryContainer: Color(0xFF3D2E0F),
    tertiary: Color(0xFF3E6B62),
    onTertiary: Colors.white,
    tertiaryContainer: Color(0xFFCDE6DF),
    onTertiaryContainer: Color(0xFF0F2C26),
    error: Color(0xFFB3261E),
    onError: Colors.white,
    errorContainer: Color(0xFFF9DEDC),
    onErrorContainer: Color(0xFF410E0B),
    surface: BrandColors.ivory,
    onSurface: Color(0xFF1B2826),
    onSurfaceVariant: Color(0xFF4A5753),
    surfaceDim: BrandColors.sandDeep,
    surfaceBright: BrandColors.paper,
    surfaceContainerLowest: Colors.white,
    surfaceContainerLow: BrandColors.paper,
    surfaceContainer: BrandColors.sand,
    surfaceContainerHigh: BrandColors.sandDeep,
    surfaceContainerHighest: Color(0xFFE2DAC7),
    outline: Color(0xFF6F7B76),
    outlineVariant: BrandColors.line,
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: BrandColors.darkInk,
    onInverseSurface: BrandColors.ivory,
    inversePrimary: BrandColors.greenGlow,
    surfaceTint: Colors.transparent,
  );

  static const ColorScheme darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: BrandColors.greenGlow,
    onPrimary: Color(0xFF07231D),
    primaryContainer: BrandColors.primaryGreen,
    onPrimaryContainer: Color(0xFFDDF0EA),
    secondary: BrandColors.goldBright,
    onSecondary: Color(0xFF2B210B),
    secondaryContainer: Color(0xFF4A3B1C),
    onSecondaryContainer: Color(0xFFF4E6C6),
    tertiary: Color(0xFFA8CFC5),
    onTertiary: Color(0xFF0E2B25),
    tertiaryContainer: Color(0xFF26453E),
    onTertiaryContainer: Color(0xFFD3EBE4),
    error: Color(0xFFF2B8B5),
    onError: Color(0xFF601410),
    errorContainer: Color(0xFF8C1D18),
    onErrorContainer: Color(0xFFF9DEDC),
    surface: BrandColors.night,
    onSurface: BrandColors.ivoryDim,
    onSurfaceVariant: Color(0xFFB9C4BF),
    surfaceDim: BrandColors.night,
    surfaceBright: Color(0xFF2B403A),
    surfaceContainerLowest: Color(0xFF09120F),
    surfaceContainerLow: BrandColors.nightRaised,
    surfaceContainer: BrandColors.nightRaised,
    surfaceContainerHigh: BrandColors.nightHigh,
    surfaceContainerHighest: BrandColors.nightHighest,
    outline: Color(0xFF85948E),
    outlineVariant: BrandColors.nightLine,
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: BrandColors.ivoryDim,
    onInverseSurface: BrandColors.darkInk,
    inversePrimary: BrandColors.primaryGreen,
    surfaceTint: Colors.transparent,
  );

  static ThemeData light({bool reduceMotion = false}) =>
      _build(lightScheme, reduceMotion: reduceMotion);

  static ThemeData dark({bool reduceMotion = false}) =>
      _build(darkScheme, reduceMotion: reduceMotion);

  static ThemeData _build(ColorScheme scheme, {required bool reduceMotion}) {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: fontFamily,
      scaffoldBackgroundColor: scheme.surface,
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
    );
    // ThemeData().textTheme has colours but no sizes (geometry is applied
    // later by Theme.of), so start from the M3 geometry to give component
    // styles derived below (app bar, nav labels, chips) real font sizes.
    final text = _textTheme(
      Typography.englishLike2021.merge(base.textTheme),
      scheme,
    );

    return base.copyWith(
      textTheme: text,
      pageTransitionsTheme: reduceMotion
          ? const PageTransitionsTheme(
              builders: {
                TargetPlatform.android: _NoTransitionsBuilder(),
                TargetPlatform.iOS: _NoTransitionsBuilder(),
                TargetPlatform.linux: _NoTransitionsBuilder(),
                TargetPlatform.macOS: _NoTransitionsBuilder(),
                TargetPlatform.windows: _NoTransitionsBuilder(),
                TargetPlatform.fuchsia: _NoTransitionsBuilder(),
              },
            )
          : base.pageTransitionsTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        titleTextStyle: text.titleLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.lgAll,
          side: BorderSide(color: scheme.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.primaryContainer,
        elevation: 0,
        height: 72,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => text.labelMedium?.copyWith(
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.w400,
            color: states.contains(WidgetState.selected)
                ? scheme.onSurface
                : scheme.onSurfaceVariant,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? scheme.onPrimaryContainer
                : scheme.onSurfaceVariant,
          ),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        indicatorColor: scheme.primaryContainer,
        selectedIconTheme: IconThemeData(color: scheme.onPrimaryContainer),
        unselectedIconTheme: IconThemeData(color: scheme.onSurfaceVariant),
        selectedLabelTextStyle: text.labelMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
        ),
        unselectedLabelTextStyle: text.labelMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.lg,
        ),
        iconColor: scheme.onSurfaceVariant,
        titleTextStyle: text.bodyLarge?.copyWith(color: scheme.onSurface),
        subtitleTextStyle: text.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      chipTheme: ChipThemeData(
        side: BorderSide.none,
        shape: const StadiumBorder(),
        labelStyle: text.labelSmall?.copyWith(fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          textStyle: WidgetStatePropertyAll(text.labelLarge),
          visualDensity: VisualDensity.standard,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: text.bodyMedium?.copyWith(
          color: scheme.onInverseSurface,
        ),
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.mdAll),
      ),
    );
  }

  /// Slightly more generous line heights than the Material defaults: Arabic
  /// script with diacritics needs vertical room, and it reads calmer in Latin.
  static TextTheme _textTheme(TextTheme base, ColorScheme scheme) {
    TextStyle? tune(TextStyle? s, {double? height, FontWeight? weight}) =>
        s?.copyWith(
          height: height,
          fontWeight: weight,
          color: scheme.onSurface,
          fontFamily: fontFamily,
        );
    TextStyle? heading(
      TextStyle? style,
      double height, [
      FontWeight weight = FontWeight.w600,
    ]) => tune(style, height: height)?.merge(headingStyle(weight));

    return base.copyWith(
      displayLarge: heading(base.displayLarge, 1.25),
      displayMedium: heading(base.displayMedium, 1.25),
      displaySmall: heading(base.displaySmall, 1.3),
      headlineLarge: heading(base.headlineLarge, 1.3),
      headlineMedium: heading(base.headlineMedium, 1.35),
      headlineSmall: heading(base.headlineSmall, 1.4),
      titleLarge: heading(base.titleLarge, 1.4),
      titleMedium: heading(base.titleMedium, 1.45),
      titleSmall: heading(base.titleSmall, 1.45, FontWeight.w500),
      bodyLarge: tune(base.bodyLarge, height: 1.6),
      bodyMedium: tune(base.bodyMedium, height: 1.6),
      bodySmall: tune(base.bodySmall, height: 1.55),
      labelLarge: tune(base.labelLarge, height: 1.4, weight: FontWeight.w500),
      labelMedium: tune(base.labelMedium, height: 1.4),
      labelSmall: tune(base.labelSmall, height: 1.4),
    );
  }
}

/// Used when the user enables "Reduce motion".
class _NoTransitionsBuilder extends PageTransitionsBuilder {
  const _NoTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => child;
}
