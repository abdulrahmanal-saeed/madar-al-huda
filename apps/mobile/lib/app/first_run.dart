import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../core/localization/app_locales.dart';
import '../core/localization/l10n_extension.dart';
import '../core/storage/key_value_store.dart';
import '../core/storage/storage_providers.dart';
import '../core/theme/app_tokens.dart';
import '../core/theme/brand_colors.dart';
import '../features/reminders/application/reminder_settings_controller.dart';
import '../features/reminders/data/reminder_scheduler.dart';
import '../features/reminders/domain/reminder_settings.dart';
import '../features/settings/application/settings_controller.dart';
import '../features/settings/domain/app_settings.dart';
import '../features/worship/application/worship_location.dart';

/// Set once the first-run steps are finished or skipped.
const firstRunDoneKey = 'app.firstRunDone.v1';

bool firstRunDone(KeyValueStore store) =>
    store.getBool(firstRunDoneKey) ?? false;

/// The first launch, right after the splash: language and theme, then why
/// the app asks for notifications and location (one screen each), then
/// which reminders to turn on.
class FirstRunFlow extends ConsumerStatefulWidget {
  const FirstRunFlow({required this.onDone, super.key});

  final VoidCallback onDone;

  @override
  ConsumerState<FirstRunFlow> createState() => _FirstRunFlowState();
}

enum _Step { look, notifications, location, reminders }

/// The reminders offered on the last step, with their switches.
typedef _ReminderChoice = ({
  String Function(AppLocalizations l10n) title,
  IconData icon,
  bool Function(ReminderSettings s) value,
  ReminderSettings Function(ReminderSettings s, bool on) apply,
});

final List<_ReminderChoice> _reminders = [
  (
    title: (l) => l.remindersAdhan,
    icon: Icons.mosque_outlined,
    value: (s) => s.adhan,
    apply: (s, on) => s.copyWith(adhan: on),
  ),
  (
    title: (l) => l.remindersBeforePrayer,
    icon: Icons.alarm_outlined,
    value: (s) => s.beforePrayer,
    apply: (s, on) => s.copyWith(beforePrayer: on),
  ),
  (
    title: (l) => l.remindersMorning,
    icon: Icons.wb_twilight_outlined,
    value: (s) => s.morning,
    apply: (s, on) => s.copyWith(morning: on),
  ),
  (
    title: (l) => l.remindersEvening,
    icon: Icons.nights_stay_outlined,
    value: (s) => s.evening,
    apply: (s, on) => s.copyWith(evening: on),
  ),
  (
    title: (l) => l.remindersAfterPrayer,
    icon: Icons.self_improvement_outlined,
    value: (s) => s.afterPrayer,
    apply: (s, on) => s.copyWith(afterPrayer: on),
  ),
  (
    title: (l) => l.remindersBedtime,
    icon: Icons.bedtime_outlined,
    value: (s) => s.bedtime,
    apply: (s, on) => s.copyWith(bedtime: on),
  ),
  (
    title: (l) => l.remindersKahf,
    icon: Icons.menu_book_outlined,
    value: (s) => s.kahf,
    apply: (s, on) => s.copyWith(kahf: on),
  ),
  (
    title: (l) => l.remindersDailyDua,
    icon: Icons.volunteer_activism_outlined,
    value: (s) => s.dailyDua,
    apply: (s, on) => s.copyWith(dailyDua: on),
  ),
  (
    title: (l) => l.remindersFastMonThu,
    icon: Icons.event_available_outlined,
    value: (s) => s.fastMonThu,
    apply: (s, on) => s.copyWith(fastMonThu: on),
  ),
  (
    title: (l) => l.remindersFastWhiteDays,
    icon: Icons.brightness_3_outlined,
    value: (s) => s.fastWhiteDays,
    apply: (s, on) => s.copyWith(fastWhiteDays: on),
  ),
];

class _FirstRunFlowState extends ConsumerState<FirstRunFlow> {
  _Step _step = _Step.look;
  bool _busy = false;
  late ReminderSettings _choice = ref.read(reminderSettingsProvider);

