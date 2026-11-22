import 'dart:convert';

import 'package:crypto/crypto.dart';
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

class MushafEdition {
  const MushafEdition._(this.surahs);
  static const id = 'tanzil-uthmani-1.1';
  static const textSha256 =
      '6933e133dd56db778c801bf738848454e43648105a151e8d84d86a7cae39ec5f';
  static const metadataSha256 =
      '8867c1d88191472adec9db694b3cd9f135b1a2ef580574d32cf888dcb22c5c7a';

  final List<MushafSurah> surahs;

  bool contains(AyahRef ref) =>
      ref.editionId == id && ref.ayah <= surahs[ref.surah - 1].verses.length;

  static Future<MushafEdition> load(AssetBundle bundle) async {
    final source = await Future.wait([
      _read(bundle, 'assets/quran/uthmani.txt', textSha256),
      _read(bundle, 'assets/quran/metadata.xml', metadataSha256),
    ]);
    final elements = XmlDocument.parse(source[1])
        .findAllElements('sura')
        .toList();
    if (elements.length != surahCount) {
      throw const FormatException('Surah count');
    }
    final lines = const LineSplitter().convert(source[0]).iterator;
    final surahs = <MushafSurah>[];
    var verseCount = 0;
    for (final element in elements) {
      final surah = surahs.length + 1;
      if (element.getAttribute('index') != '$surah' ||
          element.getAttribute('start') != '$verseCount') {
        throw const FormatException('Surah order');
      }
      final verses = <String>[];
      final count = int.parse(element.getAttribute('ayas')!);
      for (var ayah = 1; ayah <= count; ayah++) {
        final prefix = '$surah|$ayah|';
        if (!lines.moveNext() ||
            !lines.current.startsWith(prefix) ||
            lines.current.length == prefix.length) {
          throw FormatException('Verse order at $surah:$ayah');
        }
        verses.add(lines.current.substring(prefix.length));
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
    return MushafEdition._(List.unmodifiable(surahs));
  }

  static Future<String> _read(
    AssetBundle bundle,
    String path,
    String digest,
  ) async {
    final data = await bundle.load(path);
    final bytes = data.buffer.asUint8List(
      data.offsetInBytes,
      data.lengthInBytes,
    );
    if (sha256.convert(bytes).toString() != digest) {
      throw FormatException('Checksum mismatch: $path');
    }
    return utf8.decode(bytes);
  }
}
