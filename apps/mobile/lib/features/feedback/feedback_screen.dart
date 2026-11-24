import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:material_ui/material_ui.dart';

import '../../core/content/managed_library.dart';
import '../../core/localization/l10n_extension.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/responsive_content.dart';

enum FeedbackKind { problem, suggestion }

enum FeedbackResult { sent, tooMany, failed }

/// Sends a report or suggestion to the dashboard, which keeps it and
/// emails it to the owner. Only what the user typed and the build number
/// are sent.
class FeedbackApi {
  FeedbackApi(this._client);

  final http.Client _client;

  static final endpoint = Uri.https('quran.abdulrahmanalsaeed.com', '/admin/', {
    'report': '1',
  });

  Future<FeedbackResult> send({
    required FeedbackKind kind,
    required String message,
    String contact = '',
  }) async {
    try {
      final response = await _client
          .post(
            endpoint,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({
              'kind': kind.name,
              'message': message.trim(),
              'contact': contact.trim(),
              'app': 'build ${ManagedFeedVersion.build}',
            }),
          )
          .timeout(const Duration(seconds: 20));
      return switch (response.statusCode) {
        201 || 200 => FeedbackResult.sent,
        429 => FeedbackResult.tooMany,
        _ => FeedbackResult.failed,
      };
    } on Object {
      return FeedbackResult.failed;
    }
  }
}

final feedbackApiProvider = Provider<FeedbackApi>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return FeedbackApi(client);
});

class FeedbackScreen extends ConsumerStatefulWidget {
  const FeedbackScreen({super.key});

  @override
  ConsumerState<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends ConsumerState<FeedbackScreen> {
  final _message = TextEditingController();
  final _contact = TextEditingController();
  FeedbackKind _kind = FeedbackKind.problem;
  bool _sending = false;
  bool _sent = false;

  @override
  void dispose() {
    _message.dispose();
    _contact.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final l10n = context.l10n;
    if (_message.text.trim().length < 5) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.feedbackTooShort)));
      return;
    }
    setState(() => _sending = true);
    final result = await ref
        .read(feedbackApiProvider)
        .send(kind: _kind, message: _message.text, contact: _contact.text);
    if (!mounted) return;
    setState(() {
      _sending = false;
      _sent = result == FeedbackResult.sent;
    });
    if (result != FeedbackResult.sent) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result == FeedbackResult.tooMany
                ? l10n.feedbackTooMany
                : l10n.feedbackFailed,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.feedbackTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.gutter),
          children: [
            ResponsiveContent(
              child: _sent
                  ? Column(
                      key: const Key('feedback-sent'),
                      children: [
                        const SizedBox(height: AppSpacing.xxl),
                        Icon(
                          Icons.check_circle_outline,
                          size: 72,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          l10n.feedbackThanks,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        FilledButton(
                          onPressed: () => Navigator.of(context).maybePop(),
                          child: Text(l10n.feedbackDone),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          l10n.feedbackIntro,
                          style: theme.textTheme.bodyLarge,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        SegmentedButton<FeedbackKind>(
                          key: const Key('feedback-kind'),
                          segments: [
                            ButtonSegment(
                              value: FeedbackKind.problem,
                              icon: const Icon(Icons.report_problem_outlined),
                              label: Text(l10n.feedbackProblem),
                            ),
                            ButtonSegment(
                              value: FeedbackKind.suggestion,
                              icon: const Icon(Icons.lightbulb_outline),
                              label: Text(l10n.feedbackSuggestion),
                            ),
                          ],
                          selected: {_kind},
                          onSelectionChanged: (value) =>
                              setState(() => _kind = value.single),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        TextField(
                          key: const Key('feedback-message'),
                          controller: _message,
                          minLines: 6,
                          maxLines: 12,
                          maxLength: 3000,
                          textInputAction: TextInputAction.newline,
                          decoration: InputDecoration(
                            labelText: _kind == FeedbackKind.problem
                                ? l10n.feedbackProblemHint
                                : l10n.feedbackSuggestionHint,
                            alignLabelWithHint: true,
                            border: const OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        TextField(
                          key: const Key('feedback-contact'),
                          controller: _contact,
                          maxLength: 200,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: l10n.feedbackContact,
                            border: const OutlineInputBorder(),
                          ),
                        ),
                        Text(
                          l10n.feedbackPrivacy,
                          style: theme.textTheme.bodySmall,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        FilledButton.icon(
                          key: const Key('feedback-send'),
                          onPressed: _sending ? null : _send,
                          icon: _sending
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.send_outlined),
                          label: Text(l10n.feedbackSend),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
