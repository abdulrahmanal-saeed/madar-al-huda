import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:madar_al_huda/core/auth/google_account.dart';
import 'package:material_ui/material_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../helpers/pump_app.dart';

class _Auth extends Fake implements GoTrueClient {
  final events = StreamController<AuthState>.broadcast();
  User? _user;
  SignOutScope? signOutScope;

  @override
  User? get currentUser => _user;

  @override
  Stream<AuthState> get onAuthStateChange => events.stream;

  void returnFromGoogle() {
    _user = const User(
      id: 'test-user',
      appMetadata: {'provider': 'google'},
      userMetadata: {},
      aud: 'authenticated',
      email: 'reader@example.com',
      createdAt: '2026-11-23T00:00:00Z',
    );
    events.add(
      AuthState(
        AuthChangeEvent.signedIn,
        Session(accessToken: 'test', tokenType: 'bearer', user: _user!),
      ),
    );
  }

  @override
  Future<void> signOut({SignOutScope scope = SignOutScope.local}) async {
    signOutScope = scope;
    _user = null;
    events.add(const AuthState(AuthChangeEvent.signedOut, null));
  }
}

void main() {
  testWidgets('updates the settings account after sign-in and sign-out', (
    tester,
  ) async {
    final auth = _Auth();
    addTearDown(auth.events.close);
    await pumpMadarApp(
      tester,
      initialLocation: '/settings',
      additionalOverrides: [googleAuthProvider.overrideWithValue(auth)],
    );
    final signIn = find.text('Sign in with Google');
    await tester.ensureVisible(signIn);
    expect(find.text('Guest mode'), findsOneWidget);
    expect(signIn, findsOneWidget);

    auth.returnFromGoogle();
    await tester.pumpAndSettle();
    expect(find.text('reader@example.com'), findsOneWidget);
    expect(signIn, findsNothing);

    final signOut = find.text('Sign out');
    await tester.ensureVisible(signOut);
    await tester.tap(signOut);
    await tester.pumpAndSettle();
    expect(auth.signOutScope, SignOutScope.local);
    expect(find.text('Guest mode'), findsOneWidget);
    expect(signIn, findsOneWidget);
  });

  testWidgets('shows an Arabic error when the browser callback fails', (
    tester,
  ) async {
    final auth = _Auth();
    addTearDown(auth.events.close);
    await pumpMadarApp(
      tester,
      initialLocation: '/settings',
      deviceLocales: const [Locale('ar')],
      additionalOverrides: [googleAuthProvider.overrideWithValue(auth)],
    );
    expect(find.text('تسجيل الدخول باستخدام Google'), findsOneWidget);
    auth.events.addError(const AuthException('Callback failed'));
    await tester.pumpAndSettle();
    expect(
      find.text('تعذّر تسجيل الدخول باستخدام Google. حاول مرة أخرى.'),
      findsOneWidget,
    );
    expect(find.text('وضع الضيف'), findsOneWidget);
  });
}
