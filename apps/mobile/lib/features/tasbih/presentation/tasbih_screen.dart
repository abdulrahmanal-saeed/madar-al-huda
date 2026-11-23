import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show NumberFormat;
import 'package:material_ui/material_ui.dart';

import '../../../core/localization/l10n_extension.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../application/tasbih_controller.dart';

/// A large tap target that counts remembrance, with a light vibration on
/// every count and a stronger one when the goal is reached.
class TasbihScreen extends ConsumerWidget {
  const TasbihScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final language = Localizations.localeOf(context).languageCode;
    final number = NumberFormat.decimalPattern(language).format;
    final state = ref.watch(tasbihProvider);
    final controller = ref.read(tasbihProvider.notifier);
    final phrase = tasbihPhrases[state.phrase];
    final progress = state.goal == 0
        ? null
        : (state.count / state.goal).clamp(0.0, 1.0);

    void count() {
      final reached = controller.increment();
      if (reached) {
        HapticFeedback.heavyImpact();
        SemanticsService.sendAnnouncement(
          View.of(context),
          l10n.tasbihDone,
          Directionality.of(context),
        );
      } else {
        HapticFeedback.selectionClick();
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tasbihTitle),
        actions: [
          IconButton(
            key: const ValueKey('tasbih-reset'),
            tooltip: l10n.tasbihReset,
            onPressed: state.count == 0 ? null : controller.reset,
            icon: const Icon(Icons.restart_alt),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 56,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                children: [
                  for (final (index, item) in tasbihPhrases.indexed)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(
                        end: AppSpacing.sm,
                      ),
                      child: ChoiceChip(
                        label: Text(
                          item == null
                              ? l10n.tasbihFree
                              : (language == 'ar' ? item.ar : item.en),
                        ),
                        selected: state.phrase == index,
                        onSelected: (_) => controller.choosePhrase(index),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: SegmentedButton<int>(
                key: const ValueKey('tasbih-goal'),
                showSelectedIcon: false,
                segments: [
                  for (final goal in tasbihGoals)
                    ButtonSegment(
                      value: goal,
                      label: Text(goal == 0 ? l10n.tasbihNoGoal : number(goal)),
                    ),
                ],
                selected: {state.goal},
                onSelectionChanged: (selection) =>
                    controller.chooseGoal(selection.first),
              ),
            ),
            Expanded(
              child: Semantics(
                button: true,
                label: l10n.tasbihTap,
                value: l10n.tasbihCount(number(state.count)),
                excludeSemantics: true,
                child: InkWell(
                  key: const ValueKey('tasbih-tap'),
                  onTap: count,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (phrase != null)
                          Padding(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            child: Text(
                              phrase.ar,
                              textAlign: TextAlign.center,
                              textDirection: TextDirection.rtl,
                              style: const TextStyle(
                                fontFamily: AppTheme.quranFontFamily,
                                fontSize: 30,
                                height: 1.8,
                              ),
                            ),
                          ),
                        SizedBox.square(
                          dimension: 220,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox.expand(
                                child: CircularProgressIndicator(
                                  value: progress ?? 0,
                                  strokeWidth: 10,
                                  backgroundColor: scheme.surfaceContainerHigh,
                                  color: state.reachedGoal
                                      ? scheme.secondary
                                      : scheme.primary,
                                ),
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    number(state.count),
                                    key: const ValueKey('tasbih-count'),
                                    style: theme.textTheme.displayLarge
                                        ?.copyWith(
                                          fontFeatures: const [
                                            FontFeature.tabularFigures(),
                                          ],
                                        ),
                                  ),
                                  if (state.goal > 0)
                                    Text(
                                      state.reachedGoal
                                          ? l10n.tasbihDone
                                          : '/ ${number(state.goal)}',
                                      style: theme.textTheme.titleMedium,
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          l10n.tasbihTap,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text(
                l10n.tasbihToday(number(state.today)),
                key: const ValueKey('tasbih-today'),
                style: theme.textTheme.bodyLarge,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
