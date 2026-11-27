import 'package:flutter_test/flutter_test.dart';
import 'package:madar_al_huda/core/theme/app_theme.dart';
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
