import 'package:flutter_test/flutter_test.dart';
import 'package:madar_al_huda/app/deep_links.dart';
import 'package:madar_al_huda/core/routing/app_routes.dart';

void main() {
  test('app links map to in-app routes; others are ignored', () {
    expect(
      routeForLink(
        Uri.parse(
          'https://quran.abdulrahmanalsaeed.com/app/quran?surah=2&ayah=255',
        ),
      ),
      '/quran?surah=2&ayah=255',
    );
    expect(
      routeForLink(Uri.parse('https://quran.abdulrahmanalsaeed.com/app/')),
      AppRoutes.home,
    );
    expect(
      routeForLink(
        Uri.parse('https://quran.abdulrahmanalsaeed.com/app/library/names'),
      ),
      AppRoutes.names,
    );
    // Other hosts, schemes, paths and screens stay out.
    expect(routeForLink(Uri.parse('https://example.com/app/quran')), isNull);
    expect(
      routeForLink(Uri.parse('http://quran.abdulrahmanalsaeed.com/app/quran')),
      isNull,
    );
    expect(
      routeForLink(Uri.parse('https://quran.abdulrahmanalsaeed.com/admin/')),
      isNull,
    );
    expect(
      routeForLink(
        Uri.parse('https://quran.abdulrahmanalsaeed.com/app/settings'),
      ),
      isNull,
    );
    expect(
      routeForLink(Uri.parse('madar-al-huda://auth/callback?code=x')),
      isNull,
    );
  });

  test('shared links round-trip', () {
    final link = appLinkFor(AppRoutes.verse(2, 255));
    expect(
      link.toString(),
      'https://quran.abdulrahmanalsaeed.com/app/quran?surah=2&ayah=255',
    );
    expect(routeForLink(link), AppRoutes.verse(2, 255));
  });
}
