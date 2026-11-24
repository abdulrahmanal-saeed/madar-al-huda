import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../localization/numbers.dart';

typedef DownloadCollection = ({
  String label,
  int completed,
  int total,
  bool running,
  bool interrupted,
});

final collectionDownloadsProvider =
    NotifierProvider<CollectionDownloads, DownloadCollection?>(
      CollectionDownloads.new,
    );

class CollectionDownloads extends Notifier<DownloadCollection?> {
  bool _cancel = false;

  @override
  DownloadCollection? build() => null;

  void stop() => _cancel = true;

  Future<void> start(String label, List<Future<void> Function()> tasks) async {
    if (state?.running == true || tasks.isEmpty) return;
    _cancel = false;
    var completed = 0;
    void update(bool running, {bool interrupted = false}) {
      if (!ref.mounted) return;
      state = (
        label: label,
        completed: completed,
        total: tasks.length,
        running: running,
        interrupted: interrupted,
      );
    }

    update(true);
    try {
      for (final task in tasks) {
        if (_cancel || !ref.mounted) break;
        await task();
        completed++;
        update(true);
      }
    } catch (_) {
      // Completed files remain available and are skipped by the next run.
    } finally {
      update(false, interrupted: completed != tasks.length);
    }
  }
}

class CollectionDownloadStatus extends ConsumerWidget {
  const CollectionDownloadStatus({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(collectionDownloadsProvider);
    // A finished download says nothing more; only progress and an
    // interrupted run need a line.
    if (progress == null || (!progress.running && !progress.interrupted)) {
      return const SizedBox.shrink();
    }
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    return ListTile(
      title: Text(progress.label),
      subtitle: Text(
        progress.interrupted
            ? (ar
                  ? 'توقّف التنزيل. أعد التشغيل لاستكمال الملفات.'
                  : 'Download stopped. Start it again to resume.')
            : localizedDigits(
                '${progress.completed} / ${progress.total}',
                Localizations.localeOf(context).languageCode,
              ),
      ),
      leading: progress.running
          ? CircularProgressIndicator(
              value: progress.completed / progress.total,
            )
          : const Icon(Icons.offline_pin_outlined),
      trailing: progress.running
          ? TextButton(
              onPressed: ref.read(collectionDownloadsProvider.notifier).stop,
              child: Text(ar ? 'إيقاف' : 'Stop'),
            )
          : null,
    );
  }
}
