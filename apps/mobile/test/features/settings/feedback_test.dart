import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:madar_al_huda/core/localization/app_locales.dart';
import 'package:madar_al_huda/core/routing/app_routes.dart';
import 'package:madar_al_huda/features/feedback/feedback_screen.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/pump_app.dart';

void main() {
  final l10n = lookupAppLocalizations(const Locale('en'));

  testWidgets('sends a suggestion with only what the user typed', (
    tester,
  ) async {
    final sent = <Map<String, Object?>>[];
    final client = MockClient((request) async {
      expect(request.url, FeedbackApi.endpoint);
      sent.add(jsonDecode(request.body) as Map<String, Object?>);
      return http.Response('{"ok":true}', 201);
    });
    await pumpMadarApp(
      tester,
      initialLocation: AppRoutes.feedback,
      additionalOverrides: [
        feedbackApiProvider.overrideWithValue(FeedbackApi(client)),
      ],
    );

    await tester.tap(find.byKey(const Key('feedback-send')));
    await tester.pump();
    expect(find.text(l10n.feedbackTooShort), findsOneWidget);
    expect(sent, isEmpty);

    await tester.tap(find.text(l10n.feedbackSuggestion));
    await tester.enterText(
      find.byKey(const Key('feedback-message')),
      'Please add a night reading mode',
    );
    await tester.enterText(
      find.byKey(const Key('feedback-contact')),
      'me@example.com',
    );
    await tester.tap(find.byKey(const Key('feedback-send')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('feedback-sent')), findsOneWidget);
    expect(sent.single['kind'], 'suggestion');
    expect(sent.single['message'], 'Please add a night reading mode');
    expect(sent.single['contact'], 'me@example.com');
    expect(sent.single.keys, {'kind', 'message', 'contact', 'app'});
  });

  testWidgets('explains when too many reports were sent', (tester) async {
    final client = MockClient((_) async => http.Response('{}', 429));
    await pumpMadarApp(
      tester,
      initialLocation: AppRoutes.feedback,
      additionalOverrides: [
        feedbackApiProvider.overrideWithValue(FeedbackApi(client)),
      ],
    );
    await tester.enterText(
      find.byKey(const Key('feedback-message')),
      'The radio stops after a minute',
    );
    await tester.tap(find.byKey(const Key('feedback-send')));
    await tester.pumpAndSettle();
    expect(find.text(l10n.feedbackTooMany), findsOneWidget);
    expect(find.byKey(const Key('feedback-sent')), findsNothing);
  });
}
