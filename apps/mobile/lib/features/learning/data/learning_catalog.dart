import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final prophetStoriesProvider = FutureProvider<List<LearningSeries>>(
  (_) async => parseLearningSeries(
    await rootBundle.loadString('assets/learning/prophet_stories.json'),
  ),
);

enum LessonFormat {
  audio('mp3', 'audio/mpeg'),
  video('mp4', 'video/mp4');

  const LessonFormat(this.extension, this.mimeType);
  final String extension;
  final String mimeType;
}

class LessonMedia {
  const LessonMedia(this.fileName, this.bytes, this.format);

  final String fileName;
  final int bytes;
  final LessonFormat format;
}

class LessonEpisode {
  const LessonEpisode(this.number, this.media);

  final int number;
  final Map<LessonFormat, LessonMedia> media;
}

class LearningSeries {
  const LearningSeries(this.id, this.arabic, this.english, this.episodes);

  final String id;
  final String arabic;
  final String english;
  final List<LessonEpisode> episodes;

  String title(String language) => language == 'ar' ? arabic : english;
  String trackId(LessonEpisode episode) => 'learning:$id:${episode.number}';

  List<LessonEpisode> queue(LessonFormat format, int from) => [
    for (final episode in episodes)
      if (episode.number >= from && episode.media.containsKey(format)) episode,
  ];
}

List<LearningSeries> parseLearningSeries(String source) {
  final data = jsonDecode(source) as List<Object?>;
  final ids = <String>{};
  final fileNames = <String>{};
  return List.unmodifiable(
    data.map((item) {
      final entry = item as Map<String, dynamic>;
      final id = entry['id'] as String;
      if (!ids.add(id) || !RegExp(r'^[a-z0-9-]+$').hasMatch(id)) {
        throw FormatException('Invalid series identifier', id);
      }
      final episodes =
          (entry['episodes'] as List<Object?>).map((item) {
              final value = item as Map<String, dynamic>;
              final media = value['media'] as Map<String, dynamic>;
              return LessonEpisode(
                value['number'] as int,
                Map.unmodifiable({
                  for (final format in LessonFormat.values)
                    if (media[format.name] case final Map<String, dynamic> file)
                      format: _readMedia(file, format, fileNames),
                }),
              );
            }).toList()
            ..sort((first, second) => first.number.compareTo(second.number));
      var previous = 0;
      for (final episode in episodes) {
        if (episode.number <= previous || episode.media.isEmpty) {
          throw FormatException('Invalid or repeated episode number', id);
        }
        previous = episode.number;
      }
      return LearningSeries(
        id,
        entry['ar'] as String,
        entry['en'] as String,
        List.unmodifiable(episodes),
      );
    }),
  );
}

LessonMedia _readMedia(
  Map<String, dynamic> file,
  LessonFormat format,
  Set<String> fileNames,
) {
  final name = file['file'] as String;
  final bytes = file['bytes'] as int;
  if (!RegExp(r'^[A-Za-z0-9][A-Za-z0-9_-]*\.(mp3|mp4)$').hasMatch(name) ||
      !name.endsWith('.${format.extension}') ||
      !fileNames.add(name) ||
      bytes <= 0) {
    throw FormatException('Invalid learning media', name);
  }
  return LessonMedia(name, bytes, format);
}
