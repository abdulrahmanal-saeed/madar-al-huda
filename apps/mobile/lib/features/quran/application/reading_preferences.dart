import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/storage/storage_providers.dart';
import '../../../core/theme/brand_colors.dart';

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
    ReadingPaper.light => BrandColors.lightReadingPaper,
    ReadingPaper.warm => BrandColors.warmReadingPaper,
    ReadingPaper.night => BrandColors.nightReadingPaper,
    ReadingPaper.amber => BrandColors.amberReadingPaper,
    ReadingPaper.auto => (
      paper: dark
          ? colors.surfaceContainerLow
          : Color.lerp(colors.surface, colors.surfaceContainerLow, .5)!,
      ink: colors.onSurface,
      border: dark ? colors.outline : colors.surfaceContainerHigh,
      banner: dark ? colors.secondaryContainer : colors.surfaceContainer,
    ),
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
