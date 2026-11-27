import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/storage/storage_providers.dart';

/// Background of the Mushaf page, independent of the app theme.
enum ReadingPaper { auto, light, warm, night, amber }

typedef ReadingPreferences = ({double fontSize, ReadingPaper paper});

const defaultReadingFontSize = 27.0;
const minReadingFontSize = 20.0;
const maxReadingFontSize = 40.0;

/// Colours of one page background.
typedef PaperColors = ({Color paper, Color ink, Color border, Color banner});

PaperColors paperColors(ReadingPaper paper, ThemeData theme) {
  final colors = theme.colorScheme;
  final dark = theme.brightness == Brightness.dark;
  return switch (paper) {
    ReadingPaper.light => (
      paper: const Color(0xfffaf7ff),
      ink: const Color(0xff1b1530),
      border: const Color(0xffe4def3),
      banner: const Color(0xffeee9f8),
    ),
    ReadingPaper.warm => (
      paper: const Color(0xfff3e7cf),
      ink: const Color(0xff3a2a12),
      border: const Color(0xffd9c79f),
      banner: const Color(0xffeadbbb),
    ),
    ReadingPaper.night => (
      paper: const Color(0xff0d1917),
      ink: const Color(0xffece6d8),
      border: const Color(0xff34473f),
      banner: const Color(0xff223631),
    ),
    // Warm amber text on brown: dimmer than [night] for reading in the dark.
    ReadingPaper.amber => (
      paper: const Color(0xff1d1711),
      ink: const Color(0xffe9d3a6),
      border: const Color(0xff4a3a26),
      banner: const Color(0xff2c2218),
    ),
    ReadingPaper.auto =>
      dark
          ? (
              paper: colors.surfaceContainerLow,
              ink: colors.onSurface,
              border: colors.outline,
              banner: colors.secondaryContainer,
            )
          : paperColors(ReadingPaper.light, theme),
  };
}

/// Full-screen reading: the Mushaf hides its bars and the tab bar.
final readingFocusProvider = NotifierProvider<ReadingFocus, bool>(
  ReadingFocus.new,
);

class ReadingFocus extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool value) => state = value;
}

final readingPreferencesProvider =
    NotifierProvider<ReadingPreferencesController, ReadingPreferences>(
      ReadingPreferencesController.new,
    );

class ReadingPreferencesController extends Notifier<ReadingPreferences> {
  static const key = 'quran.reading.v1';
  Future<void> _save = Future.value();

  @override
  ReadingPreferences build() {
    final raw = ref.watch(keyValueStoreProvider).getString(key);
    try {
      final data = jsonDecode(raw ?? '{}') as Map<String, Object?>;
      final size = data['fontSize'];
      return (
        fontSize: size is num
            ? size.toDouble().clamp(minReadingFontSize, maxReadingFontSize)
            : defaultReadingFontSize,
        paper:
            ReadingPaper.values
                .where((paper) => paper.name == data['paper'])
                .firstOrNull ??
            ReadingPaper.auto,
      );
    } on Object {
      return (fontSize: defaultReadingFontSize, paper: ReadingPaper.auto);
    }
  }

  Future<void> setFontSize(double size) => _update((
    fontSize: size.clamp(minReadingFontSize, maxReadingFontSize),
    paper: state.paper,
  ));

  Future<void> setPaper(ReadingPaper paper) =>
      _update((fontSize: state.fontSize, paper: paper));

  Future<void> _update(ReadingPreferences next) {
    state = next;
    final store = ref.read(keyValueStoreProvider);
    final write = _save.then(
      (_) => store.setString(
        key,
        jsonEncode({'fontSize': next.fontSize, 'paper': next.paper.name}),
      ),
    );
    _save = write.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return write;
  }
}
