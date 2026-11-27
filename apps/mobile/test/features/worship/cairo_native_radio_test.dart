import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';
import 'package:madar_al_huda/core/audio/audio_playback.dart';
import 'package:madar_al_huda/core/localization/app_locales.dart';
import 'package:madar_al_huda/core/routing/app_routes.dart';
import 'package:madar_al_huda/features/worship/application/cairo_radio_stream.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/pump_app.dart';

void main() {
  final live = Uri.https('radio.example', '/live.m3u8');
  final l10n = lookupAppLocalizations(const Locale('en'));

  testWidgets('radio and recitation share playback and the mini player', (
    tester,
  ) async {
    final audio = _AudioFixture();
    addTearDown(audio.dispose);
    await pumpMadarApp(
      tester,
      initialLocation: AppRoutes.library,
      cairoRadioStream: live,
      audioPlayer: audio,
    );
    final context = tester.element(find.byKey(const ValueKey('library-radio')));
    final controller = ProviderScope.containerOf(context)
        .read(audioPlaybackProvider.notifier);

    Future<void> startChapter() => controller.start(
      const MediaItem(id: '1:159', title: 'Al-Fatihah'),
      () async => (
        url: Uri.https('recitation.example', '/1.mp3'),
        start: Duration.zero,
      ),
    );

    await startChapter();
    // The library banner plays the radio in place: no radio page.
    await tester.tap(find.byKey(const Key('library-radio-play')));
    await tester.pumpAndSettle();

    expect(audio.source, isA<HlsAudioSource>());
    expect(audio.source?.uri, live);
    expect((audio.source?.tag as MediaItem).isLive, isTrue);
    expect(
      audio.events,
      containsAllInOrder([
        'play:1:159',
        'pause:1:159',
        'load:$cairoRadioMediaId',
        'play:$cairoRadioMediaId',
      ]),
    );
    expect(find.byKey(const ValueKey('library-radio')), findsOneWidget);
    expect(find.byIcon(Icons.stop_rounded), findsOneWidget);

    GoRouter.of(context).go(AppRoutes.home);
    await tester.pumpAndSettle();
    expect(find.byTooltip(l10n.radioStop), findsOneWidget);

    await startChapter();
    await tester.pumpAndSettle();
    expect(
      audio.events,
      containsAllInOrder([
        'play:$cairoRadioMediaId',
        'pause:$cairoRadioMediaId',
        'load:1:159',
        'play:1:159',
      ]),
    );
    expect(find.byTooltip(l10n.radioStop), findsNothing);
    expect(find.byTooltip(l10n.readerPause), findsOneWidget);
  });

  testWidgets('radio shows a failed stream and lets the listener retry', (
    tester,
  ) async {
    final audio = _AudioFixture()..failNextSource = true;
    addTearDown(audio.dispose);
    await pumpMadarApp(
      tester,
      initialLocation: AppRoutes.home,
      cairoRadioStream: live,
      audioPlayer: audio,
    );
    final tile = find.byKey(const ValueKey('home-radio'));
    await tester.ensureVisible(tile);
    await tester.pumpAndSettle();
    // From home too: a failed stream explains and offers the website.
    await tester.tap(tile);
    await tester.pumpAndSettle();
    expect(find.text(l10n.radioStreamFailed), findsOneWidget);
    expect(find.text(l10n.radioOpenInBrowser), findsOneWidget);
    ScaffoldMessenger.of(tester.element(tile)).hideCurrentSnackBar();
    await tester.pumpAndSettle();

    await tester.tap(tile);
    await tester.pumpAndSettle();
    expect(audio.events.last, 'play:$cairoRadioMediaId');
    expect(find.byIcon(Icons.stop_circle_outlined), findsOneWidget);

    // The same tile stops it.
    await tester.tap(tile);
    await tester.pumpAndSettle();
    expect(audio.events.last, 'stop:$cairoRadioMediaId');
    expect(find.byIcon(Icons.stop_circle_outlined), findsNothing);
  });
}

class _AudioFixture extends Fake implements AudioPlayer {
  final _states = StreamController<PlayerState>.broadcast(sync: true);
  final events = <String>[];
  UriAudioSource? source;
  bool failNextSource = false;
  PlayerState _state = PlayerState(false, ProcessingState.idle);

  String get _id => (source?.tag as MediaItem?)?.id ?? 'none';

  void _publish(bool playing, ProcessingState state) {
    _state = PlayerState(playing, state);
    _states.add(_state);
  }

  @override
  PlayerState get playerState => _state;

  @override
  ProcessingState get processingState => _state.processingState;

  @override
  Stream<PlayerState> get playerStateStream => _states.stream;

  @override
  Stream<PlayerException> get errorStream => const Stream.empty();

  // The mini player shows progress for recordings.
  @override
  Duration get position => Duration.zero;

  @override
  Duration? get duration => null;

  @override
  Stream<Duration> get positionStream => const Stream.empty();

  @override
  Future<Duration?> setAudioSource(
    AudioSource audioSource, {
    bool preload = true,
    int? initialIndex,
    Duration? initialPosition,
  }) async {
    if (failNextSource) {
      failNextSource = false;
      throw PlayerException(1, 'test connection failure', 0);
    }
    source = audioSource as UriAudioSource;
    events.add('load:$_id');
    _publish(false, ProcessingState.ready);
    return null;
  }

  @override
  Future<void> pause() async {
    events.add('pause:$_id');
    _publish(false, _state.processingState);
  }

  @override
  Future<void> play() async {
    events.add('play:$_id');
    _publish(true, ProcessingState.ready);
  }

  @override
  Future<void> stop() async {
    events.add('stop:$_id');
    _publish(false, ProcessingState.idle);
  }

  @override
  Future<void> dispose() => _states.close();
}
