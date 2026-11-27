import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/localization/l10n_extension.dart';
import '../../../core/widgets/madar_panel.dart';
import '../../settings/application/settings_controller.dart';
import '../../settings/domain/app_settings.dart';

extension AdhkarContext on BuildContext {
  String get adhkarLanguage => Localizations.localeOf(this).languageCode;
}

Future<void> adhkarSave(BuildContext context, Future<void> action) async {
  try {
    await action;
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.l10n.localSaveFailed)));
    }
  }
}

Future<void> openAdhkarPage(BuildContext context, Widget screen) =>
    Navigator.of(context).push<void>(MaterialPageRoute(builder: (_) => screen));

class AdhkarLanguageButton extends ConsumerWidget {
  const AdhkarLanguageButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final english = context.adhkarLanguage == 'ar';
    return TextButton(
      onPressed: () => adhkarSave(
        context,
        ref
            .read(settingsControllerProvider.notifier)
            .setLanguage(english ? AppLanguage.english : AppLanguage.arabic),
      ),
      child: Text(english ? 'EN' : 'العربية'),
    );
  }
}

class AdhkarPage extends StatelessWidget {
  const AdhkarPage({
    required this.title,
    required this.body,
    this.actions = const [],
    this.bottomNavigationBar,
    super.key,
  });

  final String title;
  final Widget body;
  final List<Widget> actions;
  final Widget? bottomNavigationBar;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(title),
      actions: [...actions, const AdhkarLanguageButton()],
    ),
    body: SafeArea(
      top: false,
      bottom: bottomNavigationBar == null,
      child: body,
    ),
    bottomNavigationBar: bottomNavigationBar,
  );
}

class AdhkarHero extends StatelessWidget {
  const AdhkarHero({required this.child, this.onTap, super.key});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => MadarPanel(
    color: Theme.of(context).colorScheme.surfaceContainerHighest,
    onTap: onTap,
    child: DefaultTextStyle.merge(
      style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
      child: child,
    ),
  );
}
