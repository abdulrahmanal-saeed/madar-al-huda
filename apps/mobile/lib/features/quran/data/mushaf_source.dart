import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../core/storage/storage_providers.dart';
import 'quran_services.dart';

enum MushafSource {
  tanzil(0, 'Tanzil', 'تنزيل'),
  madinah(1, 'Madinah · QCF V2', 'مصحف المدينة · QCF V2'),
  tajweed(19, 'Tajweed · QCF V4', 'مصحف التجويد · QCF V4');

  const MushafSource(this.id, this.en, this.ar);
  final int id;
  final String en;
  final String ar;
}

final mushafSourceProvider =
    NotifierProvider<MushafSourceController, MushafSource>(
      MushafSourceController.new,
    );

class MushafSourceController extends Notifier<MushafSource> {
  static const _key = 'quran.mushafSource.v1';
  Future<void> _pending = Future.value();

  @override
  MushafSource build() {
    final selected = ref.watch(keyValueStoreProvider).getString(_key);
    return MushafSource.values
            .where((source) => source.name == selected)
            .firstOrNull ??
        MushafSource.tanzil;
  }

  Future<void> select(MushafSource value) {
    state = value;
    final store = ref.read(keyValueStoreProvider);
    final write = _pending.then((_) => store.setString(_key, value.name));
    _pending = write.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return write;
  }
}

typedef QcfPage = ({String font, Map<String, String> glyphs});

final qcfPageProvider = FutureProvider.autoDispose
    .family<QcfPage, ({MushafSource source, int page})>((ref, request) async {
      final (:source, :page) = request;
      final api = ref.watch(quranApiProvider);
      final data = await api.mushafPage(source.id, page);
      if (data['edition'] != source.id || data['page'] != page) {
        throw const FormatException('Mushaf identity mismatch');
      }
      final glyphs = <String, String>{};
      for (final raw in data['verses'] as List) {
        final verse = raw as Map;
        final key = verse['key'] as String;
        final words = verse['words'] as List;
        final glyph = words
            .map((word) => (word as List)[1] as String)
            .join(' ');
        if (glyph.isEmpty || glyphs.containsKey(key)) {
          throw const FormatException('Unexpected Mushaf glyphs');
        }
        glyphs[key] = glyph;
      }
      final font = await ref.read(_mushafFontsProvider).load(source, page);
      return (font: font, glyphs: glyphs);
    });

final _mushafFontsProvider = Provider<_MushafFonts>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return _MushafFonts(client);
});

class _MushafFonts {
  _MushafFonts(this.client);
  final http.Client client;
  final _loaded = <String, Future<String>>{};

  Future<String> load(MushafSource source, int page) {
    final family = 'QCF-${source.name}-$page';
    return _loaded[family] ??= _load(source, page, family).onError((
      error,
      stack,
    ) {
      _loaded.remove(family);
      Error.throwWithStackTrace(
        error ?? StateError('Font loading failed'),
        stack,
      );
    });
  }

  Future<String> _load(MushafSource source, int page, String family) async {
    final version = source == MushafSource.tajweed ? 'v4/colrv1' : 'v2';
    final response = await client
        .get(
          Uri.https(
            'verses.quran.foundation',
            '/fonts/quran/hafs/$version/ttf/p$page.ttf',
          ),
        )
        .timeout(const Duration(seconds: 12));
    if (response.statusCode != 200 ||
        response.bodyBytes.length > 1024 * 1024 ||
        response.bodyBytes.isEmpty) {
      throw const FormatException('Quran Foundation font unavailable');
    }
    final loader = FontLoader(family)
      ..addFont(Future.value(ByteData.sublistView(response.bodyBytes)));
    await loader.load();
    return family;
  }
}
