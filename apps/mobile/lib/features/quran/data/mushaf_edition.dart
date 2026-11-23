import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xml/xml.dart';

import '../domain/quran_storage_contracts.dart';

final mushafEditionProvider = FutureProvider<MushafEdition>(
  (_) => MushafEdition.load(rootBundle),
);

class MushafSurah {
  const MushafSurah(this.id, this.arabicName, this.englishName, this.verses);
  final int id;
  final String arabicName;
  final String englishName;
  final List<String> verses;

  String name(String locale) => locale == 'ar' ? arabicName : englishName;
}

typedef MushafVerse = ({AyahRef ref, String text});

class MushafEdition {
  const MushafEdition._(
    this.surahs,
    this.verses,
    this.surahStarts,
    this.pageStarts,
    this.juzStarts,
    this.hizbStarts,
  );
  static const id = 'tanzil-uthmani-1.1';
  static const textSha256 =
      '6933e133dd56db778c801bf738848454e43648105a151e8d84d86a7cae39ec5f';
  static const metadataSha256 =
      '8867c1d88191472adec9db694b3cd9f135b1a2ef580574d32cf888dcb22c5c7a';

  final List<MushafSurah> surahs;
  final List<MushafVerse> verses;
  final List<int> surahStarts;
  final List<int> pageStarts;
  final List<int> juzStarts;
  final List<int> hizbStarts;

  bool contains(AyahRef ref) =>
      ref.editionId == id && ref.ayah <= surahs[ref.surah - 1].verses.length;

  int indexOf(AyahRef ref) => surahStarts[ref.surah - 1] + ref.ayah - 1;

  int pageOf(AyahRef ref) => _partitionOf(indexOf(ref), pageStarts);

  int juzOf(AyahRef ref) => _partitionOf(indexOf(ref), juzStarts);

  int hizbOf(AyahRef ref) => _partitionOf(indexOf(ref), hizbStarts);

  List<MushafVerse> page(int index) => verses.sublist(
    pageStarts[index],
    index + 1 < pageStarts.length ? pageStarts[index + 1] : verses.length,
  );

  static int _partitionOf(int verse, List<int> starts) {
    var low = 0;
    var high = starts.length;
    while (low + 1 < high) {
      final mid = (low + high) ~/ 2;
      if (verse < starts[mid]) {
        high = mid;
      } else {
        low = mid;
      }
    }
    return low;
  }

  /// Reads the bundled edition, then verifies and parses it on a background
  /// isolate: hashing and parsing 6,236 verses would otherwise hold up the
  /// first frames of the home screen and the reader.
  static Future<MushafEdition> load(AssetBundle bundle) async {
    final bytes = await Future.wait([
      _bytes(bundle, 'assets/quran/uthmani.txt'),
      _bytes(bundle, 'assets/quran/metadata.xml'),
    ]);
    return compute(_parse, (text: bytes[0], metadata: bytes[1]));
  }

  static MushafEdition _parse(({Uint8List text, Uint8List metadata}) input) {
    final source = [
      _verified(input.text, 'assets/quran/uthmani.txt', textSha256),
      _verified(input.metadata, 'assets/quran/metadata.xml', metadataSha256),
    ];
    final metadata = XmlDocument.parse(source[1]).rootElement;
    final elements = metadata
        .getElement('suras')!
        .findElements('sura')
        .toList();
    if (elements.length != surahCount) {
      throw const FormatException('Surah count');
    }
    final lines = const LineSplitter().convert(source[0]).iterator;
    final surahs = <MushafSurah>[];
    final allVerses = <MushafVerse>[];
    final surahStarts = <int>[];
    var verseCount = 0;
    for (final element in elements) {
      final surah = surahs.length + 1;
      if (element.getAttribute('index') != '$surah' ||
          element.getAttribute('start') != '$verseCount') {
        throw const FormatException('Surah order');
      }
      final verses = <String>[];
      final count = int.parse(element.getAttribute('ayas')!);
      surahStarts.add(verseCount);
      for (var ayah = 1; ayah <= count; ayah++) {
        final prefix = '$surah|$ayah|';
        if (!lines.moveNext() ||
            !lines.current.startsWith(prefix) ||
            lines.current.length == prefix.length) {
          throw FormatException('Verse order at $surah:$ayah');
        }
        final text = lines.current.substring(prefix.length);
        verses.add(text);
        allVerses.add((
          ref: AyahRef(editionId: id, surah: surah, ayah: ayah),
          text: text,
        ));
      }
      verseCount += count;
      surahs.add(
        MushafSurah(
          surah,
          element.getAttribute('name')!,
          element.getAttribute('tname')!,
          List.unmodifiable(verses),
        ),
      );
    }
    if (verseCount != 6236) throw const FormatException('Ayah count');
    while (lines.moveNext()) {
      if (lines.current.isNotEmpty && !lines.current.startsWith('#')) {
        throw const FormatException('Unexpected Quran text');
      }
    }
    List<int> partition(String group, String child, int expectedCount) {
      final starts = <int>[];
      for (final node in metadata.getElement(group)!.findElements(child)) {
        final surah = int.parse(node.getAttribute('sura')!);
        final ayah = int.parse(node.getAttribute('aya')!);
        if (node.getAttribute('index') != '${starts.length + 1}' ||
            surah < 1 ||
            surah > surahs.length ||
            ayah < 1 ||
            ayah > surahs[surah - 1].verses.length) {
          throw FormatException('Invalid $group boundary');
        }
        final start = surahStarts[surah - 1] + ayah - 1;
        if (starts.isNotEmpty && start <= starts.last) {
          throw FormatException('Unordered $group boundary');
        }
        starts.add(start);
      }
      if (starts.length != expectedCount || starts.first != 0) {
        throw FormatException('Incomplete $group boundaries');
      }
      return List.unmodifiable(starts);
    }

    final quarters = partition('hizbs', 'quarter', 240);
    return MushafEdition._(
      List.unmodifiable(surahs),
      List.unmodifiable(allVerses),
      List.unmodifiable(surahStarts),
      partition('pages', 'page', 604),
      partition('juzs', 'juz', 30),
      List.unmodifiable([
        for (var i = 0; i < quarters.length; i += 4) quarters[i],
      ]),
    );
  }

  static Future<Uint8List> _bytes(AssetBundle bundle, String path) async {
    final data = await bundle.load(path);
    return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  }

  static String _verified(Uint8List bytes, String path, String digest) {
    if (sha256.convert(bytes).toString() != digest) {
      throw FormatException('Checksum mismatch: $path');
    }
    return utf8.decode(bytes);
  }
}
