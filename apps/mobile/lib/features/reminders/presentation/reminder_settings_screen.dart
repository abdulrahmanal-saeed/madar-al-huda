import 'adhan_voice_picker.dart';

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/localization/l10n_extension.dart';
import '../../../core/localization/numbers.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/responsive_content.dart';
import '../../worship/application/worship_location.dart';
import '../application/reminder_settings_controller.dart';
import '../data/reminder_scheduler.dart';
import '../domain/reminder_settings.dart';

/// Opt-in reminders: prayer times, remembrance and supplications.
class ReminderSettingsScreen extends ConsumerStatefulWidget {
  const ReminderSettingsScreen({super.key});

  @override
  ConsumerState<ReminderSettingsScreen> createState() =>
      _ReminderSettingsScreenState();
}

class _ReminderSettingsScreenState
    extends ConsumerState<ReminderSettingsScreen> {
  ReminderPermissions? _permissions;
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    unawaited(_refreshPermissions());
    // Returning from Android settings may have changed a permission.
    _lifecycle = AppLifecycleListener(onResume: _refreshPermissions);
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  Future<void> _refreshPermissions() async {
    final permissions = await ref.read(reminderSchedulerProvider).permissions();
    if (mounted) setState(() => _permissions = permissions);
  }

  /// Saves [next]; the first reminder turned on asks for permission.
  Future<void> _change(ReminderSettings next) async {
    final current = ref.read(reminderSettingsProvider);
    final controller = ref.read(reminderSettingsProvider.notifier);
    if (next.anyEnabled &&
        (!current.anyEnabled || _permissions?.notifications == false)) {
      await ref.read(reminderSchedulerProvider).requestNotifications();
      await _refreshPermissions();
    }
    try {
      await controller.update(next);
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.localSaveFailed)));
      }
    }
  }

  String _clock(BuildContext context, int minutes) =>
      TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60).format(context);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final settings = ref.watch(reminderSettingsProvider);
    final location = ref.watch(worshipLocationProvider);
    final language = Localizations.localeOf(context).languageCode;
    final number = decimalFormat(language).format;
    final permissions = _permissions;

    Widget toggle({
      required String title,
      required String subtitle,
      required bool value,
      required ReminderSettings Function(bool) apply,
      Key? key,
    }) => SwitchListTile(
      key: key,
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: (on) => _change(apply(on)),
    );

    Widget section(String title, List<Widget> children) => Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          Card(child: Column(children: children)),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.remindersTitle)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
        children: [
          ResponsiveContent(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.md),
                Text(l10n.remindersIntro, style: theme.textTheme.bodyMedium),
                if (location.point == null)
                  _Notice(
                    icon: Icons.location_off_outlined,
                    text: l10n.remindersNeedsLocation,
                  ),
                if (settings.anyEnabled &&
                    permissions != null &&
                    !permissions.notifications)
                  _Notice(
                    icon: Icons.notifications_off_outlined,
                    text: l10n.remindersPermissionDenied,
                  ),
                if (settings.anyEnabled &&
                    permissions != null &&
                    permissions.notifications &&
                    !permissions.exactAlarms)
                  _Notice(
                    icon: Icons.alarm_outlined,
                    text: l10n.remindersExactAlarm,
                    action: TextButton(
                      onPressed: () async {
                        await ref
                            .read(reminderSchedulerProvider)
                            .requestExactAlarms();
                        await _refreshPermissions();
                      },
                      child: Text(l10n.remindersExactAlarmAllow),
                    ),
                  ),
                if (settings.anyEnabled)
                  _Notice(
                    icon: Icons.volume_up_outlined,
                    text: Localizations.localeOf(context).languageCode == 'ar'
                        ? 'التذكيرات تستخدم مستوى صوت المنبّه وتحترم إعدادات عدم الإزعاج. السماح بالمنبّهات الدقيقة مطلوب لبدء التسجيل الكامل في الخلفية.'
                        : 'Reminders use alarm volume and follow Do Not Disturb settings. Exact alarm access lets full recordings start in the background.',
                  ),
                section(l10n.remindersPrayerSection, [
                  toggle(
                    title: Localizations.localeOf(context).languageCode == 'ar'
                        ? 'إشعار الصلاة الثابت'
                        : 'Persistent prayer countdown',
                    subtitle:
                        Localizations.localeOf(context).languageCode == 'ar'
                        ? 'يعرض المدينة والصلاة القادمة والوقت المتبقي'
                        : 'Show the city, next prayer and time remaining',
                    value: settings.prayerStatus,
                    apply: (on) => settings.copyWith(prayerStatus: on),
                  ),
                  toggle(
                    key: const ValueKey('reminder-adhan'),
                    title: l10n.remindersAdhan,
                    subtitle: l10n.remindersAdhanSubtitle,
                    value: settings.adhan,
                    apply: (on) => settings.copyWith(adhan: on),
                  ),
                  AdhanVoicePicker(
                    value: settings.adhanVoice,
                    onChanged: (voice) =>
                        _change(settings.copyWith(adhanVoice: voice)),
                  ),
                  toggle(
                    title: l10n.remindersBeforePrayer,
                    subtitle: l10n.remindersBeforePrayerSubtitle(
                      number(settings.beforePrayerMinutes),
                    ),
                    value: settings.beforePrayer,
                    apply: (on) => settings.copyWith(beforePrayer: on),
                  ),
                ]),
                section(l10n.remindersAdhkarSection, [
                  toggle(
                    title: l10n.remindersMorning,
                    subtitle: l10n.remindersMorningSubtitle,
                    value: settings.morning,
                    apply: (on) => settings.copyWith(morning: on),
                  ),
                  toggle(
                    title: l10n.remindersEvening,
                    subtitle: l10n.remindersEveningSubtitle,
                    value: settings.evening,
                    apply: (on) => settings.copyWith(evening: on),
                  ),
                  toggle(
                    title: l10n.remindersAfterPrayer,
                    subtitle: l10n.remindersAfterPrayerSubtitle,
                    value: settings.afterPrayer,
                    apply: (on) => settings.copyWith(afterPrayer: on),
                  ),
                  toggle(
                    title: l10n.remindersBedtime,
                    subtitle: l10n.remindersBedtimeSubtitle(
                      _clock(context, settings.bedtimeMinutes),
                    ),
                    value: settings.bedtime,
                    apply: (on) => settings.copyWith(bedtime: on),
                  ),
                  ListTile(
                    leading: const Icon(Icons.bedtime_outlined),
                    title: Text(l10n.remindersBedtimeChange),
                    trailing: Text(_clock(context, settings.bedtimeMinutes)),
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay(
                          hour: settings.bedtimeMinutes ~/ 60,
                          minute: settings.bedtimeMinutes % 60,
                        ),
                      );
                      if (picked == null) return;
                      await _change(
                        ref
                            .read(reminderSettingsProvider)
                            .copyWith(
                              bedtimeMinutes: picked.hour * 60 + picked.minute,
                            ),
                      );
                    },
                  ),
                  toggle(
                    title: l10n.remindersKahf,
                    subtitle: l10n.remindersKahfSubtitle(
                      _clock(context, 10 * 60),
                    ),
                    value: settings.kahf,
                    apply: (on) => settings.copyWith(kahf: on),
                  ),
                ]),
                section(l10n.remindersRamadanSection, [
                  toggle(
                    key: const ValueKey('reminder-suhoor'),
                    title: l10n.remindersSuhoor,
                    subtitle: l10n.remindersSuhoorSubtitle,
                    value: settings.suhoor,
                    apply: (on) => settings.copyWith(suhoor: on),
                  ),
                  toggle(
                    title: l10n.remindersIftar,
                    subtitle: l10n.remindersIftarSubtitle,
                    value: settings.iftar,
                    apply: (on) => settings.copyWith(iftar: on),
                  ),
                ]),
                section(l10n.remindersFastingSection, [
                  toggle(
                    key: const ValueKey('reminder-fast-monthu'),
                    title: l10n.remindersFastMonThu,
                    subtitle: l10n.remindersFastingSubtitle(
                      _clock(context, 21 * 60),
                    ),
                    value: settings.fastMonThu,
                    apply: (on) => settings.copyWith(fastMonThu: on),
                  ),
                  toggle(
                    title: l10n.remindersFastWhiteDays,
                    subtitle: l10n.remindersFastingSubtitle(
                      _clock(context, 21 * 60),
                    ),
                    value: settings.fastWhiteDays,
                    apply: (on) => settings.copyWith(fastWhiteDays: on),
                  ),
                  toggle(
                    title: l10n.remindersFastOccasions,
                    subtitle: l10n.remindersFastingSubtitle(
                      _clock(context, 21 * 60),
                    ),
                    value: settings.fastOccasions,
                    apply: (on) => settings.copyWith(fastOccasions: on),
                  ),
                ]),
                section(l10n.remindersDuaSection, [
                  toggle(
                    title: l10n.remindersDailyDua,
                    subtitle: l10n.remindersDailyDuaSubtitle(
                      _clock(context, 8 * 60),
                    ),
                    value: settings.dailyDua,
                    apply: (on) => settings.copyWith(dailyDua: on),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.sm,
                      AppSpacing.lg,
                      AppSpacing.lg,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          l10n.remindersDuaEvery,
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        SegmentedButton<int>(
                          key: const ValueKey('reminder-dua-every'),
                          showSelectedIcon: false,
                          segments: [
                            for (final hours in ReminderSettings.duaIntervals)
                              ButtonSegment(
                                value: hours,
                                label: Text(
                                  hours == 0
                                      ? l10n.remindersDuaOff
                                      : l10n.remindersDuaHours(number(hours)),
                                ),
                              ),
                          ],
                          selected: {settings.duaEveryHours},
                          onSelectionChanged: (selection) => _change(
                            settings.copyWith(duaEveryHours: selection.first),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          l10n.remindersQuietHours(
                            _clock(context, settings.quietStartMinutes),
                            _clock(context, settings.quietEndMinutes),
                          ),
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.icon, required this.text, this.action});

  final IconData icon;
  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Card(
        color: scheme.secondaryContainer,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Icon(icon, color: scheme.onSecondaryContainer),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(color: scheme.onSecondaryContainer),
                ),
              ),
              ?action,
            ],
          ),
        ),
      ),
    );
  }
}
