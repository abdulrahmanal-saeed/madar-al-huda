import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/localization/l10n_extension.dart';
import '../../../core/theme/app_tokens.dart';
import '../application/worship_location.dart';
import '../domain/world_cities.dart';

/// The user's one location, with a way to change it: GPS or any city.
class WorshipLocationPicker extends ConsumerWidget {
  const WorshipLocationPicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = ref.watch(worshipLocationProvider);
    final controller = ref.read(worshipLocationProvider.notifier);
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final language = Localizations.localeOf(context).languageCode;
    final place = location.place;
    final country = place == null
        ? null
        : ref
              .watch(worldCitiesProvider)
              .asData
              ?.value
              .countryName(place.country, language);
    final message = switch (location.problem) {
      LocationProblem.denied || LocationProblem.blocked => l10n.locationDenied,
      LocationProblem.unavailable => l10n.locationUnavailable,
      null => null,
    };
    final title = place == null
        ? l10n.locationChooseTitle
        : [
            place.label(language) ?? l10n.deviceLocation,
            ?country,
          ].join(language == 'ar' ? '، ' : ', ');
    final subtitle = place == null
        ? l10n.locationChooseHint
        : location.fromDevice
        ? l10n.locationFromDevice
        : l10n.locationChosenCity;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            key: const Key('worship-location'),
            leading: CircleAvatar(
              backgroundColor: theme.colorScheme.primaryContainer,
              foregroundColor: theme.colorScheme.onPrimaryContainer,
              child: Icon(
                location.fromDevice
                    ? Icons.my_location
                    : Icons.location_city_outlined,
              ),
            ),
            title: Text(title, style: theme.textTheme.titleMedium),
            subtitle: Text(subtitle),
            trailing: place == null
                ? null
                : TextButton(
                    onPressed: () => showWorshipLocationSheet(context),
                    child: Text(l10n.locationChange),
                  ),
            onTap: () => showWorshipLocationSheet(context),
          ),
          if (location.loading) const LinearProgressIndicator(minHeight: 2),
          if (place == null)
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              child: Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  FilledButton.icon(
                    onPressed: location.loading ? null : controller.useDevice,
                    icon: const Icon(Icons.my_location, size: 18),
                    label: Text(
                      location.loading
                          ? l10n.locationLoading
                          : l10n.useLocation,
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => showWorshipLocationSheet(context),
                    icon: const Icon(Icons.search, size: 18),
                    label: Text(l10n.locationSearchHint),
                  ),
                ],
              ),
            ),
          if (message != null)
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 18,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: Text(message)),
                  if (location.problem == LocationProblem.blocked)
                    TextButton(
                      onPressed: Geolocator.openAppSettings,
                      child: Text(l10n.settingsTitle),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

Future<void> showWorshipLocationSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => const _LocationSheet(),
    );

class _LocationSheet extends ConsumerStatefulWidget {
  const _LocationSheet();

  @override
  ConsumerState<_LocationSheet> createState() => _LocationSheetState();
}

class _LocationSheetState extends ConsumerState<_LocationSheet> {
  final _query = TextEditingController();
  Timer? _debounce;
  String _search = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    super.dispose();
  }

  void _changed(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 200), () {
      if (mounted) setState(() => _search = value);
    });
  }

  Future<void> _pick(WorldCity city) async {
    final messenger = ScaffoldMessenger.of(context);
    final failed = context.l10n.localSaveFailed;
    Navigator.of(context).pop();
    try {
      await ref
          .read(worshipLocationProvider.notifier)
          .selectCity(WorshipPlace.city(city));
    } on Object {
      messenger.showSnackBar(SnackBar(content: Text(failed)));
    }
  }

  void _useDevice() {
    Navigator.of(context).pop();
    unawaited(ref.read(worshipLocationProvider.notifier).useDevice());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final language = Localizations.localeOf(context).languageCode;
    final location = ref.watch(worshipLocationProvider);
    final cities = ref.watch(worldCitiesProvider);
    final current = location.place;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.85,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      child: const Icon(Icons.my_location),
                    ),
                    title: Text(l10n.useLocation),
                    subtitle: Text(l10n.locationChooseHint),
                    selected: location.fromDevice,
                    trailing: location.fromDevice
                        ? const Icon(Icons.check_circle)
                        : null,
                    onTap: location.loading ? null : _useDevice,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    key: const Key('city-search'),
                    controller: _query,
                    onChanged: _changed,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: l10n.locationSearchHint,
                      border: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(28)),
                      ),
                      isDense: true,
                      suffixIcon: _query.text.isEmpty
                          ? null
                          : IconButton(
                              tooltip: MaterialLocalizations.of(context)
                                  .deleteButtonTooltip,
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                _query.clear();
                                _changed('');
                              },
                            ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
              ),
            ),
            Expanded(
              child: switch (cities) {
                AsyncData(:final value) => _results(value, current, language),
                AsyncError() => Center(child: Text(l10n.locationUnavailable)),
                _ => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: AppSpacing.md),
                      Text(l10n.locationCitiesLoading),
                    ],
                  ),
                ),
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _results(WorldCities cities, WorshipPlace? current, String language) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final searching = _search.trim().isNotEmpty;
    final list = searching
        ? cities.search(_search)
        : cities.largestIn(current?.country);
    if (list.isEmpty) {
      return Center(child: Text(l10n.locationNoResults));
    }
    final header = searching
        ? null
        : current == null
        ? l10n.locationLargestWorld
        : l10n.locationCountryCities(
            cities.countryName(current.country, language),
          );
    return ListView.builder(
      itemCount: list.length + (header == null ? 0 : 1),
      itemBuilder: (context, index) {
        if (header != null && index == 0) {
          return Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.xs,
            ),
            child: Text(
              header,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          );
        }
        final city = list[index - (header == null ? 0 : 1)];
        final selected =
            current != null &&
            !ref.read(worshipLocationProvider).fromDevice &&
            current.cityId == city.id;
        return ListTile(
          key: ValueKey('city-${city.id}'),
          leading: const Icon(Icons.location_on_outlined),
          title: Text(city.label(language)),
          subtitle: Text(cities.countryName(city.country, language)),
          selected: selected,
          trailing: selected ? const Icon(Icons.check) : null,
          onTap: () => _pick(city),
        );
      },
    );
  }
}
