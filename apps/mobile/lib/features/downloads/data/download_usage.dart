import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

/// App-private folder that holds every download.
final downloadRootProvider = Provider<Future<Directory> Function()>(
  (_) => getApplicationSupportDirectory,
);

/// Bytes used on the device by each kind of download.
typedef DownloadUsage = ({int recitations, int stories, int library});

extension DownloadUsageTotal on DownloadUsage {
  int get total => recitations + stories + library;
}

/// Measures the download folders; refreshed after every download or removal.
final downloadUsageProvider = FutureProvider.autoDispose<DownloadUsage>((
  ref,
) async {
  final root = await ref.watch(downloadRootProvider)();
  Future<int> folder(String name) => _size(Directory('${root.path}/$name'));
  var library = 0;
  if (await root.exists()) {
    await for (final entry in root.list(followLinks: false)) {
      if (entry is File && entry.path.endsWith('.json')) {
        library += await entry.length();
      }
    }
  }
  return (
    recitations: await folder('recitation-audio-v1'),
    stories: await folder('learning-media-v1'),
    library: library,
  );
});

Future<int> _size(Directory directory) async {
  if (!await directory.exists()) return 0;
  var total = 0;
  await for (final entry in directory.list(
    recursive: true,
    followLinks: false,
  )) {
    // Partial files are temporary and never count as saved content.
    if (entry is File && !entry.path.endsWith('.part')) {
      total += await entry.length();
    }
  }
  return total;
}

/// «١٫٢ جيجابايت», «٣٤٠ ميجابايت» or the English equivalent.
String formatBytes(int bytes, String language, String Function(num) number) {
  const units = {
    'ar': ['بايت', 'كيلوبايت', 'ميجابايت', 'جيجابايت'],
    'en': ['B', 'KB', 'MB', 'GB'],
  };
  final names = units[language] ?? units['en']!;
  var value = bytes.toDouble();
  var unit = 0;
  while (value >= 1024 && unit < names.length - 1) {
    value /= 1024;
    unit++;
  }
  final tenths = (value * 10).round();
  final num rounded = unit >= 2 && value < 10 && tenths % 10 != 0
      ? tenths / 10
      : value.round();
  return '${number(rounded)} ${names[unit]}';
}
