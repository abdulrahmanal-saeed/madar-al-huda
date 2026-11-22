import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/localization/l10n_extension.dart';
import '../../../core/routing/app_sections.dart';
import '../../../core/widgets/hub_scaffold.dart';

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
    footer: Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Card(
        child: ListTile(
          leading: const Icon(Icons.radio),
          title: Text(context.l10n.radioTitle),
          subtitle: Text(context.l10n.radioOpen),
          trailing: const Icon(Icons.open_in_new),
          onTap: () async {
            try {
              if (await launchUrl(
                Uri.https('misrquran.gov.eg'),
                mode: LaunchMode.externalApplication,
              )) {
                return;
              }
            } on Exception {
              // Some devices have no browser activity available.
            }
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(context.l10n.radioOpenFailed)),
              );
            }
          },
        ),
      ),
    ),
  );
}
