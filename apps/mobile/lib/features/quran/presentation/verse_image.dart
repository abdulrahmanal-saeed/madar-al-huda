import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/localization/l10n_extension.dart';
import '../../../core/localization/numbers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';

/// Shows the verse as a branded card and shares it as a PNG image.
Future<void> shareVerseImage(
  BuildContext context, {
  required String verseText,
  required String surahName,
  required int surah,
  required int ayah,
}) => showDialog<void>(
  context: context,
  builder: (_) => _VerseImageDialog(
    verseText: verseText,
    surahName: surahName,
    surah: surah,
    ayah: ayah,
  ),
);

/// The card itself, in the app's identity; also used for the preview.
class VerseCard extends StatelessWidget {
  const VerseCard({
    required this.verseText,
    required this.reference,
    super.key,
  });

  final String verseText;

  /// «البقرة ٢٠١».
  final String reference;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 360,
      padding: const EdgeInsets.all(AppSpacing.lg),
      color: scheme.surfaceContainerLow,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.xl,
        ),
        decoration: BoxDecoration(
          border: Border.all(color: scheme.secondary, width: 1.5),
          borderRadius: AppRadii.lgAll,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              verseText,
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontFamily: AppTheme.quranFontFamily,
                fontSize: 24,
                height: 2,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              reference,
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 15,
                color: scheme.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'مدار الهدى',
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontFamily: AppTheme.headingFontFamily,
                fontSize: 14,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VerseImageDialog extends StatefulWidget {
  const _VerseImageDialog({
    required this.verseText,
    required this.surahName,
    required this.surah,
    required this.ayah,
  });

  final String verseText;
  final String surahName;
  final int surah;
  final int ayah;

  @override
  State<_VerseImageDialog> createState() => _VerseImageDialogState();
}

class _VerseImageDialogState extends State<_VerseImageDialog> {
  final _boundary = GlobalKey();
  bool _busy = false;

  Future<void> _share(String reference) async {
    setState(() => _busy = true);
    final failed = context.l10n.readerShareFailed;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      final render =
          _boundary.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
      final image = await render.toImage(pixelRatio: 3);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (bytes == null) throw StateError('No image data');
      final folder = Directory(
        '${(await getTemporaryDirectory()).path}/shared',
      );
      await folder.create(recursive: true);
      final file = File(
        '${folder.path}/verse-${widget.surah}-${widget.ayah}.png',
      );
      await file.writeAsBytes(bytes.buffer.asUint8List(), flush: true);
      await const MethodChannel('madar/share').invokeMethod<void>(
        'shareImage',
        {'path': file.path, 'text': '${widget.verseText}\n$reference'},
      );
      navigator.pop();
    } on Object {
      messenger.showSnackBar(SnackBar(content: Text(failed)));
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final language = Localizations.localeOf(context).languageCode;
    final number = decimalFormat(language).format;
    final reference = language == 'ar'
        ? '${widget.surahName} ${number(widget.ayah)}'
        : '${widget.surahName} ${widget.surah}:${widget.ayah}';
    return AlertDialog(
      contentPadding: const EdgeInsets.all(AppSpacing.md),
      content: SingleChildScrollView(
        child: FittedBox(
          child: RepaintBoundary(
            key: _boundary,
            child: VerseCard(
              key: const ValueKey('verse-card'),
              verseText: widget.verseText,
              reference: reference,
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        FilledButton.icon(
          key: const ValueKey('verse-image-share'),
          onPressed: _busy ? null : () => _share(reference),
          icon: const Icon(Icons.share_outlined),
          label: Text(l10n.readerShare),
        ),
      ],
    );
  }
}
