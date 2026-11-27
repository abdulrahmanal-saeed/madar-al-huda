import 'package:material_ui/material_ui.dart';

import 'app_tokens.dart';
import 'brand_colors.dart';
import 'brand_season.dart';
import 'remote_theme.dart';

/// Builds the Madar Al-Huda light and dark themes.
abstract final class AppTheme {
  /// Bundled UI font (Arabic + Latin). See pubspec.yaml for licensing.
  static const String fontFamily = 'NotoSansArabic';
  static const String headingFontFamily = 'NotoKufiArabic';
  static const String quranFontFamily = 'AmiriQuran';
  static const String readingFontFamily = 'NotoNaskhArabic';

  static TextStyle headingStyle(FontWeight weight) => TextStyle(
    fontFamily: headingFontFamily,
    fontFamilyFallback: const [fontFamily],
    fontWeight: weight,
    fontVariations: [FontVariation.weight(weight.value.toDouble())],
  );

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

  static ThemeData light({
    bool reduceMotion = false,
    RemoteTheme? remote,
    BrandSeason season = BrandSeason.regular,
  }) => _build(
    season != BrandSeason.regular
        ? _seasonal(lightScheme, season)
        : remote == null
        ? lightScheme
        : _remoteLight(remote),
    reduceMotion: reduceMotion,
    radius: remote?.radius,
  );

  static ThemeData dark({
    bool reduceMotion = false,
    RemoteTheme? remote,
    BrandSeason season = BrandSeason.regular,
  }) => _build(
    season != BrandSeason.regular
        ? _seasonal(darkScheme, season)
        : remote == null
        ? darkScheme
        : _remoteDark(remote),
    reduceMotion: reduceMotion,
    radius: remote?.radius,
  );

  static ColorScheme _seasonal(ColorScheme base, BrandSeason season) {
    final dark = base.brightness == Brightness.dark;
    final (
      bg,
      card,
      raised,
      ink,
      muted,
      accent,
      onAccent,
      secondary,
    ) = switch ((season, dark)) {
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
    return base.copyWith(
      primary: Color(accent),
      onPrimary: Color(onAccent),
      secondary: Color(secondary),
      onSecondary: Color(onAccent),
      primaryContainer: Color(raised),
      onPrimaryContainer: Color(ink),
      secondaryContainer: Color(raised),
      onSecondaryContainer: Color(ink),
      surface: Color(bg),
      onSurface: Color(ink),
      onSurfaceVariant: _readableOn(Color(muted), Color(bg), Color(ink), 4.5),
      surfaceDim: Color(bg),
      surfaceBright: Color(card),
      surfaceContainerLowest: Color(bg),
      surfaceContainerLow: Color(card),
      surfaceContainer: Color(card),
      surfaceContainerHigh: Color(raised),
      surfaceContainerHighest: Color(raised),
      inverseSurface: Color(ink),
      onInverseSurface: Color(bg),
      outlineVariant: Color(ink).withValues(alpha: .12),
    );
  }

  static bool _isBrand(RemoteTheme theme) =>
      theme.primary == BrandColors.primaryGreen &&
      theme.gold == BrandColors.mutedGold &&
      theme.background == BrandColors.ivory &&
      theme.ink == BrandColors.darkInk;

  /// Moves [color] toward [target] until it reaches [ratio] against [on].
  static Color _readableOn(Color color, Color on, Color target, double ratio) {
    var result = color;
    for (
      var step = 1;
      step <= 10 && contrastRatio(result, on) < ratio;
      step++
    ) {
      result = Color.lerp(color, target, step / 10)!;
    }
    return result;
  }

  /// The light scheme rebuilt around the dashboard's four colours; the
  /// hand-tuned brand scheme stays when the brand colours are published.
  static ColorScheme _remoteLight(RemoteTheme theme) {
    if (_isBrand(theme)) return lightScheme;
    final p = theme.primary;
    final bg = theme.background;
    final ink = theme.ink;
    final gold = theme.gold;
    Color mix(Color a, Color b, double t) => Color.lerp(a, b, t)!;
    final secondary = _readableOn(gold, bg, Colors.black, 4.5);
    return lightScheme.copyWith(
      primary: p,
      onPrimary: BrandColors.paper,
      primaryContainer: mix(p, bg, 0.86),
      onPrimaryContainer: _readableOn(p, mix(p, bg, 0.86), Colors.black, 4.5),
      secondary: secondary,
      secondaryContainer: mix(gold, bg, 0.78),
      onSecondaryContainer: _readableOn(
        mix(gold, Colors.black, 0.6),
        mix(gold, bg, 0.78),
        Colors.black,
        4.5,
      ),
      surface: bg,
      onSurface: ink,
      onSurfaceVariant: _readableOn(mix(ink, bg, 0.3), bg, ink, 4.5),
      surfaceDim: mix(bg, ink, 0.08),
      surfaceBright: mix(bg, Colors.white, 0.6),
      surfaceContainerLowest: Colors.white,
      surfaceContainerLow: mix(bg, Colors.white, 0.6),
      surfaceContainer: mix(bg, ink, 0.04),
      surfaceContainerHigh: mix(bg, ink, 0.07),
      surfaceContainerHighest: mix(bg, ink, 0.1),
      outline: _readableOn(mix(ink, bg, 0.45), bg, ink, 3),
      outlineVariant: mix(bg, ink, 0.12),
      inverseSurface: ink,
      onInverseSurface: bg,
    );
  }

  /// Dark mode keeps its night palette and takes only the accent colours.
  static ColorScheme _remoteDark(RemoteTheme theme) {
    if (_isBrand(theme)) return darkScheme;
    final surface = darkScheme.surface;
    return darkScheme.copyWith(
      primary: _readableOn(theme.primary, surface, Colors.white, 4.5),
      secondary: _readableOn(theme.gold, surface, Colors.white, 4.5),
    );
  }

  static ThemeData _build(
    ColorScheme scheme, {
    required bool reduceMotion,
    double? radius,
  }) {
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
        titleTextStyle: text.headlineSmall?.copyWith(
          fontWeight: FontWeight.w800,
        ),
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: radius == null
              ? const BorderRadiusDirectional.only(
                  topStart: Radius.circular(18),
                  topEnd: Radius.circular(18),
                  bottomStart: Radius.circular(18),
                  bottomEnd: Radius.circular(5),
                )
              : BorderRadius.circular(radius),
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
