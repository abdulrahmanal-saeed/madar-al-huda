import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/storage_providers.dart';
import '../domain/reminder_settings.dart';

final reminderSettingsProvider =
    NotifierProvider<ReminderSettingsController, ReminderSettings>(
      ReminderSettingsController.new,
    );

class ReminderSettingsController extends Notifier<ReminderSettings> {
  static const key = 'reminders.v1';
  Future<void> _save = Future.value();

  @override
  ReminderSettings build() =>
      ReminderSettings.decode(ref.watch(keyValueStoreProvider).getString(key));

  /// Applies [next] at once and saves it in order; a failed save keeps the
  /// change for this session, like the other preferences.
  Future<void> update(ReminderSettings next) {
    state = next;
    final store = ref.read(keyValueStoreProvider);
    final write = _save.then((_) => store.setString(key, next.encode()));
    _save = write.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return write;
  }
}
