import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'hosted_feed.dart';

final libraryFeedUrl = Uri.https('quran.abdulrahmanalsaeed.com', '/admin/', {
  'feed': 'library',
});

/// The published library feed, fetched once and shared by every screen that
/// reads it (adhkar, duas, reciters, fiqh, articles and lessons).
///
/// It is refreshed when the app returns to the foreground and every
/// [_refreshEvery] while it stays open, instead of polling on a short timer.
/// The request carries the saved ETag, so an unchanged feed costs a 304.
final managedLibraryProvider =
    FutureProvider.autoDispose<Map<String, Object?>?>((ref) {
      final loadedAt = DateTime.now();
      final timer = Timer(_refreshEvery, ref.invalidateSelf);
      ref.onDispose(timer.cancel);
      final lifecycle = AppLifecycleListener(
        onResume: () {
          if (DateTime.now().difference(loadedAt) >= _minResumeGap) {
            ref.invalidateSelf();
          }
        },
      );
      ref.onDispose(lifecycle.dispose);
      return ref
          .watch(hostedFeedProvider)
          .load(
            url: libraryFeedUrl,
            cacheName: 'madar-library-v1',
            decode: (value) {
              if (value is! Map<String, Object?> || value['version'] != 1) {
                throw const FormatException('Invalid managed library payload');
              }
              return value;
            },
            fallback: () async => null,
          );
    });

const _refreshEvery = Duration(minutes: 15);
const _minResumeGap = Duration(minutes: 1);
