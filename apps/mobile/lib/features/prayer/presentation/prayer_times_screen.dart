import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/content/feature_preview.dart';
import '../../../core/localization/l10n_extension.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/routing/app_sections.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/responsive_content.dart';
import '../../../core/widgets/section_detail_scaffold.dart';
import '../../worship/application/worship_location.dart';
import '../../worship/presentation/worship_location_picker.dart';
import '../application/prayer_preferences.dart';
import '../domain/prayer_schedule.dart';
import 'next_prayer_card.dart';
import 'prayer_method_tile.dart';

class PrayerTimesScreen extends StatelessWidget {
  const PrayerTimesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (AppSection.prayerTimes.status.isGated && !managedReleaseEnabled) {
      return const SectionDetailScaffold(section: AppSection.prayerTimes);
    }
    return const _PrayerTimes();
  }
}

class _PrayerTimes extends ConsumerStatefulWidget {
  const _PrayerTimes();

  @override
  ConsumerState<_PrayerTimes> createState() => _PrayerTimesState();
}

class _PrayerTimesState extends ConsumerState<_PrayerTimes> {
  late final Timer _timer;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (TickerMode.valuesOf(context).enabled) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Future<void> _setHanafi(bool value) async {
    setState(() => _saving = true);
    try {
      await ref.read(hanafiAsrProvider.notifier).select(value);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.localSaveFailed)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final location = ref.watch(worshipLocationProvider);
    final place = ref.watch(prayerPlaceProvider);
    final now = DateTime.now();
    final hanafi = ref.watch(hanafiAsrProvider);
    final schedule = place == null
        ? null
        : PrayerSchedule.calculate(place: place, now: now, hanafi: hanafi);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final clock = DateFormat.jm(locale);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.sectionPrayerTimesTitle),
        actions: [
          TextButton.icon(
            onPressed: () => context.push(AppRoutes.qibla),
            icon: const Icon(Icons.explore_outlined),
            label: Text(l10n.sectionQiblaTitle),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverResponsiveContent(
            sliver: SliverList.list(
              children: [
                const WorshipLocationPicker(),
                const SizedBox(height: AppSpacing.md),
                if (AppSection.prayerTimes.status.isGated)
                  Text(l10n.prayerPreview, style: theme.textTheme.bodySmall),
                if (schedule != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  NextPrayerCard(
                    schedule: schedule,
                    now: now,
                    location:
                        location.place?.label(
                          Localizations.localeOf(context).languageCode,
                        ) ??
                        l10n.deviceLocation,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Card(
                    child: Column(
                      children: [
                        ListTile(
                          title: Text(
                            DateFormat.yMMMMEEEEd(locale)
                                .format(schedule.today.first.time),
                          ),
                        ),
                        for (final entry in schedule.today)
                          ListTile(
                            selected: entry == schedule.next,
                            selectedTileColor:
                                theme.colorScheme.primaryContainer,
                            leading: Icon(
                              entry.slot == PrayerSlot.sunrise
                                  ? Icons.wb_sunny_outlined
                                  : Icons.circle,
                              size: entry.slot == PrayerSlot.sunrise ? 19 : 8,
                            ),
                            title: Text(prayerName(entry.slot, l10n)),
                            trailing: Text(clock.format(entry.time)),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          PrayerMethodTile(place: place!),
                          const Divider(),
                          Text(
                            l10n.prayerAsrCalculation,
                            style: theme.textTheme.titleSmall,
                          ),
                          Wrap(
                            spacing: AppSpacing.sm,
                            children: [
                              ChoiceChip(
                                label: Text(l10n.asrStandard),
                                selected: !hanafi,
                                onSelected: _saving
                                    ? null
                                    : (_) => _setHanafi(false),
                              ),
                              ChoiceChip(
                                label: Text(l10n.asrHanafi),
                                selected: hanafi,
                                onSelected: _saving
                                    ? null
                                    : (_) => _setHanafi(true),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
