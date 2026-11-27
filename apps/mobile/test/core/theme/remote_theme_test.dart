import 'package:flutter_test/flutter_test.dart';
import 'package:madar_al_huda/core/theme/app_theme.dart';
import 'package:madar_al_huda/core/theme/brand_colors.dart';
import 'package:madar_al_huda/core/theme/brand_palette.dart';
import 'package:madar_al_huda/core/theme/brand_season.dart';
import 'package:madar_al_huda/core/theme/remote_theme.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/pump_app.dart';

Map<String, Object?> feed(Map<String, Object?> theme) => {
  'version': 1,
  'appearance': {'theme': theme},
};

const ramadan = {
  'preset': 'ramadan',
  'primary': '#1E2A4A',
  'gold': '#C9A24A',
  'background': '#F7F1E3',
  'ink': '#1A1F33',
  'radius': 24,
  'textScale': 110,
  'ramadanAuto': false,
};

void main() {
  test('reads a published theme', () {
    final theme = RemoteTheme.fromFeed(feed(ramadan))!;
    expect(theme.primary, const Color(0xFF1E2A4A));
    expect(theme.radius, 24);
    expect(theme.textScale, closeTo(1.1, 1e-9));
  });

  test('ignores missing, malformed and unreadable themes', () {
    expect(RemoteTheme.fromFeed(null), isNull);
    expect(RemoteTheme.fromFeed({'version': 1}), isNull);
    expect(RemoteTheme.fromFeed(feed({...ramadan, 'primary': 'navy'})), isNull);
    expect(RemoteTheme.fromFeed(feed({...ramadan, 'radius': 80})), isNull);
    // Light grey text on white fails the 4.5:1 check the dashboard enforces.
    expect(
      RemoteTheme.fromFeed(
        feed({...ramadan, 'ink': '#CCCCCC', 'background': '#FFFFFF'}),
      ),
      isNull,
    );
  });

  test('brand colours keep the hand-tuned schemes', () {
    final brand = RemoteTheme.fromFeed(
      feed({
        ...ramadan,
        'primary': '#0F4A43',
        'gold': '#B8893A',
        'background': '#F5F0E6',
        'ink': '#12332F',
      }),
    )!;
    expect(AppTheme.light(remote: brand).colorScheme, AppTheme.lightScheme);
    expect(AppTheme.dark(remote: brand).colorScheme, AppTheme.darkScheme);
  });

  test('a custom theme stays readable in light and dark', () {
    final theme = RemoteTheme.fromFeed(feed(ramadan))!;
    final light = AppTheme.light(remote: theme).colorScheme;
    expect(light.primary, theme.primary);
    expect(light.surface, theme.background);
    expect(contrastRatio(light.onSurface, light.surface), greaterThan(4.5));
    expect(contrastRatio(light.secondary, light.surface), greaterThan(4.5));
    expect(
      contrastRatio(light.onSurfaceVariant, light.surface),
      greaterThan(4.5),
    );
    final dark = AppTheme.dark(remote: theme).colorScheme;
    expect(dark.surface, AppTheme.darkScheme.surface);
    expect(contrastRatio(dark.primary, dark.surface), greaterThan(4.5));
    expect(contrastRatio(dark.secondary, dark.surface), greaterThan(4.5));
  });

  test('published profiles are readable and apply to the matching season and mode', () {
    final profiles = {
      for (final entry in BrandColors.palettes.entries)
        entry.key: {
          for (final role in entry.value.entries)
            role.key: role.value.a == 1
                ? '#${(role.value.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}'
                : '#${role.value.toARGB32().toRadixString(16).padLeft(8, '0')}',
        },
    };
    profiles['eid-dark']!['heroStart'] = '#214232';
    profiles['eid-dark']!['surface'] = '#121714';
    final appearance = {
      'theme': ramadan,
      'palettes': {'version': 1, 'profiles': profiles},
    };
    final remote = RemoteTheme.fromFeed({'appearance': appearance});
    expect(remote?.palettes.length, 6);
    for (final season in BrandSeason.values) {
      for (final dark in [false, true]) {
        final theme = dark
            ? AppTheme.dark(season: season, remote: remote)
            : AppTheme.light(season: season, remote: remote);
        final profile = remote!.palettes[season.profile(dark: dark)]!;
        expect(theme.colorScheme, profile.scheme);
        expect(
          theme.extension<BrandChrome>()?.heroStart,
          profile.chrome.heroStart,
        );
      }
    }
    final eidDark = AppTheme.dark(season: BrandSeason.eid, remote: remote);
    expect(eidDark.colorScheme.surface, const Color(0xFF121714));
    expect(
      eidDark.extension<BrandChrome>()?.heroStart,
      const Color(0xFF214232),
    );
    profiles['eid-dark']!['onSurface'] = '#121714';
    expect(RemoteTheme.fromFeed({'appearance': appearance}), isNull);
  });

  testWidgets('the app applies the published colours and text size', (
    tester,
  ) async {
    await pumpMadarApp(
      tester,
      additionalOverrides: [
        remoteThemeProvider.overrideWithValue(
          RemoteTheme.fromFeed(feed(ramadan)),
        ),
      ],
    );
    final context = tester.element(find.byType(Scaffold).first);
    expect(Theme.of(context).colorScheme.primary, const Color(0xFF1E2A4A));
    expect(MediaQuery.textScalerOf(context).scale(10), closeTo(11, 0.01));
  });
}
