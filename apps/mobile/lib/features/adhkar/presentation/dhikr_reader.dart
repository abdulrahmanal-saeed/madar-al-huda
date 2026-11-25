import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/localization/l10n_extension.dart';
import '../../../core/localization/numbers.dart';
import '../../../core/theme/app_theme.dart';
import '../data/adhkar_catalog.dart';
import '../data/adhkar_progress.dart';
import 'adhkar_widgets.dart';
import 'dhikr_content.dart';

class DhikrReader extends ConsumerStatefulWidget {
  const DhikrReader({required this.group, super.key});

  final DhikrGroup group;

  @override
  ConsumerState<DhikrReader> createState() => _DhikrReaderState();
}

class _DhikrReaderState extends ConsumerState<DhikrReader> {
  final _scroll = ScrollController();
  late int _index;

  @override
  void initState() {
    super.initState();
    final progress = ref.read(adhkarProgressProvider);
    final group = widget.group;
    final day = adhkarDayKey(DateTime.now());
    final first = group.entries.indexWhere(
      (entry) => !progress.complete(day, group, entry),
    );
    _index = first < 0 ? 0 : first;
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _go(int index) {
    setState(() => _index = index);
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  @override
  Widget build(BuildContext context) {
    final group = widget.group;
    final entry = group.entries[_index];
    final day = adhkarDayKey(DateTime.now());
    final language = context.adhkarLanguage;
    final progress = ref.watch(adhkarProgressProvider);
    final controller = ref.read(adhkarProgressProvider.notifier);
    final option = progress.variantIndex(day, group, entry);
    final variant = entry.variants[option];
    final savedKey = entry.savedKey(variant);
    final saved = progress.saved.contains(savedKey);
    final shownCount = progress.count(day, group, entry);
    final complete = shownCount == variant.goal;
    final separateSteps = variant.steps.length > 1 &&
        variant.steps.every((step) => const {
          'tasbih', 'tahmid', 'takbir', 'tahlil', 'closing_tahlil',
        }.contains(step.unit));
    final number = decimalFormat(language).format;
    final l10n = context.l10n;
    return AdhkarPage(
      title: group.title.inLanguage(language),
      actions: [
        IconButton(
          tooltip: saved ? l10n.adhkarRemoveFavorite : l10n.adhkarAddFavorite,
          icon: Icon(saved ? Icons.favorite : Icons.favorite_border),
          onPressed: () => adhkarSave(
            context,
            controller.setSaved(savedKey, selected: !saved),
          ),
        ),
      ],
      body: ListView(
        controller: _scroll,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        children: [
          Text(
            l10n.adhkarPosition(
              number(_index + 1),
              number(group.entries.length),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              for (final item in group.entries)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: LinearProgressIndicator(
                      value: progress.complete(day, group, item) ? 1 : 0,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            entry.title.inLanguage(language),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          if (entry.variants.length > 1)
            DropdownButton<int>(
              isExpanded: true,
              value: option,
              items: [
                for (var i = 0; i < entry.variants.length; i++)
                  DropdownMenuItem(
                    value: i,
                    child: Text(
                      l10n.adhkarVariant(
                        entry.variants[i].steps
                            .map((step) => number(step.count))
                            .join(' · '),
                      ),
                    ),
                  ),
              ],
              onChanged: (value) {
                if (value != null) {
                  adhkarSave(
                    context,
                    controller.chooseVariant(day, group, entry, value),
                  );
                }
              },
            ),
          const SizedBox(height: 10),
          if (separateSteps)
            for (var i = 0; i < variant.steps.length; i++)
              _stepCard(context, group, entry, variant, day, i),
          DhikrContent(
            key: ValueKey('${entry.id}:${variant.hadith}'),
            hadith: variant.hadith,
            entry: entry,
            period: group.id,
            showWording: !separateSteps,
          ),
          const SizedBox(height: 14),
          Text(l10n.adhkarSavedProgress, textAlign: TextAlign.center),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!separateSteps)
                Row(
                children: [
                  if (variant.steps.isNotEmpty) ...[
                    Semantics(
                      liveRegion: true,
                      child: SizedBox.square(
                        dimension: 54,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            CircularProgressIndicator(
                              value: shownCount / variant.goal,
                            ),
                            Center(
                              child: Text(
                                number(shownCount),
                                semanticsLabel: l10n.adhkarPosition(
                                  number(shownCount),
                                  number(variant.goal),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: FilledButton(
                      onPressed: complete
                          ? null
                          : () => adhkarSave(
                              context,
                              controller.advance(day, group, entry),
                            ),
                      child: Text(
                        complete
                            ? l10n.adhkarCompleted
                            : variant.steps.isEmpty
                            ? l10n.adhkarMarkRead
                            : _counterLabel(
                                context,
                                variant.stepAt(shownCount).unit,
                              ),
                      ),
                    ),
                  ),
                ],
              ),
              if (separateSteps)
                Text(
                  complete ? l10n.adhkarCompleted : '${number(shownCount)} / ${number(variant.goal)}',
                  textAlign: TextAlign.center,
                ),
              OverflowBar(
                alignment: MainAxisAlignment.spaceBetween,
                overflowAlignment: OverflowBarAlignment.center,
                children: [
                  TextButton.icon(
                    onPressed: _index > 0 ? () => _go(_index - 1) : null,
                    icon: const Icon(Icons.arrow_back),
                    label: Text(l10n.adhkarPrevious),
                  ),
                  if (shownCount > 0)
                    TextButton(
                      onPressed: () => adhkarSave(
                        context,
                        controller.reset(day, group, entry),
                      ),
                      child: Text(l10n.adhkarReset),
                    ),
                  if (_index + 1 < group.entries.length)
                    TextButton.icon(
                      onPressed: () => _go(_index + 1),
                      label: Text(l10n.adhkarNext),
                      icon: const Icon(Icons.arrow_forward),
                    )
                  else
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(l10n.adhkarReturnToToday),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stepCard(
    BuildContext context,
    DhikrGroup group,
    DhikrEntry entry,
    DhikrVariant variant,
    String day,
    int index,
  ) {
    final step = variant.steps[index];
    final language = context.adhkarLanguage;
    final number = decimalFormat(language).format;
    final l10n = context.l10n;
    final count = ref.watch(adhkarProgressProvider).stepCount(day, group, entry, index);
    final finished = count >= step.count;
    final fullTahlil = step.unit == 'closing_tahlil' ||
        (step.unit == 'tahlil' && step.count == 1);
    final wording = switch (step.unit) {
      'tasbih' => 'سُبْحَانَ اللَّهِ',
      'tahmid' => 'الْحَمْدُ لِلَّهِ',
      'takbir' => 'اللَّهُ أَكْبَرُ',
      _ => fullTahlil
          ? 'لَا إِلَٰهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ، وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ'
          : 'لَا إِلَٰهَ إِلَّا اللَّهُ',
    };
    final meaning = switch (step.unit) {
      'tasbih' => 'Glory be to Allah.',
      'tahmid' => 'All praise belongs to Allah.',
      'takbir' => 'Allah is the Greatest.',
      _ => fullTahlil
          ? 'There is no deity worthy of worship except Allah alone, without partner. To Him belongs all sovereignty and praise, and He has power over all things.'
          : 'There is no deity worthy of worship except Allah.',
    };
    return Card(
      key: ValueKey('dhikr-step-$index'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              wording,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontFamily: AppTheme.readingFontFamily,
                fontSize: 23,
                height: 1.75,
              ),
            ),
            if (language == 'en') Text(meaning),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: finished ? null : () => adhkarSave(
                      context,
                      ref.read(adhkarProgressProvider.notifier).advanceStep(
                        day, group, entry, index,
                      ),
                    ),
                    child: Text(finished ? l10n.adhkarCompleted : _counterLabel(context, step.unit)),
                  ),
                ),
                const SizedBox(width: 12),
                Semantics(
                  liveRegion: true,
                  child: SizedBox.square(
                    dimension: 64,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CircularProgressIndicator(value: count / step.count),
                        Center(child: Text('${number(count)}/${number(step.count)}')),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _counterLabel(BuildContext context, String unit) {
    final l10n = context.l10n;
    return switch (unit) {
      'tasbih' => l10n.adhkarTasbih,
      'tahmid' => l10n.adhkarTahmid,
      'takbir' => l10n.adhkarTakbir,
      'closing_tahlil' || 'tahlil' => l10n.adhkarTahlil,
      'seeking_forgiveness' => l10n.adhkarIstighfar,
      'each_surah' => l10n.adhkarThreeSurahCycle,
      'full_recitation_and_wiping_cycle' => l10n.adhkarBedtimeCycle,
      _ => l10n.adhkarCountOnce,
    };
  }
}
