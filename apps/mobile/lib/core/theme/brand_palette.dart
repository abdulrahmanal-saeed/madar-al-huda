import 'package:material_ui/material_ui.dart';

class BrandPalette {
  const BrandPalette({required this.scheme, required this.chrome});

  final ColorScheme scheme;
  final BrandChrome chrome;
}

/// Brand colours used outside the Material component roles.
class BrandChrome extends ThemeExtension<BrandChrome> {
  const BrandChrome({
    required this.heroStart,
    required this.heroEnd,
    required this.heroInk,
    required this.splash,
  });

  final Color heroStart;
  final Color heroEnd;
  final Color heroInk;
  final Color splash;

  @override
  BrandChrome copyWith({
    Color? heroStart,
    Color? heroEnd,
    Color? heroInk,
    Color? splash,
  }) => BrandChrome(
    heroStart: heroStart ?? this.heroStart,
    heroEnd: heroEnd ?? this.heroEnd,
    heroInk: heroInk ?? this.heroInk,
    splash: splash ?? this.splash,
  );

  @override
  BrandChrome lerp(covariant BrandChrome? other, double t) => other == null
      ? this
      : BrandChrome(
          heroStart: Color.lerp(heroStart, other.heroStart, t)!,
          heroEnd: Color.lerp(heroEnd, other.heroEnd, t)!,
          heroInk: Color.lerp(heroInk, other.heroInk, t)!,
          splash: Color.lerp(splash, other.splash, t)!,
        );
}
