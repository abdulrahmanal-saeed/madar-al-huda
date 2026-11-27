import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/content/content_news.dart';
import '../../../core/diagnostics/error_log.dart';
import '../../../core/localization/l10n_extension.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/madar_panel.dart';
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

    final arabic = Localizations.localeOf(context).languageCode == 'ar';
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: MadarBackdrop(
        child: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            children: [
              ResponsiveContent(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _GroupHeader(l10n.settingsLanguage),
                    MadarPanel(
                      child: _SettingChoices(
                        label: arabic ? 'لغة الواجهة' : 'Interface language',
                        choices: [
                          for (final language in AppLanguage.values)
                            ChoiceChip(
                              key: languageOptionKey(language),
                              showCheckmark: false,
                              label: Text(_languageLabel(context, language)),
                              selected: settings.language == language,
                              onSelected: (_) =>
                                  run(() => controller.setLanguage(language)),
                            ),
                        ],
                      ),
                    ),
                    _GroupHeader(l10n.settingsAppearance),
                    MadarPanel(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            child: _SettingChoices(
                              label: arabic ? 'نمط التطبيق' : 'App theme',
                              choices: [
                                for (final theme in AppThemePreference.values)
                                  ChoiceChip(
                                    key: themeOptionKey(theme),
                                    showCheckmark: false,
                                    label: Text(_themeLabel(context, theme)),
                                    selected: settings.theme == theme,
                                    onSelected: (_) =>
                                        run(() => controller.setTheme(theme)),
                                  ),
                              ],
                            ),
                          ),
                          const _Divider(),
                          SwitchListTile(
                            key: reduceMotionKey,
                            title: Text(l10n.settingsReduceMotion),
                            subtitle: Text(l10n.settingsReduceMotionSubtitle),
                            value: settings.reduceMotion,
                            onChanged: (enabled) => run(
                              () =>
                                  controller.setReduceMotion(enabled: enabled),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _GroupHeader(arabic ? 'التطبيق' : 'App'),
                    MadarPanel(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          ListTile(
                            key: const ValueKey('settings-reminders'),
                            title: Text(l10n.remindersTitle),
                            subtitle: Text(l10n.remindersSettingsSubtitle),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => context.push(AppRoutes.reminders),
                          ),
                          const _Divider(),
                          ListTile(
                            key: const ValueKey('settings-downloads'),
                            title: Text(l10n.downloadsTitle),
                            subtitle: Text(l10n.downloadsSettingsSubtitle),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => context.push(AppRoutes.downloads),
                          ),
                          const _Divider(),
                          const SettingsUpdates(),
                          const _Divider(),
                          const ContentNewsTile(),
                          const _Divider(),
                          const PrivacyPolicyTile(),
                        ],
                      ),
                    ),
                    _GroupHeader(l10n.settingsAccount),
                    const MadarPanel(
                      padding: EdgeInsets.zero,
                      child: SettingsAccount(),
                    ),
                    _GroupHeader(l10n.settingsAbout),
                    MadarPanel(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          ListTile(
                            key: const ValueKey('settings-feedback'),
                            title: Text(l10n.feedbackTitle),
                            subtitle: Text(l10n.feedbackSettingsSubtitle),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => context.push(AppRoutes.feedback),
                          ),
                          const _Divider(),
                          const ErrorReportTile(),
                          ListTile(
                            title: Text(l10n.appTitle),
                            subtitle: Text(l10n.settingsAboutBody),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
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
}

class _SettingChoices extends StatelessWidget {
  const _SettingChoices({required this.label, required this.choices});

  final String label;
  final List<Widget> choices;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(label, style: Theme.of(context).textTheme.titleSmall),
      ),
      const SizedBox(width: AppSpacing.sm),
      Flexible(
        flex: 3,
        child: Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          alignment: WrapAlignment.end,
          children: choices,
        ),
      ),
    ],
  );
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
            color: theme.colorScheme.primary,
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
    padding: EdgeInsets.zero,
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
