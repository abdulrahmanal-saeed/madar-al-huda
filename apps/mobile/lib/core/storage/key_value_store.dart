import 'package:shared_preferences/shared_preferences.dart';

/// Small synchronous-read key/value store for user preferences.
///
/// Storage boundaries (see docs/ARCHITECTURE.md → "Local storage"):
/// * **Preferences** (language, theme, toggles) → this interface.
/// * **Single reading cursor** → the versioned edition reference managed by
///   the Quran reading-position repository.
/// * **Structured collections** (bookmarks and khatmah plans) → their feature
///   repositories and offline database (P01-03).
/// * **Licensed offline content** (Quran edition, tafsir, audio cache) →
///   versioned, checksummed datasets behind provider adapters (P01-01).
///   Never stored here.
abstract interface class KeyValueStore {
  String? getString(String key);
  bool? getBool(String key);
  Future<void> setString(String key, String value);
  Future<void> setBool(String key, {required bool value});
  Future<void> remove(String key);
}

/// Production implementation backed by `shared_preferences`.
///
/// Only keys in [allowList] can be read or written, which keeps this store
/// from silently accumulating unrelated data.
final class SharedPreferencesKeyValueStore implements KeyValueStore {
  SharedPreferencesKeyValueStore._(this._prefs);

  final SharedPreferencesWithCache _prefs;

  static Future<SharedPreferencesKeyValueStore> create({
    required Set<String> allowList,
  }) async {
    final prefs = await SharedPreferencesWithCache.create(
      cacheOptions: SharedPreferencesWithCacheOptions(allowList: allowList),
    );
    return SharedPreferencesKeyValueStore._(prefs);
  }

  // Read untyped and check the type ourselves: the typed getters throw on a
  // mismatched value, and a corrupt entry must never crash app start-up.
  @override
  String? getString(String key) {
    final value = _prefs.get(key);
    return value is String ? value : null;
  }

  @override
  bool? getBool(String key) {
    final value = _prefs.get(key);
    return value is bool ? value : null;
  }

  @override
  Future<void> setString(String key, String value) =>
      _prefs.setString(key, value);

  @override
  Future<void> setBool(String key, {required bool value}) =>
      _prefs.setBool(key, value);

  @override
  Future<void> remove(String key) => _prefs.remove(key);
}

/// In-memory implementation for tests, previews and as a safe fallback.
class InMemoryKeyValueStore implements KeyValueStore {
  InMemoryKeyValueStore([Map<String, Object>? initial])
    : _values = {...?initial};

  final Map<String, Object> _values;

  /// Read-only view, useful for assertions in tests.
  Map<String, Object> get values => Map.unmodifiable(_values);

  @override
  String? getString(String key) {
    final value = _values[key];
    return value is String ? value : null;
  }

  @override
  bool? getBool(String key) {
    final value = _values[key];
    return value is bool ? value : null;
  }

  @override
  Future<void> setString(String key, String value) async =>
      _values[key] = value;

  @override
  Future<void> setBool(String key, {required bool value}) async =>
      _values[key] = value;

  @override
  Future<void> remove(String key) async => _values.remove(key);
}
