import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/auth/google_account.dart';
import '../../../core/localization/l10n_extension.dart';

class SettingsAccount extends ConsumerStatefulWidget {
  const SettingsAccount({super.key});

  @override
  ConsumerState<SettingsAccount> createState() => _SettingsAccountState();
}

class _SettingsAccountState extends ConsumerState<SettingsAccount> {
  bool _working = false;

  Future<void> _run(Future<void> Function() action, String error) async {
    if (_working) return;
    setState(() => _working = true);
    try {
      await action();
    } catch (_) {
      if (mounted) _showError(error);
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final auth = ref.watch(googleAuthProvider);
    final state = ref.watch(googleAccountUserProvider);
    final user = state.hasValue ? state.value : auth?.currentUser;
    ref.listen(googleAccountUserProvider, (_, next) {
      if (next.hasError && auth?.currentUser == null) {
        _showError(l10n.settingsGoogleSignInError);
      }
    });

    if (auth != null && user != null) {
      return Column(
        children: [
          ListTile(
            leading: const Icon(Icons.account_circle_outlined),
            title: Text(l10n.settingsGoogleAccount),
            subtitle: switch (user.email) {
              final email? => Text(email, textDirection: TextDirection.ltr),
              null => null,
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: Text(l10n.settingsGoogleSignOut),
            enabled: !_working,
            onTap: () => _run(
              () => auth.signOut(scope: SignOutScope.local),
              l10n.settingsGoogleSignOutError,
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.person_outline),
          title: Text(l10n.settingsGuestMode),
          subtitle: Text(l10n.settingsGuestModeBody),
        ),
        if (auth != null)
          ListTile(
            leading: const Icon(Icons.login),
            title: Text(l10n.settingsGoogleSignIn),
            enabled: !_working,
            onTap: () => _run(() async {
              if (!await signInWithGoogle(auth)) {
                throw StateError('Could not open the OAuth browser');
              }
            }, l10n.settingsGoogleSignInError),
          ),
      ],
    );
  }
}
