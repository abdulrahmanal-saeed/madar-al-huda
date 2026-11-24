import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/localization/l10n_extension.dart';
import '../../../core/localization/numbers.dart';
import '../../../core/theme/app_tokens.dart';
import '../application/reading_preferences.dart';

Future<void> showReadingSettings(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => const ReadingSettingsSheet(),
    );

/// Text size and page background for the Mushaf, applied as they change.
class ReadingSettingsSheet extends ConsumerWidget {
  const ReadingSettingsSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final language = Localizations.localeOf(context).languageCode;
    final number = decimalFormat(language).format;
    final preferences = ref.watch(readingPreferencesProvider);
    final controller = ref.read(readingPreferencesProvider.notifier);
    final papers = {
      ReadingPaper.auto: l10n.readerPaperAuto,
      ReadingPaper.light: l10n.readerPaperLight,
      ReadingPaper.warm: l10n.readerPaperWarm,
      ReadingPaper.night: l10n.readerPaperNight,
    };
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.readerAppearance, style: theme.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.lg),
            Text(l10n.readerFontSize, style: theme.textTheme.titleSmall),
            Row(
              children: [
                IconButton(
                  tooltip: l10n.readerSmaller,
                  onPressed: preferences.fontSize > minReadingFontSize
                      ? () => controller.setFontSize(preferences.fontSize - 2)
                      : null,
                  icon: const Icon(Icons.text_decrease),
                ),
                Expanded(
                  child: Slider(
                    key: const ValueKey('reader-font-size'),
                    min: minReadingFontSize,
                    max: maxReadingFontSize,
                    divisions: ((maxReadingFontSize - minReadingFontSize) / 2)
                        .round(),
                    value: preferences.fontSize,
                    label: number(preferences.fontSize.round()),
                    onChanged: controller.setFontSize,
                  ),
                ),
                IconButton(
                  tooltip: l10n.readerLarger,
                  onPressed: preferences.fontSize < maxReadingFontSize
                      ? () => controller.setFontSize(preferences.fontSize + 2)
                      : null,
                  icon: const Icon(Icons.text_increase),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(l10n.readerPaper, style: theme.textTheme.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            SegmentedButton<ReadingPaper>(
              key: const ValueKey('reader-paper'),
              showSelectedIcon: false,
              segments: [
                for (final entry in papers.entries)
                  ButtonSegment(value: entry.key, label: Text(entry.value)),
              ],
              selected: {preferences.paper},
              onSelectionChanged: (selection) =>
                  controller.setPaper(selection.first),
            ),
          ],
        ),
      ),
    );
  }
}
