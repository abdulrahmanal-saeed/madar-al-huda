import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/localization/l10n_extension.dart';
import '../../../core/localization/numbers.dart';
import '../../../core/localization/search_text.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../application/memorization.dart';
import '../data/mushaf_edition.dart';

/// Memorizing a passage: repeat each verse, hide the text to recite it, and
/// mark what is memorized.
class MemorizeScreen extends ConsumerStatefulWidget {
  const MemorizeScreen({super.key});

  @override
  ConsumerState<MemorizeScreen> createState() => _MemorizeScreenState();
}

class _MemorizeScreenState extends ConsumerState<MemorizeScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final language = Localizations.localeOf(context).languageCode;
    final numbers = decimalFormat(language);
    final edition = ref.watch(mushafEditionProvider).asData?.value;
    final memorized = ref.watch(memorizedProvider);
    if (edition == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.memorizeTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final total = edition.verses.length;
    final done = memorized.values.fold<int>(0, (sum, v) => sum + v.length);
    final needle = normalizeSearch(_query);
    final surahs = [
      for (final surah in edition.surahs)
        if (needle.isEmpty ||
            normalizeSearch(surah.arabicName).contains(needle) ||
            normalizeSearch(surah.englishName).contains(needle) ||
            '${surah.id}' == needle)
          surah,
    ];
    return Scaffold(
      appBar: AppBar(title: Text(l10n.memorizeTitle)),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            sliver: SliverList.list(
              children: [
                Card(
                  margin: EdgeInsets.zero,
                  color: scheme.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.memorizeOverall(
                            numbers.format(done),
                            numbers.format(total),
                          ),
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        ClipRRect(
                          borderRadius: AppRadii.smAll,
                          child: LinearProgressIndicator(
                            value: done / total,
                            minHeight: 8,
                            backgroundColor: scheme.surface,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          l10n.memorizeIntro,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  onChanged: (value) => setState(() => _query = value),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: l10n.memorizeFindSurah,
                    isDense: true,
                    border: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(28)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SliverList.builder(
            itemCount: surahs.length,
            itemBuilder: (context, index) {
              final surah = surahs[index];
              final count = memorized[surah.id]?.length ?? 0;
              final share = count / surah.verses.length;
              return ListTile(
                key: ValueKey('memorize-surah-${surah.id}'),
                leading: CircleAvatar(
                  backgroundColor: share == 1
                      ? scheme.primary
                      : scheme.secondaryContainer,
                  foregroundColor: share == 1
                      ? scheme.onPrimary
                      : scheme.onSecondaryContainer,
                  child: share == 1
                      ? const Icon(Icons.check)
                      : Text(numbers.format(surah.id)),
                ),
                title: Text(surah.name(language)),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Row(
                    children: [
                      Expanded(
                        child: LinearProgressIndicator(
                          value: share,
                          minHeight: 4,
                          borderRadius: AppRadii.smAll,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        '${numbers.format(count)}/${numbers.format(surah.verses.length)}',
                        style: theme.textTheme.labelSmall,
                      ),
                    ],
                  ),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        MemorizeSession(edition: edition, surah: surah),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class MemorizeSession extends ConsumerStatefulWidget {
  const MemorizeSession({
    required this.edition,
    required this.surah,
    super.key,
  });

  final MushafEdition edition;
  final MushafSurah surah;

  @override
  ConsumerState<MemorizeSession> createState() => _MemorizeSessionState();
}

class _MemorizeSessionState extends ConsumerState<MemorizeSession> {
  late int _first = 1;
  late int _last = math.min(widget.surah.verses.length, 5);
  MemorizeView _view = MemorizeView.full;
  int _target = 5;
  final _counts = <int, int>{};
  final _revealed = <int>{};

  void _count(int ayah) {
    setState(() {
      final next = (_counts[ayah] ?? 0) + 1;
      _counts[ayah] = next > _target ? 0 : next;
    });
    if (_counts[ayah] == _target) HapticFeedback.mediumImpact();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final language = Localizations.localeOf(context).languageCode;
    final numbers = decimalFormat(language);
    final memorized = ref.watch(memorizedProvider)[widget.surah.id] ?? const {};
    final controller = ref.read(memorizedProvider.notifier);
    final verseCount = widget.surah.verses.length;
    final all = [for (var a = _first; a <= _last; a++) a];

    DropdownButton<int> picker(
      int value,
      ValueChanged<int> onChanged, {
      required int from,
      required int to,
    }) => DropdownButton<int>(
      value: value,
      isDense: true,
      menuMaxHeight: 360,
      items: [
        for (var ayah = from; ayah <= to; ayah++)
          DropdownMenuItem(value: ayah, child: Text(numbers.format(ayah))),
      ],
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.surah.name(language)),
        actions: [
          PopupMenuButton<bool>(
            onSelected: (on) =>
                controller.setRange(widget.surah.id, _first, _last, on: on),
            itemBuilder: (_) => [
              PopupMenuItem(value: true, child: Text(l10n.memorizeMarkRange)),
              PopupMenuItem(value: false, child: Text(l10n.memorizeClearRange)),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      Text(l10n.memorizeFrom),
                      picker(
                        _first,
                        (v) => setState(() {
                          _first = v;
                          if (_last < v) _last = v;
                        }),
                        from: 1,
                        to: verseCount,
                      ),
                      Text(l10n.memorizeTo),
                      picker(
                        _last,
                        (v) => setState(() => _last = v),
                        from: _first,
                        to: verseCount,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SegmentedButton<MemorizeView>(
                    key: const Key('memorize-view'),
                    showSelectedIcon: false,
                    segments: [
                      ButtonSegment(
                        value: MemorizeView.full,
                        label: Text(l10n.memorizeShow),
                      ),
                      ButtonSegment(
                        value: MemorizeView.firstWord,
                        label: Text(l10n.memorizeFirstWord),
                      ),
                      ButtonSegment(
                        value: MemorizeView.hidden,
                        label: Text(l10n.memorizeHide),
                      ),
                    ],
                    selected: {_view},
                    onSelectionChanged: (value) => setState(() {
                      _view = value.single;
                      _revealed.clear();
                    }),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(child: Text(l10n.memorizeRepeatEach)),
                      IconButton(
                        onPressed: _target > 1
                            ? () => setState(() => _target--)
                            : null,
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                      Text(
                        numbers.format(_target),
                        style: theme.textTheme.titleMedium,
                      ),
                      IconButton(
                        onPressed: _target < 50
                            ? () => setState(() => _target++)
                            : null,
                        icon: const Icon(Icons.add_circle_outline),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          for (final ayah in all)
            Builder(
              builder: (context) {
                // The first verse of each surah opens with the basmala in this
                // text; the Mushaf shows it apart, and so does this screen.
                final basmala = widget.edition.surahs.first.verses.first;
                final raw = widget.surah.verses[ayah - 1];
                final text =
                    widget.surah.id > 1 &&
                        ayah == 1 &&
                        raw.startsWith('$basmala ')
                    ? raw.substring(basmala.length + 1)
                    : raw;
                final done = memorized.contains(ayah);
                final count = _counts[ayah] ?? 0;
                final shown =
                    _view == MemorizeView.full || _revealed.contains(ayah);
                return Card(
                  key: ValueKey('memorize-verse-$ayah'),
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  color: done ? scheme.primaryContainer : null,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: scheme.secondaryContainer,
                              foregroundColor: scheme.onSecondaryContainer,
                              child: Text(
                                numbers.format(ayah),
                                style: theme.textTheme.labelSmall,
                              ),
                            ),
                            const Spacer(),
                            FilterChip(
                              key: ValueKey('memorized-$ayah'),
                              label: Text(l10n.memorizeDone),
                              selected: done,
                              onSelected: (_) =>
                                  controller.toggle(widget.surah.id, ayah),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        InkWell(
                          borderRadius: AppRadii.mdAll,
                          onTap: _view == MemorizeView.full
                              ? null
                              : () => setState(() {
                                  _revealed.contains(ayah)
                                      ? _revealed.remove(ayah)
                                      : _revealed.add(ayah);
                                }),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.sm,
                            ),
                            child: shown
                                ? Text(
                                    text,
                                    textDirection: TextDirection.rtl,
                                    style: const TextStyle(
                                      fontFamily: AppTheme.quranFontFamily,
                                      fontSize: 24,
                                      height: 1.9,
                                    ),
                                  )
                                : Column(
                                    children: [
                                      if (_view == MemorizeView.firstWord)
                                        Text(
                                          '${firstWordOf(text)} …',
                                          textDirection: TextDirection.rtl,
                                          style: const TextStyle(
                                            fontFamily:
                                                AppTheme.quranFontFamily,
                                            fontSize: 24,
                                            height: 1.9,
                                          ),
                                        ),
                                      Text(
                                        l10n.memorizeTapToReveal,
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: scheme.onSurfaceVariant,
                                            ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        FilledButton.tonalIcon(
                          key: ValueKey('memorize-count-$ayah'),
                          onPressed: () => _count(ayah),
                          icon: Icon(
                            count >= _target
                                ? Icons.check_circle
                                : Icons.replay,
                          ),
                          label: Text(
                            l10n.memorizeRepeated(
                              numbers.format(count),
                              numbers.format(_target),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
