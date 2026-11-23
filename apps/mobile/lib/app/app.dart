import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../core/localization/app_locales.dart';
import '../core/theme/app_theme.dart';
import '../features/settings/application/settings_controller.dart';
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
        return showStartupSplash ? StartupSplash(child: content) : content;
      },
    );
  }
}
