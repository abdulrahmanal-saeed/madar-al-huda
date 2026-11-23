import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/content/hosted_feed.dart';
import 'learning_catalog.dart';
import 'learning_files.dart';

final prophetStoriesProvider = FutureProvider.autoDispose<List<LearningSeries>>(
  (ref) {
    final refresh = Timer(const Duration(minutes: 2), ref.invalidateSelf);
    ref.onDispose(refresh.cancel);
    final base = ref.watch(learningFilesProvider).base;
    return ref
        .watch(hostedFeedProvider)
        .load(
          url: base?.replace(
            pathSegments: [
              ...base.pathSegments.where((segment) => segment.isNotEmpty),
              'catalog.php',
            ],
          ),
          cacheName: 'prophet-stories-catalog-v1',
          decode: (data) {
            if (data is! Map || data['version'] != 1) {
              throw const FormatException('Invalid story catalog version');
            }
            return parseLearningCatalog(data['series']);
          },
          fallback: () async => parseLearningCatalog(
            jsonDecode(
              await rootBundle.loadString(
                'assets/learning/prophet_stories.json',
              ),
            ),
          ),
        );
  },
);
