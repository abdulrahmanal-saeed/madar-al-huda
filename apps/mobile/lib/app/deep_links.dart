import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../core/routing/app_routes.dart';
import 'app_router.dart';

const appLinkHost = 'quran.abdulrahmanalsaeed.com';

/// Screens a shared link may open; anything else is ignored.
const _linkable = [
  AppRoutes.home,
  AppRoutes.quran,
  AppRoutes.adhkar,
  AppRoutes.worship,
  AppRoutes.library,
  AppRoutes.learning,
  AppRoutes.search,
  AppRoutes.memorize,
  AppRoutes.stats,
  AppRoutes.reminders,
  AppRoutes.downloads,
  AppRoutes.zakat,
];

/// The in-app route for `https://quran.abdulrahmanalsaeed.com/app/…`, or
/// null for any other link.
String? routeForLink(Uri uri) {
  if (uri.scheme != 'https' || uri.host != appLinkHost) return null;
  final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
  if (segments.isEmpty || segments.first != 'app') return null;
  if (segments.length == 1) return AppRoutes.home;
  final path = '/${segments.skip(1).join('/')}';
  if (!_linkable.any((root) => path == root || path.startsWith('$root/'))) {
    return null;
  }
  return Uri(
    path: path,
    queryParameters: uri.queryParameters.isEmpty ? null : uri.queryParameters,
  ).toString();
}

/// A link to [route] that opens the app, or the download page without it.
Uri appLinkFor(String route) {
  final target = Uri.parse(route);
  return Uri.https(
    appLinkHost,
    '/app${target.path}',
    target.queryParameters.isEmpty ? null : target.queryParameters,
  );
}

/// Links the system hands to the app: the one it was opened with, then any
/// later ones. Empty where the plugin is missing (tests, desktop).
final appLinkStreamProvider = Provider<Stream<Uri>>((ref) {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
    return const Stream.empty();
  }
  try {
    return AppLinks().uriLinkStream;
  } on Object {
    return const Stream.empty();
  }
});

/// Opens app links in the router; other links (sign-in callbacks) are left
/// to their own handlers.
class DeepLinks extends ConsumerStatefulWidget {
  const DeepLinks({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<DeepLinks> createState() => _DeepLinksState();
}

class _DeepLinksState extends ConsumerState<DeepLinks> {
  StreamSubscription<Uri>? _links;

  @override
  void initState() {
    super.initState();
    _links = ref.read(appLinkStreamProvider).listen(
      (uri) {
        final route = routeForLink(uri);
        if (route != null) ref.read(appRouterProvider).go(route);
      },
      // A missing plugin or a malformed link never reaches the user.
      onError: (Object _) {},
    );
  }

  @override
  void dispose() {
    unawaited(_links?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
