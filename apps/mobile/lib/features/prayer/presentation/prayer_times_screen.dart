import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/content/feature_preview.dart';
import '../../../core/localization/app_locales.dart';
import '../../../core/localization/l10n_extension.dart';
import '../../../core/routing/app_sections.dart';
import '../../../core/storage/storage_providers.dart';
import '../../../core/widgets/section_detail_scaffold.dart';
import '../../worship/application/worship_location.dart';
import '../../worship/presentation/worship_location_picker.dart';
import '../domain/prayer_schedule.dart';

class PrayerTimesScreen extends StatelessWidget {
  const PrayerTimesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (AppSection.prayerTimes.status.isGated && !featurePreviewEnabled) {
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
  late bool _hanafi;
  bool _saving = false;
  static const hanafiKey = 'worship.hanafiAsr';

  @override
  void initState() {
    super.initState();
    _hanafi = ref.read(keyValueStoreProvider).getBool(hanafiKey) ?? false;
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
      await ref.read(keyValueStoreProvider).setBool(hanafiKey, value: value);
      if (mounted) setState(() => _hanafi = value);
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
    final location = ref.watch(worshipLocationProvider);
    final country = location.country;
    final point = location.point;
    final now = DateTime.now();
    final schedule = point == null || country == null
        ? null
        : PrayerSchedule.calculate(
            location: point,
            country: country,
            now: now,
            hanafi: _hanafi,
          );
    final locale = Localizations.localeOf(context).toLanguageTag();
    final format = DateFormat.Hm(locale);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.sectionPrayerTimesTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const WorshipLocationPicker(),
            if (AppSection.prayerTimes.status.isGated) Text(l10n.prayerPreview),
            if (schedule != null) ...[
              const SizedBox(height: 16),
              Text(
                DateFormat.yMMMMEEEEd(locale).format(schedule.today.first.time),
              ),
              Text(
                country == WorshipCountry.egypt
                    ? l10n.prayerEgyptMethod
                    : l10n.prayerDubaiMethod,
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.hanafiAsr),
                subtitle: Text(_hanafi ? l10n.asrHanafi : l10n.asrStandard),
                value: _hanafi,
                onChanged: _saving ? null : _setHanafi,
              ),
              Card(
                child: ListTile(
                  title: Text(l10n.nextPrayer),
                  subtitle: Text(_name(schedule.next.slot, l10n)),
                  trailing: Text(format.format(schedule.next.time)),
                ),
              ),
              for (final entry in schedule.today)
                ListTile(
                  title: Text(_name(entry.slot, l10n)),
                  trailing: Text(format.format(entry.time)),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

String _name(PrayerSlot slot, AppLocalizations l10n) => switch (slot) {
  PrayerSlot.fajr => l10n.prayerFajr,
  PrayerSlot.sunrise => l10n.prayerSunrise,
  PrayerSlot.dhuhr => l10n.prayerDhuhr,
  PrayerSlot.asr => l10n.prayerAsr,
  PrayerSlot.maghrib => l10n.prayerMaghrib,
  PrayerSlot.isha => l10n.prayerIsha,
};
