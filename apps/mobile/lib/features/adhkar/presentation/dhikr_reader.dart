import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/audio/devotional_audio_button.dart';
import '../../../core/localization/l10n_extension.dart';
import '../../../core/localization/numbers.dart';
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
  bool _saving = false;
  bool _groupFinished = false;

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
    setState(() {
      _index = index;
      _groupFinished = false;
    });
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  Future<void> _advance(String day, DhikrGroup group, DhikrEntry entry) async {
    if (_saving) return;
    final index = _index;
    final progress = ref.read(adhkarProgressProvider);
    if (progress.complete(day, group, entry)) return;
    setState(() => _saving = true);
    await adhkarSave(context, () async {
      await ref
          .read(adhkarProgressProvider.notifier)
          .advance(day, group, entry);
      if (!mounted ||
          index != _index ||
          !ref.read(adhkarProgressProvider).complete(day, group, entry)) {
        return;
      }
      if (index + 1 < group.entries.length) {
        _go(index + 1);
      } else {
        final result = ref.read(adhkarProgressProvider);
        setState(
          () => _groupFinished =
              result.completedInGroup(day, group) == result.groupGoal(group),
        );
      }
    }());
    if (mounted) setState(() => _saving = false);
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
    final number = decimalFormat(language).format;
    final l10n = context.l10n;
    return AdhkarPage(
      title: group.title.inLanguage(language),
      actions: [
        if (variant.recording case final recording?)
          DevotionalAudioButton(
            recording: recording,
            title: entry.title.inLanguage(language),
          ),
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
          DhikrContent(
            key: ValueKey('${entry.id}:${variant.hadith}'),
            hadith: variant.hadith,
            entry: entry,
            period: group.id,
          ),
          const SizedBox(height: 14),
          if (_groupFinished)
            Semantics(
              liveRegion: true,
              child: Text(
                language == 'ar'
                    ? 'تمت مجموعة الأذكار'
                    : 'Remembrance group complete',
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  if (variant.steps.isNotEmpty) ...[
                    Semantics(
                      liveRegion: true,
                      label: l10n.adhkarPosition(
                        number(shownCount),
                        number(variant.goal),
                      ),
                      child: SizedBox.square(
                        dimension: 82,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(42),
                          onTap: complete || _saving
                              ? null
                              : () => _advance(day, group, entry),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              CircularProgressIndicator(
                                value: shownCount / variant.goal,
                              ),
                              Center(
                                child: Text(
                                  number(shownCount),
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: FilledButton(
                      onPressed: complete || _saving
                          ? null
                          : () => _advance(day, group, entry),
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

  String _counterLabel(BuildContext context, String unit) {
    final l10n = context.l10n;
    return switch (unit) {
      'tasbih' => l10n.adhkarTasbih,
      'tahmid' => l10n.adhkarTahmid,
      'takbir' => l10n.adhkarTakbir,
      'closing_tahlil' => l10n.adhkarTahlil,
      'seeking_forgiveness' => l10n.adhkarIstighfar,
      'each_surah' => l10n.adhkarThreeSurahCycle,
      'full_recitation_and_wiping_cycle' => l10n.adhkarBedtimeCycle,
      _ => l10n.adhkarCountOnce,
    };
  }
}
