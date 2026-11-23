import 'dart:async';
import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:video_player/video_player.dart';

import '../../../core/localization/l10n_extension.dart';
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
      final player = switch (uri.scheme) {
        'asset' => VideoPlayerController.asset(uri.path.substring(1)),
        'file' => VideoPlayerController.file(File.fromUri(uri)),
        _ => VideoPlayerController.networkUrl(uri),
      };
      _controller = player;
      await player.initialize().timeout(const Duration(seconds: 25));
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

  Future<void> _toggle(VideoPlayerController player) async {
    try {
      if (player.value.isPlaying) {
        await player.pause();
      } else {
        if (player.value.isCompleted) await player.seekTo(Duration.zero);
        await player.play();
      }
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final controller = _controller;
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: SafeArea(
        child: ListView(
          children: [
            ResponsiveContent(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    l10n.learningEpisodeNumber(widget.queue[_index].number),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  if (_loading)
                    const AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_failed || controller == null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.learningPlaybackFailed),
                        TextButton(
                          onPressed: () => _open(_index),
                          child: Text(l10n.learningRetry),
                        ),
                      ],
                    )
                  else ...[
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 420),
                      child: ColoredBox(
                        color: Colors.black,
                        child: Center(
                          child: AspectRatio(
                            aspectRatio: controller.value.aspectRatio,
                            child: VideoPlayer(controller),
                          ),
                        ),
                      ),
                    ),
                    VideoProgressIndicator(controller, allowScrubbing: true),
                    ValueListenableBuilder(
                      valueListenable: controller,
                      builder: (context, value, _) => Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            tooltip: l10n.learningPreviousEpisode,
                            onPressed: _index == 0
                                ? null
                                : () => _open(_index - 1),
                            icon: const Icon(Icons.skip_previous),
                          ),
                          IconButton(
                            tooltip: value.isPlaying
                                ? l10n.readerPause
                                : l10n.readerResume,
                            onPressed: () => _toggle(controller),
                            icon: Icon(
                              value.isPlaying ? Icons.pause : Icons.play_arrow,
                            ),
                          ),
                          IconButton(
                            tooltip: l10n.learningNextEpisode,
                            onPressed: _index + 1 >= widget.queue.length
                                ? null
                                : () => _open(_index + 1),
                            icon: const Icon(Icons.skip_next),
                          ),
                        ],
                      ),
                    ),
                  ],
                  for (final (position, episode) in widget.queue.indexed)
                    ListTile(
                      title: Text(l10n.learningEpisodeNumber(episode.number)),
                      selected: position == _index,
                      leading: const Icon(Icons.play_circle_outline),
                      onTap: _loading || position == _index
                          ? null
                          : () => _open(position),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
