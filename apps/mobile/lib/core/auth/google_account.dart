import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const googleAccountCallback = 'madar-al-huda://auth/callback';

final googleAuthProvider = Provider<GoTrueClient?>((ref) => null);

final googleAccountUserProvider = StreamProvider.autoDispose<User?>((ref) {
  final auth = ref.watch(googleAuthProvider);
  return auth == null
      ? const Stream.empty()
      : auth.onAuthStateChange.map((state) => state.session?.user);
});

Future<GoTrueClient?> initializeGoogleAccount() async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return null;

  // The Quran Edge Function and Auth are on the same Supabase project.
  final quranUrl = Uri.tryParse(
    const String.fromEnvironment('MADAR_QURAN_API_URL'),
  );
  const publicKey = String.fromEnvironment('MADAR_SUPABASE_ANON_KEY');
  if (quranUrl == null ||
      quranUrl.scheme != 'https' ||
      quranUrl.host.isEmpty ||
      quranUrl.userInfo.isNotEmpty ||
      publicKey.isEmpty) {
    return null;
  }

  try {
    final supabase = await Supabase.initialize(
      url: quranUrl.origin,
      publishableKey: publicKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
        detectSessionInUriPredicate: _isGoogleAccountCallback,
      ),
      debug: false,
    );
    return supabase.client.auth;
  } catch (_) {
    // The offline features still start if the account store is unavailable.
    return null;
  }
}

bool _isGoogleAccountCallback(Uri uri) {
  final target = Uri.parse(googleAccountCallback);
  return uri.scheme == target.scheme &&
      uri.authority == target.authority &&
      uri.path == target.path &&
      (uri.hasQuery || uri.hasFragment);
}

Future<bool> signInWithGoogle(GoTrueClient auth) => auth.signInWithOAuth(
  OAuthProvider.google,
  redirectTo: googleAccountCallback,
  authScreenLaunchMode: LaunchMode.externalApplication,
  queryParams: const {'prompt': 'select_account'},
);
