import 'dart:convert';

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

typedef LocalizedText = ({String ar, String en});

String localizedIn(LocalizedText text, String language) =>
    language == 'ar' ? text.ar : text.en;

LocalizedText? _localized(Object? value) {
  if (value is! Map) return null;
  final ar = '${value['ar'] ?? ''}'.trim();
  final en = '${value['en'] ?? ''}'.trim();
  if (ar.isEmpty && en.isEmpty) return null;
  return (ar: ar.isNotEmpty ? ar : en, en: en.isNotEmpty ? en : ar);
}

class LessonEpisode {
  const LessonEpisode(this.number, this.media, {this.title});

  final int number;
  final Map<LessonFormat, LessonMedia> media;

  /// The title set in the dashboard, if any.
  final LocalizedText? title;
}

class LearningSeries {
  const LearningSeries(
    this.id,
    this.arabic,
    this.english,
    this.episodes, {
    this.description,
  });

  final String id;
  final String arabic;
  final String english;
  final List<LessonEpisode> episodes;
  final LocalizedText? description;

  String title(String language) => language == 'ar' ? arabic : english;
  String trackId(LessonEpisode episode) => 'learning:$id:${episode.number}';

  List<LessonEpisode> queue(LessonFormat format, int from) => [
    for (final episode in episodes)
      if (episode.number >= from && episode.media.containsKey(format)) episode,
  ];
}

List<LearningSeries> parseLearningSeries(String source) =>
    parseLearningCatalog(jsonDecode(source));

List<LearningSeries> parseLearningCatalog(Object? source) {
  final data = source as List<Object?>;
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
                title: _localized(value['title']),
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
        description: _localized(entry['description']),
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
