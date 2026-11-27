import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../localization/civil_hijri_date.dart';

enum BrandSeason {
  regular,
  ramadan,
  eid;

  static BrandSeason on(DateTime date) => switch (civilHijri(date)) {
    (month: 9, day: _, year: _) => ramadan,
    (month: 10, day: 1, year: _) => eid,
    _ => regular,
  };

  String asset(String kind, {required bool dark}) {
    final prefix = this == regular ? '' : '$name-';
    return 'assets/brand/$prefix$kind-${dark ? 'dark' : 'light'}.png';
  }
}

final brandSeasonProvider = Provider<BrandSeason>((ref) {
  final now = DateTime.now();
  final tomorrow = DateTime(now.year, now.month, now.day + 1);
  final timer = Timer(tomorrow.difference(now), ref.invalidateSelf);
  final life = AppLifecycleListener(
    onResume: () {
      if (BrandSeason.on(DateTime.now()) != BrandSeason.on(now)) {
        ref.invalidateSelf();
      }
    },
  );
  ref.onDispose(timer.cancel);
  ref.onDispose(life.dispose);
  return BrandSeason.on(now);
});
