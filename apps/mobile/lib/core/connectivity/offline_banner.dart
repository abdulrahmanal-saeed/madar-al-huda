import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../localization/l10n_extension.dart';

/// Whether the phone has no network at all. Unknown counts as online, so
/// the banner never shows by mistake (tests, unsupported platforms).
final offlineProvider = StreamProvider<bool>((ref) async* {
  final connectivity = Connectivity();
  bool offline(List<ConnectivityResult> results) =>
      results.isNotEmpty && results.every((r) => r == ConnectivityResult.none);
  try {
    yield offline(await connectivity.checkConnectivity());
    yield* connectivity.onConnectivityChanged.map(offline);
  } on Object {
    yield false;
  }
});

/// A thin line above the tab bar while the phone is offline: saved content
/// keeps working, the rest waits for the connection.
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offline = ref.watch(offlineProvider).asData?.value ?? false;
    final scheme = Theme.of(context).colorScheme;
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      child: offline
          ? Material(
              key: const Key('offline-banner'),
              color: scheme.inverseSurface,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.cloud_off_outlined,
                      size: 16,
                      color: scheme.onInverseSurface,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        context.l10n.offlineBanner,
                        style: TextStyle(
                          color: scheme.onInverseSurface,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : const SizedBox(width: double.infinity),
    );
  }
}
