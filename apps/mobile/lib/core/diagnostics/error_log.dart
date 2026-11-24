import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path_provider/path_provider.dart';

import '../localization/l10n_extension.dart';

/// Errors kept on the phone only. Nothing is sent anywhere: the user may
/// read the report and choose to share it from Settings.
class ErrorLog {
  ErrorLog(this._directory);

  final Future<Directory> Function() _directory;
  static const keep = 40;
  Future<void> _writes = Future.value();

  Future<File> get _file async =>
      File('${(await _directory()).path}/error-log.jsonl');

  /// Records one error: its type, message and the top of its stack. File
  /// paths are shortened to package names, and nothing the user typed is
  /// included.
  Future<void> record(Object error, StackTrace? stack, {String? context}) {
    final entry = jsonEncode({
      'at': DateTime.now().toUtc().toIso8601String(),
      'type': error.runtimeType.toString(),
      'message': _trim(error.toString(), 300),
      'context': ?context,
      'stack': [
        for (final line in (stack?.toString() ?? '').split('\n').take(12))
          if (line.trim().isNotEmpty)
            line.replaceAll(RegExp(r'file:///[^ )]*/lib/'), 'lib/').trim(),
      ],
    });
    final write = _writes.then((_) async {
      final file = await _file;
      final lines = await file.exists() ? await file.readAsLines() : <String>[];
      final kept = [...lines, entry];
      await file.writeAsString(
        '${kept.skip(kept.length > keep ? kept.length - keep : 0).join('\n')}\n',
        flush: true,
      );
    });
    _writes = write.catchError((Object _) {});
    return _writes;
  }

  Future<List<Map<String, Object?>>> entries() async {
    try {
      final file = await _file;
      if (!await file.exists()) return const [];
      return [
        for (final line in await file.readAsLines())
          if (line.trim().isNotEmpty) jsonDecode(line) as Map<String, Object?>,
      ];
    } on Object {
      return const [];
    }
  }

  Future<void> clear() async {
    final file = await _file;
    if (await file.exists()) await file.delete();
  }

  static String _trim(String text, int limit) =>
      text.length > limit ? '${text.substring(0, limit)}…' : text;
}

final errorLogProvider = Provider<ErrorLog>(
  (_) => ErrorLog(getApplicationSupportDirectory),
);

/// Sends Flutter and platform errors to [log] as well as their usual
/// handlers.
void captureErrors(ErrorLog log) {
  final previous = FlutterError.onError;
  FlutterError.onError = (details) {
    unawaited(
      log.record(
        details.exception,
        details.stack,
        context: details.context?.toString(),
      ),
    );
    previous?.call(details);
  };
  final platform = PlatformDispatcher.instance.onError;
  PlatformDispatcher.instance.onError = (error, stack) {
    unawaited(log.record(error, stack));
    return platform?.call(error, stack) ?? false;
  };
}

final errorReportProvider =
    FutureProvider.autoDispose<List<Map<String, Object?>>>(
      (ref) => ref.watch(errorLogProvider).entries(),
    );

/// Settings row: how many errors the phone kept, with a sheet to read,
/// share or clear them.
class ErrorReportTile extends ConsumerWidget {
  const ErrorReportTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final entries = ref.watch(errorReportProvider).asData?.value ?? const [];
    return ListTile(
      key: const Key('error-report'),
      leading: const Icon(Icons.bug_report_outlined),
      title: Text(l10n.errorReportTitle),
      subtitle: Text(
        entries.isEmpty
            ? l10n.errorReportNone
            : l10n.errorReportCount('${entries.length}'),
      ),
      trailing: entries.isEmpty ? null : const Icon(Icons.chevron_right),
      onTap: entries.isEmpty
          ? null
          : () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              useSafeArea: true,
              showDragHandle: true,
              builder: (_) => _ErrorReportSheet(entries: entries),
            ),
    );
  }
}

class _ErrorReportSheet extends ConsumerWidget {
  const _ErrorReportSheet({required this.entries});

  final List<Map<String, Object?>> entries;

  String get _report => [
    'Madar Al-Huda error report',
    for (final entry in entries.reversed)
      '[${entry['at']}] ${entry['type']}: ${entry['message']}\n'
          '${(entry['stack'] as List<Object?>? ?? const []).join('\n')}',
  ].join('\n\n');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.8,
      child: Column(
        children: [
          ListTile(
            title: Text(
              l10n.errorReportTitle,
              style: theme.textTheme.titleLarge,
            ),
            subtitle: Text(l10n.errorReportPrivacy),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                for (final entry in entries.reversed)
                  Card(
                    child: ListTile(
                      title: Text(
                        '${entry['type']}',
                        textDirection: TextDirection.ltr,
                      ),
                      subtitle: Text(
                        '${entry['message']}\n${entry['at']}',
                        textDirection: TextDirection.ltr,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () async {
                        try {
                          await const MethodChannel('madar/share')
                              .invokeMethod<void>('shareText', _report);
                        } on Exception {
                          await Clipboard.setData(ClipboardData(text: _report));
                        }
                      },
                      icon: const Icon(Icons.share_outlined),
                      label: Text(l10n.errorReportShare),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: () async {
                      await ref.read(errorLogProvider).clear();
                      ref.invalidate(errorReportProvider);
                      if (context.mounted) Navigator.of(context).pop();
                    },
                    child: Text(l10n.errorReportClear),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
