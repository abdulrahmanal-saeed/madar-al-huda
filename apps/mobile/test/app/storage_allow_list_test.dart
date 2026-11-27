import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:madar_al_huda/app/first_run.dart';
import 'package:madar_al_huda/core/content/content_news.dart';
import 'package:madar_al_huda/core/storage/key_value_store.dart';
import 'package:madar_al_huda/core/storage/storage_providers.dart';
import 'package:madar_al_huda/features/quran/data/mushaf_source.dart';
import 'package:madar_al_huda/main.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  test('the real store accepts the first-run flag', () async {
    // Regression: a key missing from the allow list made the platform store
    // throw at startup, leaving a grey screen after the splash.
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    final store = await SharedPreferencesKeyValueStore.create(
      allowList: storageAllowList,
    );
    expect(firstRunDone(store), isFalse);
    await store.setBool(firstRunDoneKey, value: true);
    expect(firstRunDone(store), isTrue);
  });

  test('a store that cannot answer never blocks startup', () async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    final store = await SharedPreferencesKeyValueStore.create(
      allowList: const {'something.else.v1'},
    );
    expect(firstRunDone(store), isTrue);
  });

  test(
    'the production store accepts the news and Mushaf preferences',
    () async {
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty();
      final store = await SharedPreferencesKeyValueStore.create(
        allowList: storageAllowList,
      );
      final container = ProviderContainer(
        overrides: [keyValueStoreProvider.overrideWithValue(store)],
      );
      addTearDown(container.dispose);

      expect(container.read(contentNewsProvider), isTrue);
      await container.read(contentNewsProvider.notifier).set(false);
      expect(store.getBool(ContentNewsPreference.key), isFalse);

      expect(container.read(mushafSourceProvider), MushafSource.values.first);
      final edition = MushafSource.values.last;
      await container.read(mushafSourceProvider.notifier).select(edition);
      expect(store.getString(MushafSourceController.key), edition.name);
    },
  );
}
