import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/localization/l10n_extension.dart';
import '../../qibla/domain/qibla_bearing.dart';
import '../application/worship_location.dart';

class WorshipLocationPicker extends ConsumerWidget {
  const WorshipLocationPicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = ref.watch(worshipLocationProvider);
    final controller = ref.read(worshipLocationProvider.notifier);
    final l10n = context.l10n;
    final message = switch (location.problem) {
      LocationProblem.denied => l10n.locationDenied,
      LocationProblem.blocked => l10n.locationDenied,
      LocationProblem.unavailable => l10n.locationUnavailable,
      LocationProblem.outside => l10n.locationOutside,
      null => null,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButton<ManualCity>(
          isExpanded: true,
          hint: Text(l10n.chooseCity),
          value: location.devicePoint == null ? location.city : null,
          items: [
            for (final city in ManualCity.values)
              DropdownMenuItem(value: city, child: Text(city.label(l10n))),
          ],
          onChanged: (city) async {
            if (city == null) return;
            try {
              await controller.selectCity(city);
            } catch (_) {
              if (context.mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(l10n.localSaveFailed)));
              }
            }
          },
        ),
        OutlinedButton.icon(
          onPressed: location.loading ? null : controller.useDevice,
          icon: const Icon(Icons.my_location),
          label: Text(
            location.loading ? l10n.locationLoading : l10n.useLocation,
          ),
        ),
        if (location.devicePoint != null) Text(l10n.deviceLocation),
        if (message != null) Text(message),
        if (location.problem == LocationProblem.blocked)
          TextButton(
            onPressed: Geolocator.openAppSettings,
            child: Text(l10n.settingsTitle),
          ),
      ],
    );
  }
}
