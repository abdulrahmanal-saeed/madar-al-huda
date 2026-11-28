import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:madar_al_huda/core/storage/key_value_store.dart';
import 'package:madar_al_huda/core/storage/storage_providers.dart';
import 'package:madar_al_huda/features/fiqh/data/fiqh_reading.dart';

void main() {
  test('favorites and recent history persist by stable ID', () async {
    final store = InMemoryKeyValueStore();
    final container = ProviderContainer(
      overrides: [keyValueStoreProvider.overrideWithValue(store)],
    );
    addTearDown(container.dispose);
    final controller = container.read(fiqhReadingProvider.notifier);
    await controller.toggleFavorite('test-a');
    await controller.recordReading('test-a');
    await controller.recordReading('test-b');
    await controller.recordReading('test-a');
    await controller.setFontScale(9);
    expect(container.read(fiqhReadingProvider).favorites, ['test-a']);
    expect(container.read(fiqhReadingProvider).history, ['test-a', 'test-b']);
    expect(container.read(fiqhReadingProvider).fontScale, 1.5);
    final reopened = ProviderContainer(
      overrides: [keyValueStoreProvider.overrideWithValue(store)],
    );
    addTearDown(reopened.dispose);
    expect(reopened.read(fiqhReadingProvider).favorites, ['test-a']);
    await reopened.read(fiqhReadingProvider.notifier).clearHistory();
    expect(reopened.read(fiqhReadingProvider).history, isEmpty);
    expect(reopened.read(fiqhReadingProvider).favorites, ['test-a']);
  });
}
