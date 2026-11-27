import '../content/managed_library.dart';

typedef DevotionalRecording = ({Uri url, int bytes});

DevotionalRecording? devotionalRecording(Object? raw) {
  if (raw is! Map) return null;
  final file = raw['file'];
  final bytes = raw['bytes'];
  if (file is! String ||
      !RegExp(r'^Library-[a-f0-9]{32}[.]mp3$').hasMatch(file) ||
      bytes is! int ||
      bytes < 1024 ||
      bytes > 12 * 1024 * 1024) {
    return null;
  }
  return (
    url: libraryFeedUrl.replace(queryParameters: {'library_media': file}),
    bytes: bytes,
  );
}
