import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:video_player/video_player.dart';

import '../../../core/audio/playback_speeds.dart';
import '../../../core/localization/l10n_extension.dart';
import '../../../core/localization/numbers.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/responsive_content.dart';
import '../data/learning_catalog.dart';
import '../data/learning_files.dart';

class EpisodeVideoScreen extends StatefulWidget {
  const EpisodeVideoScreen({
    required this.title,
    required this.queue,
    required this.files,
    super.key,
  });

  final String title;
  final List<LessonEpisode> queue;
  final LearningFiles files;

  @override
  State<EpisodeVideoScreen> createState() => _EpisodeVideoScreenState();
}

class _EpisodeVideoScreenState extends State<EpisodeVideoScreen> {
  VideoPlayerController? _controller;
  int _index = 0;
  double _speed = 1;
  bool _loading = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    unawaited(_open(0));
  }

  @override
  void dispose() {
    final player = _controller;
    player?.removeListener(_onVideoChanged);
    unawaited(player?.dispose());
    super.dispose();
  }

  Future<void> _open(int index) async {
    if (_loading || index < 0 || index >= widget.queue.length) return;
    final previous = _controller;
    if (previous != null) _speed = previous.value.playbackSpeed;
    setState(() {
      _loading = true;
      _failed = false;
      _index = index;
      _controller = null;
    });
    try {
      previous?.removeListener(_onVideoChanged);
      await previous?.dispose();
      final media = widget.queue[index].media[LessonFormat.video]!;
      final uri = await widget.files.playable(media);
      if (!mounted) return;
      // The sound keeps going when the app is in the background.
      final options = VideoPlayerOptions(allowBackgroundPlayback: true);
      final player = uri.scheme == 'file'
          ? VideoPlayerController.file(
              File.fromUri(uri),
              videoPlayerOptions: options,
            )
          : VideoPlayerController.networkUrl(uri, videoPlayerOptions: options);
      _controller = player;
      await player.initialize().timeout(const Duration(seconds: 25));
      if (_speed != 1) await player.setPlaybackSpeed(_speed);
      if (!mounted) return;
      player.addListener(_onVideoChanged);
      await player.play();
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) {
        setState(() => _loading = false);
        _onVideoChanged();
      }
    }
  }

  void _onVideoChanged() {
    final value = _controller?.value;
    if (!mounted || _loading || _failed || value == null) return;
    if (value.hasError) {
      setState(() => _failed = true);
    } else if (value.isCompleted) {
      unawaited(_open(_index + 1));
    }
  }

  Future<void> _fullscreen(VideoPlayerController player) async {
    await Navigator.of(context).push<void>(
      PageRouteBuilder(
        opaque: true,
        pageBuilder: (_, _, _) => _FullscreenVideo(
          controller: player,
          onPrevious: _index == 0 ? null : () => _open(_index - 1),
          onNext: _index + 1 >= widget.queue.length
              ? null
              : () => _open(_index + 1),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final numbers = decimalFormat(Localizations.localeOf(context).languageCode);
    final controller = _controller;
    final episode = widget.queue[_index];

    Widget frame(Widget child) => AspectRatio(
      aspectRatio: 16 / 9,
      child: ColoredBox(color: Colors.black, child: child),
    );

    final Widget player;
    if (_loading) {
      player = frame(
        const Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    } else if (_failed || controller == null) {
      player = frame(
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.white70, size: 36),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.learningPlaybackFailed,
                style: const TextStyle(color: Colors.white),
              ),
              TextButton(
                onPressed: () => _open(_index),
                child: Text(l10n.learningRetry),
              ),
            ],
          ),
        ),
      );
    } else {
      player = VideoSurface(
        controller: controller,
        onFullscreen: () => _fullscreen(controller),
        onPrevious: _index == 0 ? null : () => _open(_index - 1),
        onNext: _index + 1 >= widget.queue.length
            ? null
            : () => _open(_index + 1),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: SafeArea(
        child: ListView(
          children: [
            // The video takes the full width at its own shape: no bars.
            Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: AppBreakpoints.maxContentWidth,
                  maxHeight: MediaQuery.sizeOf(context).height * 0.6,
                ),
                child: player,
              ),
            ),
            ResponsiveContent(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    l10n.learningEpisodeNumber(numbers.format(episode.number)),
                    style: theme.textTheme.titleLarge,
                  ),
                  Text(
                    widget.title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  for (final (position, item) in widget.queue.indexed)
                    Card(
                      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                      color: position == _index
                          ? scheme.primaryContainer
                          : null,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: position == _index
                              ? scheme.primary
                              : scheme.secondaryContainer,
                          foregroundColor: position == _index
                              ? scheme.onPrimary
                              : scheme.onSecondaryContainer,
                          child: position == _index
                              ? const Icon(Icons.graphic_eq)
                              : Text(numbers.format(item.number)),
                        ),
                        title: Text(
                          l10n.learningEpisodeNumber(
                            numbers.format(item.number),
                          ),
                        ),
                        subtitle: position == _index
                            ? Text(l10n.learningNowPlaying)
                            : null,
                        trailing: position == _index
                            ? null
                            : const Icon(Icons.play_circle_outline),
                        onTap: _loading || position == _index
                            ? null
                            : () => _open(position),
                      ),
                    ),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _clock(Duration value) {
  final seconds = value.inSeconds;
  String two(int n) => n.toString().padLeft(2, '0');
  return seconds >= 3600
      ? '${seconds ~/ 3600}:${two(seconds ~/ 60 % 60)}:${two(seconds % 60)}'
      : '${seconds ~/ 60}:${two(seconds % 60)}';
}

/// The video with controls that appear on tap and fade while it plays.
class VideoSurface extends StatefulWidget {
  const VideoSurface({
    required this.controller,
    this.onFullscreen,
    this.onPrevious,
    this.onNext,
    this.fullscreen = false,
    super.key,
  });

  final VideoPlayerController controller;
  final VoidCallback? onFullscreen;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final bool fullscreen;

  @override
  State<VideoSurface> createState() => _VideoSurfaceState();
}

class _VideoSurfaceState extends State<VideoSurface> {
  bool _visible = true;
  Timer? _hide;
  double? _dragging;

  @override
  void initState() {
    super.initState();
    _scheduleHide();
  }

  @override
  void dispose() {
    _hide?.cancel();
    super.dispose();
  }

  void _scheduleHide() {
    _hide?.cancel();
    _hide = Timer(const Duration(seconds: 3), () {
      if (mounted && widget.controller.value.isPlaying && _dragging == null) {
        setState(() => _visible = false);
      }
    });
  }

  void _show() {
    setState(() => _visible = true);
    _scheduleHide();
  }

  Future<void> _toggle() async {
    final player = widget.controller;
    if (player.value.isPlaying) {
      await player.pause();
    } else {
      if (player.value.isCompleted) await player.seekTo(Duration.zero);
      await player.play();
    }
    _show();
  }

  Future<void> _seekBy(Duration offset) async {
    final value = widget.controller.value;
    var target = value.position + offset;
    if (target < Duration.zero) target = Duration.zero;
    if (target > value.duration) target = value.duration;
    await widget.controller.seekTo(target);
    _show();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final controller = widget.controller;
    final ratio = controller.value.aspectRatio;
    return AspectRatio(
      aspectRatio: ratio > 0 ? ratio : 16 / 9,
      child: ColoredBox(
        color: Colors.black,
        child: Stack(
          fit: StackFit.expand,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () =>
                  _visible ? setState(() => _visible = false) : _show(),
              onDoubleTap: _toggle,
              child: VideoPlayer(controller),
            ),
            IgnorePointer(
              ignoring: !_visible,
              child: AnimatedOpacity(
                opacity: _visible ? 1 : 0,
                duration: const Duration(milliseconds: 200),
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x66000000),
                        Color(0x00000000),
                        Color(0x99000000),
                      ],
                      stops: [0, 0.45, 1],
                    ),
                  ),
                  // Media controls keep their left-to-right order in every
                  // language, like any player's buttons.
                  child: Directionality(
                    textDirection: TextDirection.ltr,
                    child: ValueListenableBuilder(
                      valueListenable: controller,
                      builder: (context, value, _) {
                        final duration = value.duration;
                        final position = value.position > duration
                            ? duration
                            : value.position;
                        final total = duration.inMilliseconds.toDouble();
                        final current =
                            _dragging ??
                            (total <= 0
                                ? 0.0
                                : position.inMilliseconds / total);
                        return Column(
                          children: [
                            const Spacer(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _RoundButton(
                                  icon: Icons.skip_previous_rounded,
                                  tooltip: l10n.learningPreviousEpisode,
                                  onPressed: widget.onPrevious,
                                ),
                                _RoundButton(
                                  icon: Icons.replay_10_rounded,
                                  tooltip: l10n.playerBack,
                                  onPressed: () =>
                                      _seekBy(const Duration(seconds: -10)),
                                ),
                                _RoundButton(
                                  key: const Key('video-play-pause'),
                                  icon: value.isPlaying
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded,
                                  tooltip: value.isPlaying
                                      ? l10n.readerPause
                                      : l10n.readerResume,
                                  large: true,
                                  onPressed: _toggle,
                                ),
                                _RoundButton(
                                  icon: Icons.forward_10_rounded,
                                  tooltip: l10n.playerForward,
                                  onPressed: () =>
                                      _seekBy(const Duration(seconds: 10)),
                                ),
                                _RoundButton(
                                  icon: Icons.skip_next_rounded,
                                  tooltip: l10n.learningNextEpisode,
                                  onPressed: widget.onNext,
                                ),
                              ],
                            ),
                            const Spacer(),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    _clock(position),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Expanded(
                                    child: SliderTheme(
                                      data: SliderTheme.of(context).copyWith(
                                        trackHeight: 3,
                                        activeTrackColor: scheme.primary,
                                        inactiveTrackColor: Colors.white30,
                                        thumbColor: scheme.primary,
                                        overlayColor: scheme.primary.withValues(
                                          alpha: 0.2,
                                        ),
                                        thumbShape: const RoundSliderThumbShape(
                                          enabledThumbRadius: 7,
                                        ),
                                      ),
                                      child: Slider(
                                        value: current.clamp(0.0, 1.0),
                                        onChangeStart: (v) =>
                                            setState(() => _dragging = v),
                                        onChanged: (v) =>
                                            setState(() => _dragging = v),
                                        onChangeEnd: (v) async {
                                          await controller.seekTo(
                                            Duration(
                                              milliseconds: (v * total).round(),
                                            ),
                                          );
                                          if (mounted) {
                                            setState(() => _dragging = null);
                                          }
                                          _scheduleHide();
                                        },
                                      ),
                                    ),
                                  ),
                                  Text(
                                    _clock(duration),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                  PopupMenuButton<double>(
                                    key: const ValueKey('video-speed'),
                                    tooltip: l10n.playerSpeed,
                                    initialValue: value.playbackSpeed,
                                    onOpened: () => _hide?.cancel(),
                                    onCanceled: _scheduleHide,
                                    onSelected: (speed) async {
                                      try {
                                        await controller.setPlaybackSpeed(
                                          speed,
                                        );
                                      } finally {
                                        if (mounted) _show();
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      for (final speed in playbackSpeeds)
                                        PopupMenuItem(
                                          value: speed,
                                          child: Text(
                                            '${decimalFormat(Localizations.localeOf(context).languageCode).format(speed)}×',
                                          ),
                                        ),
                                    ],
                                    child: Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: Text(
                                        '${decimalFormat(Localizations.localeOf(context).languageCode).format(value.playbackSpeed)}×',
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: widget.fullscreen
                                        ? l10n.learningExitFullscreen
                                        : l10n.learningFullscreen,
                                    color: Colors.white,
                                    onPressed: widget.fullscreen
                                        ? () => Navigator.of(context).pop()
                                        : widget.onFullscreen,
                                    icon: Icon(
                                      widget.fullscreen
                                          ? Icons.fullscreen_exit
                                          : Icons.fullscreen,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.large = false,
    super.key,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool large;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
    child: IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      iconSize: large ? 44 : 28,
      color: Colors.white,
      disabledColor: Colors.white30,
      style: large
          ? IconButton.styleFrom(backgroundColor: Colors.black38)
          : null,
      icon: Icon(icon),
    ),
  );
}

/// Landscape, edge to edge, sharing the same player.
class _FullscreenVideo extends StatefulWidget {
  const _FullscreenVideo({
    required this.controller,
    this.onPrevious,
    this.onNext,
  });

  final VideoPlayerController controller;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  State<_FullscreenVideo> createState() => _FullscreenVideoState();
}

class _FullscreenVideoState extends State<_FullscreenVideo> {
  @override
  void initState() {
    super.initState();
    final ratio = widget.controller.value.aspectRatio;
    if (ratio >= 1) {
      unawaited(
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]),
      );
    }
    unawaited(
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky),
    );
  }

  @override
  void dispose() {
    unawaited(SystemChrome.setPreferredOrientations(const []));
    unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    body: Center(
      child: VideoSurface(
        controller: widget.controller,
        fullscreen: true,
        // Changing episode replaces the player; return to the list for it.
        onPrevious: widget.onPrevious == null
            ? null
            : () {
                Navigator.of(context).pop();
                widget.onPrevious!();
              },
        onNext: widget.onNext == null
            ? null
            : () {
                Navigator.of(context).pop();
                widget.onNext!();
              },
      ),
    ),
  );
}
