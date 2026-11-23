import 'package:material_ui/material_ui.dart';

import '../../../core/content/feature_preview.dart';
import '../../../core/localization/l10n_extension.dart';
import '../../../core/routing/app_sections.dart';
import '../../../core/widgets/hub_scaffold.dart';
import 'cairo_radio_card.dart';
import 'daily_reading_card.dart';

/// Worship tab root: prayer times, Qibla, adhkar.
class WorshipHubScreen extends StatelessWidget {
  const WorshipHubScreen({super.key});

  static const List<AppSection> sections = [
    AppSection.prayerTimes,
    AppSection.qibla,
    AppSection.adhkar,
  ];

  @override
  Widget build(BuildContext context) => HubScaffold(
    title: context.l10n.navWorship,
    intro: context.l10n.worshipHubIntro,
    sections: sections,
    footer: const Padding(
      padding: EdgeInsets.only(top: 12),
      child: Column(
        children: [
          CairoRadioCard(),
          if (featurePreviewEnabled) DailyReadingCard(),
        ],
      ),
    ),
  );
}
