import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/content/content_news.dart';
import '../../../core/diagnostics/error_log.dart';
import '../../../core/localization/l10n_extension.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/responsive_content.dart';
import '../application/settings_controller.dart';
import '../domain/app_settings.dart';
import 'settings_account.dart';
import 'settings_updates.dart';

/// Language, appearance, accessibility, guest-mode and about.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static Key languageOptionKey(AppLanguage l) => ValueKey('language-$l');
  static Key themeOptionKey(AppThemePreference t) => ValueKey('theme-$t');
  static const Key reduceMotionKey = ValueKey('reduce-motion');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final settings = ref.watch(settingsControllerProvider);
    final controller = ref.read(settingsControllerProvider.notifier);

    Future<void> run(Future<void> Function() action) async {
      final messenger = ScaffoldMessenger.of(context);
      final message = l10n.settingsSaveError;
      try {
        await action();
      } catch (_) {
        messenger.showSnackBar(SnackBar(content: Text(message)));
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          children: [
            ResponsiveContent(
              padding: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _GroupHeader(l10n.settingsLanguage),
                  RadioGroup<AppLanguage>(
                    groupValue: settings.language,
                    onChanged: (value) {
                      if (value != null) {
                        run(() => controller.setLanguage(value));
                      }
                    },
                    child: Column(
                      children: [
                        for (final language in AppLanguage.values)
                          RadioListTile<AppLanguage>(
                            key: languageOptionKey(language),
                            value: language,
                            title: Text(_languageLabel(context, language)),
                          ),
                      ],
                    ),
                  ),
                  const _Divider(),
                  _GroupHeader(l10n.settingsAppearance),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.sm,
                    ),
                    child: SegmentedButton<AppThemePreference>(
                      showSelectedIcon: false,
                      segments: [
                        for (final theme in AppThemePreference.values)
                          ButtonSegment(
                            value: theme,
                            icon: Icon(_themeIcon(theme)),
                            label: Text(
                              _themeLabel(context, theme),
                              key: themeOptionKey(theme),
                            ),
                          ),
                      ],
                      selected: {settings.theme},
                      onSelectionChanged: (selection) =>
                          run(() => controller.setTheme(selection.single)),
                    ),
                  ),
                  SwitchListTile(
                    key: reduceMotionKey,
                    secondary: const Icon(Icons.motion_photos_off_outlined),
                    title: Text(l10n.settingsReduceMotion),
                    subtitle: Text(l10n.settingsReduceMotionSubtitle),
                    value: settings.reduceMotion,
                    onChanged: (enabled) =>
                        run(() => controller.setReduceMotion(enabled: enabled)),
                  ),
                  ListTile(
                    key: const ValueKey('settings-reminders'),
                    leading: const Icon(Icons.notifications_active_outlined),
                    title: Text(l10n.remindersTitle),
                    subtitle: Text(l10n.remindersSettingsSubtitle),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push(AppRoutes.reminders),
                  ),
                  ListTile(
                    key: const ValueKey('settings-downloads'),
                    leading: const Icon(Icons.download_for_offline_outlined),
                    title: Text(l10n.downloadsTitle),
                    subtitle: Text(l10n.downloadsSettingsSubtitle),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push(AppRoutes.downloads),
                  ),
                  const _Divider(),
                  _GroupHeader(l10n.settingsAccount),
                  const SettingsAccount(),
                  const _Divider(),
                  _GroupHeader(l10n.settingsAbout),
                  const SettingsUpdates(),
                  const ContentNewsTile(),
                  const PrivacyPolicyTile(),
                  ListTile(
                    key: const ValueKey('settings-feedback'),
                    leading: const Icon(Icons.feedback_outlined),
                    title: Text(l10n.feedbackTitle),
                    subtitle: Text(l10n.feedbackSettingsSubtitle),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push(AppRoutes.feedback),
                  ),
                  const ErrorReportTile(),
                  ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: Text(l10n.appTitle),
                    subtitle: Text(l10n.settingsAboutBody),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _languageLabel(BuildContext context, AppLanguage language) =>
      switch (language) {
        AppLanguage.system => context.l10n.languageSystem,
        AppLanguage.arabic => context.l10n.languageArabic,
        AppLanguage.english => context.l10n.languageEnglish,
      };

  static String _themeLabel(BuildContext context, AppThemePreference theme) =>
      switch (theme) {
        AppThemePreference.system => context.l10n.themeSystem,
        AppThemePreference.light => context.l10n.themeLight,
        AppThemePreference.dark => context.l10n.themeDark,
      };

  static IconData _themeIcon(AppThemePreference theme) => switch (theme) {
    AppThemePreference.system => Icons.brightness_auto_outlined,
    AppThemePreference.light => Icons.light_mode_outlined,
    AppThemePreference.dark => Icons.dark_mode_outlined,
  };
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.xs,
      ),
      child: Semantics(
        header: true,
        child: Text(
          text,
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.secondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
    child: Divider(indent: AppSpacing.lg, endIndent: AppSpacing.lg),
  );
}

class PrivacyPolicyTile extends StatelessWidget {
  const PrivacyPolicyTile({super.key});

  @override
  Widget build(BuildContext context) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    return ListTile(
      key: const ValueKey('settings-privacy'),
      leading: const Icon(Icons.privacy_tip_outlined),
      title: Text(ar ? 'سياسة الخصوصية' : 'Privacy policy'),
      trailing: const Icon(Icons.open_in_new),
      onTap: () async {
        final uri = Uri.https('quran.abdulrahmanalsaeed.com', '/privacy/');
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      },
    );
  }
}
