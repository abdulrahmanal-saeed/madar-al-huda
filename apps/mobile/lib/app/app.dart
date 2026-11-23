import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../core/content/feature_preview.dart';
import '../core/localization/app_locales.dart';
import '../core/localization/l10n_extension.dart';
import '../core/routing/app_sections.dart';
import '../core/theme/app_theme.dart';
import '../features/reminders/application/reminder_sync.dart';
import '../features/settings/application/settings_controller.dart';
import '../features/worship/application/worship_location.dart';
import 'app_router.dart';
import 'startup_splash.dart';

/// Root widget. Wires settings (language, theme, motion) into MaterialApp.
class MadarApp extends ConsumerWidget {
  const MadarApp({this.showStartupSplash = true, super.key});

  final bool showStartupSplash;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      routerConfig: router,
      // null → follow the device language via localeListResolutionCallback.
      locale: settings.language.locale,
      supportedLocales: AppLocales.supported,
      // material_ui bundles the Material, Cupertino and Widgets delegates.
      localizationsDelegates: const [
        AppLocalizations.delegate,
        ...GlobalMaterialLocalizations.delegates,
      ],
      localeListResolutionCallback: (deviceLocales, _) =>
          AppLocales.resolveDeviceLocale(deviceLocales),
      themeMode: settings.theme.themeMode,
      theme: AppTheme.light(reduceMotion: settings.reduceMotion),
      darkTheme: AppTheme.dark(reduceMotion: settings.reduceMotion),
      builder: (context, child) {
        final content = settings.reduceMotion
            ? MediaQuery(
                data: MediaQuery.of(context).copyWith(disableAnimations: true),
                child: child!,
              )
            : child!;
        final synced = ReminderSync(child: content);
        return showStartupSplash
            ? StartupSplash(
                onDismissed: () => unawaited(_setUpLocation(context, ref)),
                child: synced,
              )
            : synced;
      },
    );
  }

  Future<void> _setUpLocation(BuildContext context, WidgetRef ref) async {
    if (kIsWeb ||
        defaultTargetPlatform != TargetPlatform.android ||
        (!managedReleaseEnabled &&
            AppSection.qibla.status.isGated &&
            AppSection.prayerTimes.status.isGated)) {
      return;
    }
    final navigatorKey = ref
        .read(appRouterProvider)
        .routerDelegate
        .navigatorKey;
    final controller = ref.read(worshipLocationProvider.notifier);
    if (!await controller.locateAtStartup() || !context.mounted) return;
    final navigator = navigatorKey.currentState;
    if (navigator == null || !navigator.mounted) return;
    final allow = await showDialog<bool>(
      context: navigator.context,
      builder: (context) {
        final l10n = context.l10n;
        return AlertDialog(
          title: Text(l10n.startupLocationTitle),
          content: Text(l10n.startupLocationExplanation),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.startupLocationLater),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.useLocation),
            ),
          ],
        );
      },
    );
    if (!context.mounted) return;
    if (allow == true) {
      await controller.useDevice();
    } else {
      try {
        await controller.deferDeviceAtStartup();
      } catch (_) {
        // Dismissing location setup leaves the app usable if storage fails.
      }
    }
  }
}
