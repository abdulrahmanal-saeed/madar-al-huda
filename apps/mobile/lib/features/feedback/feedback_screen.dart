import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter/services.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:material_ui/material_ui.dart';

import '../../core/content/managed_library.dart';
import '../../core/localization/l10n_extension.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/responsive_content.dart';

const _maxFeedbackImageBytes = 2 * 1024 * 1024;
const _feedbackImages = MethodChannel('madar/feedback-image');

enum FeedbackKind { problem, suggestion }

enum FeedbackResult { sent, tooMany, failed }

/// Sends a report or suggestion to the dashboard, which keeps it and
/// emails it to the owner. Only user-entered information, an explicitly
/// selected image, and the build number are sent.
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
    Uint8List? image,
  }) async {
    if (image != null &&
        (image.isEmpty || image.length > _maxFeedbackImageBytes)) {
      return FeedbackResult.failed;
    }
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
              if (image != null) 'image': base64Encode(image),
            }),
          )
          .timeout(const Duration(seconds: 20));
      if (image != null &&
          (response.statusCode == 200 || response.statusCode == 201)) {
        final receipt = jsonDecode(response.body);
        if (receipt is! Map || receipt['image'] != true) {
          return FeedbackResult.failed;
        }
      }
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
  bool _picking = false;
  Uint8List? _image;

  bool get _canPick =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  bool get _ar => Localizations.localeOf(context).languageCode == 'ar';

  Future<void> _pickImage() async {
    setState(() => _picking = true);
    try {
      final image = await _feedbackImages.invokeMethod<Uint8List>('pick');
      if (mounted && image != null) setState(() => _image = image);
    } on Object {
      if (mounted) {
        final message = _ar
            ? 'اختر صورة PNG أو JPEG بحجم لا يتجاوز 2 ميجابايت.'
            : 'Choose a PNG or JPEG image no larger than 2 MB.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

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
        .send(
          kind: _kind,
          message: _message.text,
          contact: _contact.text,
          image: _image,
        );
    if (!mounted) return;
    setState(() {
      _sending = false;
      _sent = result == FeedbackResult.sent;
      if (_sent) _image = null;
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
                        if (_canPick) ...[
                          OutlinedButton.icon(
                            key: const Key('feedback-image'),
                            onPressed: _sending || _picking ? null : _pickImage,
                            icon: const Icon(Icons.add_photo_alternate_outlined),
                            label: Text(
                              _ar ? 'إرفاق صورة (اختياري)' : 'Attach image (optional)',
                            ),
                          ),
                          Text(
                            _ar
                                ? 'اختر لقطة شاشة بدون معلومات شخصية (PNG أو JPEG، حتى 2 ميجابايت). تُرسل مع البلاغ إلى الإدارة فقط.'
                                : 'Choose a screenshot without personal information (PNG or JPEG, up to 2 MB). It is sent only to the administrators.',
                            style: theme.textTheme.bodySmall,
                          ),
                          if (_image case final image?) ...[
                            Image.memory(
                              image,
                              height: 120,
                              cacheWidth: 480,
                              fit: BoxFit.contain,
                              errorBuilder: (_, _, _) => const Icon(Icons.broken_image),
                            ),
                            TextButton.icon(
                              onPressed: _sending || _picking
                                  ? null
                                  : () => setState(() => _image = null),
                              icon: const Icon(Icons.close),
                              label: Text(_ar ? 'إزالة الصورة' : 'Remove image'),
                            ),
                          ],
                          const SizedBox(height: AppSpacing.md),
                        ],
                        FilledButton.icon(
                          key: const Key('feedback-send'),
                          onPressed: _sending || _picking ? null : _send,
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
