import 'package:video_player/video_player.dart';
import 'package:flutter/material.dart';

class StoryVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final Function onVideoFinished;
  final Function(double) onProgressUpdate;
  final Duration storyDuration;

  const StoryVideoPlayer({
    super.key,
    required this.videoUrl,
    required this.onVideoFinished,
    required this.onProgressUpdate,
    required this.storyDuration,
  });

  @override
  State<StoryVideoPlayer> createState() => _StoryVideoPlayerState();
}

class _StoryVideoPlayerState extends State<StoryVideoPlayer> {
  late VideoPlayerController _controller;
  late Duration _videoDuration;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        setState(() {
          _videoDuration = _controller.value.duration;
        });
        _controller.play();
        _controller.setLooping(false);
        _controller.addListener(_updateProgress);
      });
  }

  void _updateProgress() {
    final position = _controller.value.position;
    final progress =
        position.inMilliseconds / widget.storyDuration.inMilliseconds;
    widget.onProgressUpdate(progress); // Actualizamos la barra de progreso
    if (position >= _videoDuration) {
      widget
          .onVideoFinished(); // El video ha terminado, avanzamos a la siguiente historia
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _controller.value.isInitialized
        ? GestureDetector(
            onTap: () {
              if (_controller.value.isPlaying) {
                _controller.pause();
              } else {
                _controller.play();
              }
            },
            child: AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: VideoPlayer(_controller),
            ),
          )
        : const Center(child: CircularProgressIndicator());
  }
}
