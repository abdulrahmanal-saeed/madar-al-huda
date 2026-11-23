import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/storage_providers.dart';

final hanafiAsrProvider = NotifierProvider<HanafiAsr, bool>(HanafiAsr.new);

class HanafiAsr extends Notifier<bool> {
  static const key = 'worship.hanafiAsr';

  @override
  bool build() => ref.watch(keyValueStoreProvider).getBool(key) ?? false;

  Future<void> select(bool value) async {
    await ref.read(keyValueStoreProvider).setBool(key, value: value);
    state = value;
  }
}
