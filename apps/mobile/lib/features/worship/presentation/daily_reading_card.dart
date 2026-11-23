import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show NumberFormat;
import 'package:material_ui/material_ui.dart';

import '../../../core/localization/l10n_extension.dart';
import '../../../core/routing/app_routes.dart';
import '../../quran/data/mushaf_edition.dart';
import '../../quran/domain/quran_search_text.dart';
import '../../quran/domain/quran_storage_contracts.dart';
import '../data/daily_reading_plan.dart';

class DailyReadingCard extends StatelessWidget {
  const DailyReadingCard({super.key});

  Future<void> _open(BuildContext context) async {
    final verse = await showModalBottomSheet<AyahRef>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => const _DailyReadingSheet(),
    );
    if (verse == null || !context.mounted) return;
    context.go(
      Uri(
        path: AppRoutes.quran,
        queryParameters: {'surah': '${verse.surah}', 'ayah': '${verse.ayah}'},
      ).toString(),
    );
  }

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: const Icon(Icons.menu_book_outlined),
      title: Text(context.l10n.dailyReadingTitle),
      trailing: const Icon(Icons.arrow_forward_ios),
      onTap: () => _open(context),
    ),
  );
}

class _DailyReadingSheet extends ConsumerStatefulWidget {
  const _DailyReadingSheet();

  @override
  ConsumerState<_DailyReadingSheet> createState() => _DailyReadingSheetState();
}

class _DailyReadingSheetState extends ConsumerState<_DailyReadingSheet> {
  final _paceForm = GlobalKey<FormState>();
  bool _saving = false;
  bool _saveFailed = false;

  Future<void> _save(Future<void> Function() update) async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _saveFailed = false;
    });
    try {
      await update();
    } catch (_) {
      if (mounted) setState(() => _saveFailed = true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _editPace(int current, NumberFormat numbers) async {
    final l10n = context.l10n;
    final pace = await showDialog<int>(
      context: context,
      builder: (dialog) {
        int? pages;
        return AlertDialog(
          title: Text(l10n.dailyReadingEdit),
          content: Form(
            key: _paceForm,
            child: TextFormField(
              initialValue: numbers.format(current),
              autofocus: true,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: l10n.dailyReadingPaceLabel,
              ),
              validator: (value) {
                final input = int.tryParse(quranSearchText(value ?? ''));
                if (input == null ||
                    input < 1 ||
                    input > DailyReadingPlanController.totalPages) {
                  return l10n.dailyReadingPaceRange;
                }
                pages = input;
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialog).pop(),
              child: Text(MaterialLocalizations.of(dialog).cancelButtonLabel),
            ),
            FilledButton(
              onPressed: () {
                if (_paceForm.currentState!.validate()) {
                  Navigator.of(dialog).pop(pages);
                }
              },
              child: Text(l10n.dailyReadingSave),
            ),
          ],
        );
      },
    );
    if (pace == null || !mounted) return;
    await _save(
      () => ref.read(dailyReadingPlanProvider.notifier).setPace(pace),
    );
  }

  @override
  Widget build(BuildContext context) {
    final plan = ref.watch(dailyReadingPlanProvider);
    final edition = ref.watch(mushafEditionProvider).asData?.value;
    final controller = ref.read(dailyReadingPlanProvider.notifier);
    const total = DailyReadingPlanController.totalPages;
    final l10n = context.l10n;
    final numbers = NumberFormat.decimalPattern(
      Localizations.localeOf(context).languageCode,
    );
    final completed = plan.pagesRead == total;
    final progress = l10n.dailyReadingProgress(
      numbers.format(plan.pagesRead),
      numbers.format(total),
    );
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.dailyReadingTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Text(progress),
            LinearProgressIndicator(value: plan.pagesRead / total),
            const SizedBox(height: 12),
            if (completed)
              Text(l10n.dailyReadingCompleted)
            else ...[
              Text(
                l10n.dailyReadingRange(
                  numbers.format(plan.pagesRead + 1),
                  numbers.format(plan.endPage(total)),
                ),
              ),
              Text(
                l10n.dailyReadingRemaining(
                  numbers.format(plan.remainingSessions(total)),
                ),
              ),
            ],
            if (_saveFailed) Text(l10n.localSaveFailed),
            Wrap(
              spacing: 8,
              children: [
                TextButton(
                  onPressed: _saving
                      ? null
                      : () => _editPace(plan.pagesPerSession, numbers),
                  child: Text(l10n.dailyReadingEdit),
                ),
                if (completed)
                  FilledButton(
                    onPressed: _saving
                        ? null
                        : () => _save(controller.startAgain),
                    child: Text(l10n.dailyReadingRestart),
                  )
                else ...[
                  FilledButton(
                    onPressed: edition == null || _saving
                        ? null
                        : () {
                            final index = edition.pageStarts[plan.pagesRead];
                            Navigator.of(context)
                                .pop(edition.verses[index].ref);
                          },
                    child: Text(l10n.dailyReadingOpen),
                  ),
                  OutlinedButton(
                    onPressed: _saving
                        ? null
                        : () => _save(controller.completeSession),
                    child: Text(l10n.dailyReadingMarkRead),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
