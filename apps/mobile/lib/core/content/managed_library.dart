import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'hosted_feed.dart';

final managedLibraryProvider =
    FutureProvider.autoDispose<Map<String, Object?>?>((ref) {
      final timer = Timer(const Duration(minutes: 2), ref.invalidateSelf);
      ref.onDispose(timer.cancel);
      return ref
          .watch(hostedFeedProvider)
          .load(
            url: Uri.https('quran.abdulrahmanalsaeed.com', '/admin/', {
              'feed': 'library',
            }),
            cacheName: 'managed-library-v1',
            decode: (value) {
              if (value is! Map<String, Object?> || value['version'] != 1) {
                throw const FormatException('Invalid managed library payload');
              }
              return value;
            },
            fallback: () async => null,
          );
    });