  void _next() {
    if (_step == _Step.reminders) {
      unawaited(_finish());
      return;
    }
    setState(() => _step = _Step.values[_step.index + 1]);
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } on Object {
      // A refused or failed request never blocks the first run.
    }
    if (!mounted) return;
    setState(() => _busy = false);
    _next();
  }

  Future<void> _finish() async {
    setState(() => _busy = true);
    try {
      await ref.read(reminderSettingsProvider.notifier).update(_choice);
      if (_choice.anyEnabled) {
        final scheduler = ref.read(reminderSchedulerProvider);
        if (!(await scheduler.permissions()).notifications) {
          await scheduler.requestNotifications();
        }
      }
    } on Object {
      // Reminders stay editable from Settings if saving fails here.
    }
    try {
      await ref
          .read(keyValueStoreProvider)
          .setBool(firstRunDoneKey, value: true);
    } on Object {
      // Shown again next launch if the flag could not be saved.
    }
    if (mounted) widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final page = switch (_step) {
      _Step.look => _look(context),
      _Step.notifications => _explain(
        context,
        key: const Key('first-run-notifications'),
        icon: Icons.notifications_active_outlined,
        title: l10n.firstRunNotificationsTitle,
        body: l10n.firstRunNotificationsBody,
        allow: l10n.firstRunNotificationsAllow,
        onAllow: () => _run(
          () => ref.read(reminderSchedulerProvider).requestNotifications(),
        ),
      ),
      _Step.location => _explain(
        context,
        key: const Key('first-run-location'),
        icon: Icons.my_location_outlined,
        title: l10n.startupLocationTitle,
        body: l10n.firstRunLocationBody,
        allow: l10n.useLocation,
        onAllow: () =>
            _run(() => ref.read(worshipLocationProvider.notifier).useDevice()),
        onLater: () => _run(
          () =>
              ref.read(worshipLocationProvider.notifier).deferDeviceAtStartup(),
        ),
      ),
      _Step.reminders => _remindersPage(context),
    };
    return Material(
      color: scheme.surface,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                0,
              ),
              child: Row(
                children: [
                  for (final step in _Step.values)
                    Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: 4,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color: step.index <= _step.index
                              ? BrandColors.mutedGold
                              : scheme.outlineVariant,
                          borderRadius: AppRadii.xlAll,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: KeyedSubtree(key: ValueKey(_step), child: page),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _heading(BuildContext context, IconData icon, String title) {
    final theme = Theme.of(context);
    return Column(
      children: [
        DecoratedBox(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [BrandColors.primaryGreen, BrandColors.heroGreenEnd],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Icon(icon, size: 40, color: BrandColors.goldBright),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          title,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall,
        ),
      ],
    );
  }

  Widget _look(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final settings = ref.watch(settingsControllerProvider);
    final controller = ref.read(settingsControllerProvider.notifier);
    final arabic =
        settings.language == AppLanguage.arabic ||
        (settings.language == AppLanguage.system &&
            Localizations.localeOf(context).languageCode == 'ar');
    Widget option({
      required Key key,
      required String label,
      required IconData icon,
      required bool selected,
      required VoidCallback onTap,
    }) => Expanded(
      child: Card(
        key: key,
        clipBehavior: Clip.antiAlias,
        color: selected ? theme.colorScheme.primaryContainer : null,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.xlAll,
          side: BorderSide(
            color: selected
                ? BrandColors.mutedGold
                : theme.colorScheme.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
            child: Column(
              children: [
                Icon(icon),
                const SizedBox(height: AppSpacing.sm),
                Text(label, style: theme.textTheme.titleMedium),
              ],
            ),
          ),
        ),
      ),
    );
    final dark =
        settings.theme == AppThemePreference.dark ||
        (settings.theme == AppThemePreference.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);
    return _Page(
      action: FilledButton(
        key: const Key('first-run-next'),
        onPressed: _next,
        child: Text(l10n.firstRunNext),
      ),
      children: [
        _heading(context, Icons.tune, l10n.firstRunLookTitle),
        const SizedBox(height: AppSpacing.xl),
        Text(l10n.settingsLanguage, style: theme.textTheme.titleSmall),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            option(
              key: const Key('first-run-arabic'),
              label: l10n.languageArabic,
              icon: Icons.translate,
              selected: arabic,
              onTap: () => controller.setLanguage(AppLanguage.arabic),
            ),
            option(
              key: const Key('first-run-english'),
              label: l10n.languageEnglish,
              icon: Icons.language,
              selected: !arabic,
              onTap: () => controller.setLanguage(AppLanguage.english),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(l10n.settingsAppearance, style: theme.textTheme.titleSmall),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            option(
              key: const Key('first-run-light'),
              label: l10n.themeLight,
              icon: Icons.light_mode_outlined,
              selected: !dark,
              onTap: () => controller.setTheme(AppThemePreference.light),
            ),
            option(
              key: const Key('first-run-dark'),
              label: l10n.themeDark,
              icon: Icons.dark_mode_outlined,
              selected: dark,
              onTap: () => controller.setTheme(AppThemePreference.dark),
            ),
          ],
        ),
      ],
    );
  }

  Widget _explain(
    BuildContext context, {
    required Key key,
    required IconData icon,
    required String title,
    required String body,
    required String allow,
    required VoidCallback onAllow,
    VoidCallback? onLater,
  }) {
    final l10n = context.l10n;
    return _Page(
      key: key,
      action: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton(
            key: const Key('first-run-allow'),
            onPressed: _busy ? null : onAllow,
            child: Text(allow),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            key: const Key('first-run-later'),
            onPressed: _busy ? null : (onLater ?? _next),
            child: Text(l10n.startupLocationLater),
          ),
        ],
      ),
      children: [
        const SizedBox(height: AppSpacing.xl),
        _heading(context, icon, title),
        const SizedBox(height: AppSpacing.lg),
        Text(
          body,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.7),
        ),
      ],
    );
  }

  Widget _remindersPage(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final all = _reminders.every((r) => r.value(_choice));
    return _Page(
      key: const Key('first-run-reminders'),
      action: FilledButton(
        key: const Key('first-run-finish'),
        onPressed: _busy ? null : _next,
        child: Text(l10n.firstRunStart),
      ),
      children: [
        _heading(context, Icons.notifications_outlined, l10n.remindersTitle),
        const SizedBox(height: AppSpacing.sm),
        Text(
          l10n.firstRunRemindersBody,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.md),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: OutlinedButton.icon(
            key: const Key('first-run-select-all'),
            onPressed: () => setState(() {
              for (final reminder in _reminders) {
                _choice = reminder.apply(_choice, !all);
              }
            }),
            icon: Icon(all ? Icons.remove_done : Icons.done_all),
            label: Text(all ? l10n.firstRunClearAll : l10n.firstRunSelectAll),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Card(
          child: Column(
            children: [
              for (final reminder in _reminders)
                SwitchListTile(
                  secondary: Icon(reminder.icon),
                  title: Text(reminder.title(l10n)),
                  value: reminder.value(_choice),
                  onChanged: (on) =>
                      setState(() => _choice = reminder.apply(_choice, on)),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Page extends StatelessWidget {
  const _Page({required this.children, required this.action, super.key});

  final List<Widget> children;
  final Widget action;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Expanded(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.gutter),
          children: children,
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.gutter,
          0,
          AppSpacing.gutter,
          AppSpacing.lg,
        ),
        child: action,
      ),
    ],
  );
}

/// Shows [FirstRunFlow] above the app until it is finished once.
class FirstRunGate extends ConsumerStatefulWidget {
  const FirstRunGate({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<FirstRunGate> createState() => _FirstRunGateState();
}

class _FirstRunGateState extends ConsumerState<FirstRunGate> {
  late bool _show = !firstRunDone(ref.read(keyValueStoreProvider));

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      ExcludeSemantics(
        excluding: _show,
        child: IgnorePointer(ignoring: _show, child: widget.child),
      ),
      if (_show)
        // Its own overlay, since this sits above the app's navigator.
        Overlay(
          initialEntries: [
            OverlayEntry(
              builder: (_) =>
                  FirstRunFlow(onDone: () => setState(() => _show = false)),
            ),
          ],
        ),
    ],
  );
}
