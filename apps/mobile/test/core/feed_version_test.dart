import 'package:flutter_test/flutter_test.dart';
import 'package:madar_al_huda/core/content/managed_library.dart';

void main() {
  test('a build keeps feeds it can read and skips newer ones', () {
    // Feeds from before versioning, and the current shape.
    expect(ManagedFeedVersion.accepts({'version': 1}, build: 40), isTrue);
    expect(
      ManagedFeedVersion.accepts({
        'schemaVersion': 1,
        'minAppVersion': 0,
      }, build: 40),
      isTrue,
    );
    // A shape this build does not know.
    expect(
      ManagedFeedVersion.accepts({'schemaVersion': 2}, build: 40),
      isFalse,
    );
    // The dashboard asks for a newer build.
    expect(
      ManagedFeedVersion.accepts({'minAppVersion': 41}, build: 40),
      isFalse,
    );
    expect(
      ManagedFeedVersion.accepts({'minAppVersion': 40}, build: 40),
      isTrue,
    );
    // Local builds have no number and accept any minimum.
    expect(ManagedFeedVersion.accepts({'minAppVersion': 99}, build: 0), isTrue);
  });
}
