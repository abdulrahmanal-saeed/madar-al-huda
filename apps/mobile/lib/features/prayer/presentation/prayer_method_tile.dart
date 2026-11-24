import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/localization/l10n_extension.dart';
import '../../worship/application/worship_location.dart';
import '../domain/prayer_method.dart';
import '../domain/prayer_schedule.dart';

/// Shows the method in use and lets the user pick another one.
class PrayerMethodTile extends ConsumerWidget {
  const PrayerMethodTile({required this.place, super.key});

  final PrayerPlace place;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final chosen = ref.watch(prayerMethodProvider);
    final name = l10n.prayerMethodName(place.method.name);
    return ListTile(
      key: const Key('prayer-method'),
      contentPadding: EdgeInsets.zero,
      title: Text(l10n.prayerCalculationMethod),
      subtitle: Text(
        chosen == null ? '$name · ${l10n.prayerMethodAuto}' : name,
      ),
      trailing: const Icon(Icons.expand_more),
      onTap: () => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: true,
        builder: (sheet) => _MethodSheet(chosen: chosen),
      ),
    );
  }
}

class _MethodSheet extends ConsumerWidget {
  const _MethodSheet({required this.chosen});

  final PrayerMethod? chosen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final place = ref.watch(worshipLocationProvider).place;
    final automatic = place == null
        ? null
        : PrayerMethod.forCountry(place.country);

    Future<void> select(PrayerMethod? method) async {
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      try {
        await ref.read(prayerMethodProvider.notifier).select(method);
      } on Object {
        messenger.showSnackBar(SnackBar(content: Text(l10n.localSaveFailed)));
      }
    }

    Widget option({
      required String title,
      String? subtitle,
      required bool selected,
      required VoidCallback onTap,
    }) => ListTile(
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle),
      selected: selected,
      trailing: selected
          ? const Icon(Icons.check_circle)
          : const Icon(Icons.circle_outlined),
      onTap: onTap,
    );

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      builder: (context, scroll) => ListView(
        controller: scroll,
        children: [
          ListTile(
            title: Text(
              l10n.prayerMethodPick,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          option(
            title: l10n.prayerMethodAuto,
            subtitle: automatic == null
                ? null
                : l10n.prayerMethodName(automatic.name),
            selected: chosen == null,
            onTap: () => select(null),
          ),
          const Divider(),
          for (final method in PrayerMethod.values)
            option(
              title: l10n.prayerMethodName(method.name),
              selected: chosen == method,
              onTap: () => select(method),
            ),
        ],
      ),
    );
  }
}
