import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../storage/storage_providers.dart';

const _channel = MethodChannel('madar/content_news');
const _preference = 'contentNews.enabled';

final contentNewsProvider = NotifierProvider<ContentNewsPreference, bool>(
  ContentNewsPreference.new,
);

class ContentNewsPreference extends Notifier<bool> {
  Future<void> _writes = Future.value();

  @override
  bool build() => ref.watch(keyValueStoreProvider).getBool(_preference) ?? true;

  Future<void> set(bool enabled) {
    state = enabled;
    final store = ref.read(keyValueStoreProvider);
    final write = _writes.then(
      (_) => store.setBool(_preference, value: enabled),
    );
    _writes = write.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return write;
  }
}

class ContentNewsSync extends ConsumerStatefulWidget {
  const ContentNewsSync({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<ContentNewsSync> createState() => _ContentNewsSyncState();
}

class _ContentNewsSyncState extends ConsumerState<ContentNewsSync> {
  late final AppLifecycleListener _lifecycle;
  (bool, String)? _configuration;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onResume: () {
        if (_configuration case (final enabled, final language)) {
          _sync(enabled, language);
        }
      },
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  Future<void> _sync(bool enabled, String language) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await _channel.invokeMethod<void>('configure', {
        'enabled': enabled,
        'language': language,
      });
    } on PlatformException {
      // The Android service will be retried on resume.
    } on MissingPluginException {
      // Settings and widget tests run without the native Android receiver.
    }
  }

  @override
  Widget build(BuildContext context) {
    final enabled = ref.watch(contentNewsProvider);
    final language = Localizations.localeOf(context).languageCode;
    if (_configuration != (enabled, language)) {
      _configuration = (enabled, language);
      _sync(enabled, language);
    }
    return widget.child;
  }
}

class ContentNewsTile extends ConsumerWidget {
  const ContentNewsTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    return SwitchListTile(
      title: Text(ar ? 'أخبار المحتوى' : 'Content news'),
      subtitle: Text(
        ar
            ? 'إشعارات المواسم والحلقات والميزات الجديدة'
            : 'Notifications for new seasons, episodes and features',
      ),
      value: ref.watch(contentNewsProvider),
      onChanged: (enabled) async {
        try {
          if (enabled &&
              !kIsWeb &&
              defaultTargetPlatform == TargetPlatform.android) {
            await _channel.invokeMethod<void>('permission');
          }
          await ref.read(contentNewsProvider.notifier).set(enabled);
        } on PlatformException {
          // Android notification access remains editable in device settings.
        } on MissingPluginException {
          await ref.read(contentNewsProvider.notifier).set(enabled);
        }
      },
    );
  }
}
